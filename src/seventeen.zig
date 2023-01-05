const std = @import("std");
const utils = @import("utils.zig");
const parse = std.fmt.parseInt;
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const Direction = enum { left, right };

const DirectionIter = struct {
    directions: []Direction,
    idx: usize,

    fn next(self: *DirectionIter) Direction {
        const ret = self.directions[self.idx];
        self.idx += 1;
        if (self.idx == self.directions.len) {
            self.idx = 0;
        }
        return ret;
    }
};

const Chamber = struct {
    rocks : [7]std.ArrayList(u64),
    
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var all = try utils.readAll(allocator, "input/seventeen");
    defer allocator.free(all);

    var directions_list = std.ArrayList(Direction).init(allocator);
    defer directions_list.deinit();
    try directions_list.ensureTotalCapacity(all.len);

    for (all) |a| {
        switch (a) {
            '<' => directions_list.appendAssumeCapacity(.left),
            '>' => directions_list.appendAssumeCapacity(.right),
            else => break,
        }
    }

    var direction_iter = DirectionIter{.directions = directions_list.items, .idx = 0};


    const one = 0;

    print("1: {}\n2: {s}\n", .{ one, "TODO" });
}
