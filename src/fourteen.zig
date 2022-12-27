const std = @import("std");
const utils = @import("utils.zig");
const parse = std.fmt.parseInt;
const print = std.debug.print;

const pointTy = i32;
const Point = struct {
    x: pointTy,
    y: pointTy,
    fn read(p: []const u8) !Point {
        const comma = std.mem.indexOf(u8, p, ",").?;
        var x = try parse(pointTy, p[0..comma], 10);
        var y = try parse(pointTy, p[comma + 1 ..], 10);
        return Point{ .x = x, .y = y };
    }
};

const List = std.ArrayList(pointTy);
const MapType = std.AutoHashMap(pointTy, List);

fn addPoint(allocator: std.mem.Allocator, map: *MapType, point: Point) !void {
    var res = try map.getOrPut(point.x);
    if (!res.found_existing) {
        res.value_ptr.* = List.init(allocator);
    } else if (!spaceFree(res.value_ptr.items, point.y)) return;
    try res.value_ptr.*.append(point.y);
}

fn indexOfGreaterThan(list: []pointTy, val: pointTy) ?usize {
    for (list) |v, idx| {
        if (v > val) return idx;
    }
    return null;
}

fn spaceFree(col: []pointTy, y: pointTy) bool {
    return !std.mem.containsAtLeast(pointTy, col, 1, &[_]pointTy{y});
}

fn dropSand(map: *MapType) !bool {
    var next = Point{ .x = 500, .y = 0 };
    while (true) {
        var col = map.getPtr(next.x) orelse return false;
        // find next value less than next.y
        const wall_idx = indexOfGreaterThan(col.items, next.y) orelse return false;
        const wall_y = col.items[wall_idx];

        // can it go left or right
        const left_col = map.get(next.x - 1) orelse return false;
        if (spaceFree(left_col.items, wall_y)) {
            next = Point{ .x = next.x - 1, .y = wall_y };
        } else {
            const right_col = map.get(next.x + 1) orelse return false;
            if (spaceFree(right_col.items, wall_y)) {
                next = Point{ .x = next.x + 1, .y = wall_y };
            } else {
                // stop
                try col.insert(wall_idx, wall_y - 1);
                return true;
            }
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var all = try utils.readAll(allocator, "input/fourteen");
    defer allocator.free(all);

    // map from column to points in that column
    var map = MapType.init(allocator);
    defer {
        var iter = map.iterator();
        while (iter.next()) |*col| {
            col.value_ptr.deinit();
        }
        map.deinit();
    }

    var lines = std.mem.tokenize(u8, all, "\n");

    while (lines.next()) |line| {
        var points = std.mem.tokenize(u8, line, " -> ");
        var previous = try Point.read(points.next().?);
        try addPoint(allocator, &map, previous);
        while (points.next()) |point| {
            const next = try Point.read(point);
            if (previous.x != next.x) {
                std.debug.assert(previous.y == next.y);
                const direction = std.math.sign(next.x - previous.x);
                var i: pointTy = previous.x + direction; // previous will have been added in the last loop
                while (i != next.x + direction) : (i += direction) {
                    try addPoint(allocator, &map, Point{ .x = i, .y = previous.y });
                }
            } else if (previous.y != next.y) {
                std.debug.assert(previous.x == next.x);
                const direction = std.math.sign(next.y - previous.y);
                var i: pointTy = previous.y + direction; // previous will have been added in the last loop
                while (i != next.y + direction) : (i += direction) {
                    try addPoint(allocator, &map, Point{ .x = previous.x, .y = i });
                }
            }
            previous = next;
        }
    }

    var map_iter = map.iterator();
    while (map_iter.next()) |col| {
        std.sort.sort(pointTy, col.value_ptr.items, {}, std.sort.asc(pointTy));
    }

    var count: pointTy = 0;
    while (try dropSand(&map)) : (count += 1) {}

    print("1: {}\n2: {s}\n", .{ count, "TODO" });
}
