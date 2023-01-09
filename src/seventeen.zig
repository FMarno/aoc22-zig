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

const bits = 64;
const Column = std.meta.Int(.unsigned, bits);
const Cols = [7]Column;

// 0 is left and 6 is right
const shapes = [5]Cols{
    Cols{
        0b0,
        0b0,
        0b1,
        0b1,
        0b1,
        0b1,
        0b0,
    },
    Cols{
        0b000,
        0b000,
        0b010,
        0b111,
        0b010,
        0b000,
        0b000,
    },
    Cols{
        0b000,
        0b000,
        0b001,
        0b001,
        0b111,
        0b000,
        0b000,
    },
    Cols{
        0b0000,
        0b0000,
        0b1111,
        0b0000,
        0b0000,
        0b0000,
        0b0000,
    },
    Cols{
        0b00,
        0b00,
        0b11,
        0b11,
        0b00,
        0b00,
        0b00,
    },
};

const ShapeIter = struct {
    idx: usize,

    fn next(self: *ShapeIter) Cols {
        const ret = shapes[self.idx];
        self.idx += 1;
        if (self.idx == shapes.len) {
            self.idx = 0;
        }
        return ret;
    }
};

const Chamber = struct {
    const Self = @This();
    rocks: std.ArrayList(Cols),

    fn new(allocator: Allocator) !Self {
        var chamber = Self{ .rocks = std.ArrayList(Cols).init(allocator) };

        // start with a floor
        try chamber.addCols();
        for (chamber.rocks.items[0]) |*r| {
            r.* |= 1;
        }

        return chamber;
    }

    fn deinit(self: *Self) void {
        self.rocks.deinit();
    }

    fn addCols(self: *Self) !void {
        try self.rocks.append(std.mem.zeroes(Cols));
    }

    fn place(self: *Self, cols: Cols) void {
        for (self.rocks.items[0]) |*c, idx| {
            c.* = c.* | cols[idx];
        }
    }

    fn height(self: Self) usize {
        var idx = self.rocks.items.len - 1;
        while (true) : (idx -= 1) {
            var min_lz: usize = bits;
            for (self.rocks.items[idx]) |c| {
                min_lz = std.math.min(min_lz, @clz(c));
            }
            std.debug.assert(min_lz < bits); // not sure about this

            return idx * bits + (bits - min_lz);
        }
    }

    fn collides(self: Self, cols: Cols) bool {
        std.debug.assert(self.rocks.items.len == 1);
        for (self.rocks.items[0]) |c, idx| {
            if (c & cols[idx] != 0) {
                return true;
            }
        }
        return false;
    }

    fn display(self: Self, shape: ?Cols) void {
        const h = self.height() + 7;
        print("|-------|\n", .{});
        std.debug.assert(self.rocks.items.len == 1);
        const cols = self.rocks.items[0];
        var idx: usize = std.math.min(h, bits - 1);
        while (true) : (idx -= 1) {
            const filter = @as(Column, 1) << @intCast(u6, idx);
            var chars: [7]u8 = undefined;
            for (chars) |*c, ci| {
                c.* = if (cols[ci] & filter == 0) '.' else '#';
                if (shape) |s| {
                    c.* = if (s[ci] & filter == 0) c.* else '@';
                }
            }
            print("|{s}|\n", .{chars});
            if (idx == 0) break;
        }
        print("|-------|\n", .{});
    }
};

fn shape_up(cols: *Cols, offset: usize) void {
    for (cols) |*c| {
        c.* = c.* << @intCast(u6, offset);
    }
}

fn shape_down(chamber: Chamber, cols: *Cols) bool {
    for (cols) |*c| {
        c.* = c.* >> 1;
    }
    for (chamber.rocks.items[0]) |c, idx| {
        const collision = c & cols[idx] != 0;
        if (collision) {
            print("collide!\n", .{});
            // undo movement
            for (cols) |*b| {
                b.* = b.* << 1;
            }
            return true;
        }
    }
    return false;
}

fn shape_left(chamber: Chamber, cols: *Cols) void {
    if (cols[0] != 0) return; // hit against wall
    for (cols[0..6]) |*c, idx| {
        c.* = cols[idx + 1];
    }
    cols[6] = 0;
    if (chamber.collides(cols.*)) {
        // undo
        var idx: usize = 6;
        while (idx != 0) : (idx -= 1) {
            cols[idx] = cols[idx - 1];
        }
        cols[0] = 0;
    }
}
fn shape_right(chamber: Chamber, cols: *Cols) void {
    if (cols[6] != 0) return; // hit against wall
    {
        var idx: usize = 6;
        while (idx != 0) : (idx -= 1) {
            cols[idx] = cols[idx - 1];
        }
        cols[0] = 0;
    }
    if (chamber.collides(cols.*)) {
        // undo
        for (cols[0..6]) |*c, idx| {
            c.* = cols[idx + 1];
        }
        cols[6] = 0;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var all = try utils.readAll(allocator, "input/test");
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

    var direction_iter = DirectionIter{ .directions = directions_list.items, .idx = 0 };
    var shapes_iter = ShapeIter{ .idx = 0 };

    var chamber = try Chamber.new(allocator);
    defer chamber.deinit();

    var count: usize = 0;
    while (true) : (count += 1) {
        var shape = shapes_iter.next();
        const height = chamber.height();
        if (height + 3 >= chamber.rocks.items.len * bits) {
            break;
            //try chamber.addCols();
        }
        shape_up(&shape, height + 3);
        chamber.display(shape);
        while (true) {
            var dir = direction_iter.next();
            switch (dir) {
                .left => shape_left(chamber, &shape),
                .right => shape_right(chamber, &shape),
            }
            if (shape_down(chamber, &shape)) {
                chamber.place(shape);
                break;
            }
        }
        if (count == 10) break;
    }

    chamber.display(null);

    const one = count;

    print("1: {}\n2: {s}\n", .{ one, "TODO" });
}
