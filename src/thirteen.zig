const std = @import("std");
const utils = @import("utils.zig");
const parseUnsigned = std.fmt.parseUnsigned;
const print = std.debug.print;
const isDigit = std.ascii.isDigit;

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

//const ReadInt = struct {
//    val: u32,
//    the_rest: []u8,
//};
fn readInt(line: []const u8) u32 {
    println("readInt", line);
    //const end = std.mem.indexOfAny(u8, line, ",]").?;
    return std.fmt.parseUnsigned(u32, line, 10) catch unreachable;
    //return .{ .val = val, .the_rest = line[end + 1 ..] };
}
const ItemIter = struct {
    line: []const u8,
    fn next(self: *ItemIter) ?[]const u8 {
        if (self.line.len == 0) return null;
        const end = std.mem.indexOfAny(u8, self.line, ",]") orelse self.line.len;
        var ret = self.line[0..end];
        print("l:{s} ret:{s} end:{}\n", .{ self.line, ret, end });
        self.line = self.line[end + 1 ..];
        return ret;
    }
};

fn compareList(lhs: []const u8, rhs: []const u8) std.math.Order {
    // skip opening [
    var lhs_iter = ItemIter{ .line = lhs[1..] };
    var rhs_iter = ItemIter{ .line = rhs[1..] };
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

fn compareIntList(item: []const u8, list: []const u8) std.math.Order {
    const items = std.mem.count(u8, list, ",") + 1;
    if (items > 1) return .gt;
    const num = std.mem.indexOfAny(u8, list, "0123456789") orelse return .lt;
    const list_val = readInt(list[num..]);
    const val = readInt(item);

    return std.math.order(val, list_val);
}

fn compareItem(lhs: []const u8, rhs: []const u8) std.math.Order {
    const lhs_type = getType(lhs);
    const rhs_type = getType(rhs);

    if (lhs_type == rhs_type) {
        if (lhs_type == .int) {
            const lhs_value = readInt(lhs);
            const rhs_value = readInt(rhs);
            return std.math.order(lhs_value, rhs_value);
        } else {
            return compareList(lhs, rhs);
        }
    } else {
        if (lhs_type == .int) return compareIntList(lhs, rhs);
        return switch (compareIntList(rhs, lhs)) {
            .lt => .gt,
            .gt => .lt,
            .eq => .eq,
        };
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var all = try utils.readAll(allocator, "input/test");
    defer allocator.free(all);

    var lines = std.mem.tokenize(u8, all, "\n");
    var sum: u32 = 0;
    var idx: u32 = 0;
    while (true) : (idx += 1) {
        const lhs = lines.next() orelse break;
        const rhs = lines.next().?;
        if (compareItem(lhs, rhs) != .gt) {
            sum += idx;
        }
    }

    std.debug.print("1: {}\n2: {}\n", .{ sum, sum });
}
