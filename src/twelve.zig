const std = @import("std");
const utils = @import("utils.zig");
const parseUnsigned = std.fmt.parseUnsigned;
const print = std.debug.print;

const Coord = struct {
    row: usize,
    col: usize,
};
const Map = struct {
    width: usize,
    height: usize,
    data: [][]u8,

    fn get(self: Map, coord: Coord) u8 {
        return self.data[coord.row][coord.col];
    }
    fn getNeighbours(self: Map, coord: Coord, neighbours: *std.ArrayList(Coord)) void {
        std.debug.assert(neighbours.capacity >= 4);
        neighbours.clearRetainingCapacity();
        const height = self.get(coord);
        if (coord.row > 0) {
            const potential = Coord{ .row = coord.row - 1, .col = coord.col };
            if ((self.get(potential) - 1) <= height) {
                neighbours.appendAssumeCapacity(potential);
            }
        }
        if (coord.col > 0) {
            const potential = Coord{ .row = coord.row, .col = coord.col - 1 };
            if ((self.get(potential) - 1) <= height) {
                neighbours.appendAssumeCapacity(potential);
            }
        }
        if (coord.row < self.height) {
            const potential = Coord{ .row = coord.row + 1, .col = coord.col };
            if ((self.get(potential) - 1) <= height) {
                neighbours.appendAssumeCapacity(potential);
            }
        }
        if (coord.col < self.width) {
            const potential = Coord{ .row = coord.row, .col = coord.col + 1 };
            if ((self.get(potential) - 1) <= height) {
                neighbours.appendAssumeCapacity(potential);
            }
        }
    }
};

const SearchCtx = struct {
    end: Coord,
    cost_to: std.AutoHashMap(Coord, u32),
};

fn manhattanDistance(ctx: SearchCtx, lhs: Coord, rhs: Coord) std.math.Order {
    const l_cost = ctx.cost_to.get(lhs).?;
    const l_distance = try std.math.absInt(@intCast(i32, lhs.row) - @intCast(i32, ctx.end.row)) + try std.math.absInt(@intCast(i32, lhs.col) - @intCast(i32, ctx.end.col));
    const r_cost = ctx.cost_to.get(rhs).?;
    const r_distance = try std.math.absInt(@intCast(i32, rhs.row) - @intCast(i32, ctx.end.row)) + try std.math.absInt(@intCast(i32, rhs.col) - @intCast(i32, ctx.end.col));
    return std.math.order(l_distance + l_cost, r_distance + r_cost);
}

fn astar(allocator: std.mem.Allocator, map: *Map, start: Coord, end: Coord) !?u32 {
    var to_search = std.PriorityQueue(Coord, SearchCtx, manhattanDistance).init(allocator, .{ .end = end });
    try to_search.add(start);

    var cost_to = std.AutoHashMap(Coord, u32).init(allocator);
    try cost_to.put(start, 0);

    var neighbours = try std.ArrayList(Coord).initCapacity(allocator, 4);

    while (to_search.len != 0) {
        const next = to_search.remove();
        const current_cost = cost_to.get(next).?;
        if (next == end) {
            return current_cost;
        }

        map.getNeighbours(next, &neighbours);
        for (neighbours.items) |neighbour| {
            const tentative_score = current_cost + 1;
            const neighbour_score = try cost_to.getOrPut(neighbour);
            if (!neighbour_score.found_existing or tentative_score < neighbour_score.value) {
                neighbour_score.value = tentative_score;
                var present = false;
                var iter = to_search.iterator();
                while (iter.next()) |v| {
                    if (v == neighbour) {
                        present = true;
                        break;
                    }
                }
                if (!present) {
                    try to_search.add(neighbour);
                }
            }
        }
    }
    return null;
}

fn run(comptime part1: bool, allocator: std.mem.Allocator, lines: []const []u8) !u32 {
    _ = part1;
    _ = allocator;
    _ = lines;
    return 0;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try utils.readLines(allocator, "input/test");
    defer utils.freeLines(allocator, lines);

    const one = try run(true, allocator, lines);

    std.debug.print("1: {}\n2: TODO\n", .{
        one,
    });
}
