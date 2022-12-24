const std = @import("std");
const utils = @import("utils.zig");
const parseUnsigned = std.fmt.parseUnsigned;
const print = std.debug.print;
const isDigit = std.ascii.isDigit;
const Order = std.math.Order;

const ItemTag = enum {
    int,
    list,
};

const Item = union(ItemTag) {
    int: u32,
    list: []Item,
};

fn println(prefix: []const u8, line: []const u8) void {
    print("{s}: {s}\n", .{ prefix, line });
}

fn getType(line: []const u8) ItemTag {
    //if (line.len == 0) return null;
    std.debug.assert(line.len > 0);
    if (line[0] == '[') return .list;
    std.debug.assert(isDigit(line[0]));
    return .int;
}

fn readInt(line: []const u8) u32 {
    return std.fmt.parseUnsigned(u32, line, 10) catch unreachable;
}

const ItemIter = struct {
    line: []const u8,
    fn next(self: *ItemIter) ?[]const u8 {
        if (self.line.len == 0) return null;
        const ty = getType(self.line);
        if (ty == .int) {
            const end = std.mem.indexOfAny(u8, self.line, ",]");
            if (end) |e_idx| {
                const ret = self.line[0..e_idx];
                self.line = self.line[e_idx + 1 ..];
                return ret;
            } else {
                const ret = self.line;
                self.line = &.{};
                return ret;
            }
        } else {
            var open: u32 = 1;
            var close: u32 = 0;
            var idx: usize = 1;
            while (open != close) : (idx += 1) {
                if (self.line[idx] == '[') {
                    open += 1;
                } else if (self.line[idx] == ']') {
                    close += 1;
                }
            }
            const ret = self.line[0..idx];
            self.line = if (idx == self.line.len) &.{} else self.line[idx + 1 ..];
            return ret;
        }
    }
};

fn compareList(lhs: []const u8, rhs: []const u8) Order {
    // skip opening [
    var lhs_iter = ItemIter{ .line = lhs[1 .. lhs.len - 1] };
    var rhs_iter = ItemIter{ .line = rhs[1 .. rhs.len - 1] };
    while (true) {
        //skip the opening [
        const lhs_item = lhs_iter.next();
        const rhs_item = rhs_iter.next();
        if (lhs_item) |l| {
            if (rhs_item) |r| {
                const cmp = compareItem(l, r);
                if (cmp == .eq) continue;
                return cmp;
            } else {
                return .gt;
            }
        } else {
            if (rhs_item) |_| {
                return .lt;
            } else {
                return .eq;
            }
        }
    }
}

fn compareIntList(item: []const u8, list: []const u8) Order {
    print("CompareIntList {s} vs {s}\n", .{ item, list });
    var iter = ItemIter{ .line = list[1 .. list.len - 1] };
    const demote = iter.next() orelse return .gt;
    return compareItem(item, demote);

}

fn compareItem(lhs: []const u8, rhs: []const u8) Order {
    print("Compare {s} vs {s}\n", .{ lhs, rhs });
    const lhs_type = getType(lhs);
    const rhs_type = getType(rhs);

    const result = blk: {
        if (lhs_type == rhs_type) {
            if (lhs_type == .int) {
                const lhs_value = readInt(lhs);
                const rhs_value = readInt(rhs);
                break :blk std.math.order(lhs_value, rhs_value);
            } else {
                break :blk compareList(lhs, rhs);
            }
        } else {
            if (lhs_type == .int) return compareIntList(lhs, rhs);
            const r: Order = switch (compareIntList(rhs, lhs)) {
                .lt => .gt,
                .gt => .lt,
                .eq => .eq,
            };
            break :blk r;
        }
    };
    print("compare {s} and {s} = {}\n", .{ lhs, rhs, result });
    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var all = try utils.readAll(allocator, "input/thirteen");
    defer allocator.free(all);

    var lines = std.mem.tokenize(u8, all, "\n");
    var sum: u32 = 0;
    var idx: u32 = 0;
    while (true) : (idx += 1) {
        const lhs = lines.next() orelse break;
        const rhs = lines.next().?;
        print("\n", .{});
        switch (compareItem(lhs, rhs)) {
            .lt => sum += idx + 1,
            .gt => {},
            .eq => unreachable,
        }
    }

    std.debug.print("1: {}\n2: {}\n", .{ sum, sum });
}
