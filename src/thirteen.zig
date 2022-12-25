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

fn getType(line: []const u8) ItemTag {
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
    var iter = ItemIter{ .line = list[1 .. list.len - 1] };
    const demote = iter.next() orelse return .gt;

    return switch (compareItem(item, demote)) {
        .eq => if (iter.next()) |_| .lt else .eq,
        else => |x| x,
    };
}

fn compareItem(lhs: []const u8, rhs: []const u8) Order {
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
        const r: Order = switch (compareIntList(rhs, lhs)) {
            .lt => .gt,
            .gt => .lt,
            .eq => .eq,
        };
        return r;
    }
}

fn lessThan(ctx: @TypeOf(.{}), lhs: []const u8, rhs: []const u8) bool {
    _ = ctx;
    return compareItem(lhs, rhs) == .lt;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var packets = std.ArrayList([]u8).init(allocator);
    defer {
        for (packets.items) |packet| {
            allocator.free(packet);
        }
        packets.deinit();
    }
    var key1 = "[[2]]";
    var key2 = "[[6]]";
    var k1 = try allocator.alloc(u8, key1.len);
    var k2 = try allocator.alloc(u8, key2.len);
    std.mem.copy(u8, k1, key1);
    std.mem.copy(u8, k2, key2);
    try packets.append(k1);
    try packets.append(k2);

    var all = try utils.readAll(allocator, "input/thirteen");
    defer allocator.free(all);

    var lines = std.mem.tokenize(u8, all, "\n");
    var sum: u32 = 0;
    var idx: u32 = 0;
    while (true) : (idx += 1) {
        const lhs = lines.next() orelse break;
        const rhs = lines.next().?;
        switch (compareItem(lhs, rhs)) {
            .lt => sum += idx + 1,
            .gt => {},
            .eq => unreachable,
        }
        var l_line = try allocator.alloc(u8, lhs.len);
        std.mem.copy(u8, l_line, lhs);
        try packets.append(l_line);
        var r_line = try allocator.alloc(u8, rhs.len);
        std.mem.copy(u8, r_line, rhs);
        try packets.append(r_line);
    }

    std.sort.sort([]u8, packets.items, .{}, lessThan);
    var idx1: usize = undefined;
    var idx2: usize = undefined;

    for (packets.items) |packet, i| {
        if (std.mem.eql(u8, packet, key1)) {
            idx1 = i + 1;
            break;
        }
    }
    for (packets.items[idx1 - 1 ..]) |packet, i| {
        if (std.mem.eql(u8, packet, key2)) {
            idx2 = idx1 + i;
            break;
        }
    }

    print("1: {}\n2: {}\n", .{ sum, idx1 * idx2 });
}

const expect = std.testing.expect;
test "testing" {
    try expect(compareItem("[1,2,3]", "[[1],[2],[3]]") == .eq);
    try expect(compareItem("[1]", "[[[[],2],2],2]") == .gt);
    try expect(compareItem("[2]", "[[[[]]]]") == .gt);
    try expect(compareItem("[1,1,3,1,1]", "[1,1,5,1,1]") == .lt);
    try expect(compareItem("[[1],[2,3,4]]", "[[1],4]") == .lt);
    try expect(compareItem("[9]", "[[8,7,6]]") == .gt);
    try expect(compareItem("[[4,4],4,4]", "[[4,4],4,4,4]") == .lt);
    try expect(compareItem("[7,7,7,7]", "[7,7,7]") == .gt);
    try expect(compareItem("[]", "[3]") == .lt);
    try expect(compareItem("[[[]]]", "[[]]") == .gt);
    try expect(compareItem("[1,[2,[3,[4,[5,6,7]]]],8,9]", "[1,[2,[3,[4,[5,6,0]]]],8,9]") == .gt);
}

test "catch me out" {
    try expect(compareItem("[[[4,6,9,3,1],4,[3],[2,4,[6,10]],6],[]]", "[[4,8],[[],6],[3,4]]") == .gt);
    try expect(compareItem("[[6,2,[[],0,[1]]],[[[2],[6,2,8,5,0],[6,6,5,3],[8,10,8,5,1],[]],[[],[10,2,7],[7,3,4],3],[[3],1],8],[8,[7],[],7],[[[0,4,5,3,0],[0,10]],7]]", "[[[[6,9]],0,[1,[6,6,4,6,5],8],[2,6,0,[3]],[]],[[2,1],[8,2,8,3,6],5,10],[1,8],[1,8,1],[[10,[5,5,4,8,2],1,[]]]]") == .lt);
}
