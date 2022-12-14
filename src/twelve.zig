const std = @import("std");
const utils = @import("utils.zig");
const parseUnsigned = std.fmt.parseUnsigned;
const print = std.debug.print;

const Coord = struct {
    row: usize,
    col: usize,

    fn equals(lhs: Coord, rhs: Coord) bool {
        return lhs.row == rhs.row and lhs.col == rhs.col;
    }
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
        if (coord.row < self.height - 1) {
            const potential = Coord{ .row = coord.row + 1, .col = coord.col };
            if ((self.get(potential) - 1) <= height) {
                neighbours.appendAssumeCapacity(potential);
            }
        }
        if (coord.col < self.width - 1) {
            const potential = Coord{ .row = coord.row, .col = coord.col + 1 };
            if ((self.get(potential) - 1) <= height) {
                neighbours.appendAssumeCapacity(potential);
            }
        }
    }
};

const SearchCtx = struct {
    end: Coord,
    cost_to: *std.AutoHashMap(Coord, u32),
};

fn manhattanDistance(ctx: SearchCtx, lhs: Coord, rhs: Coord) std.math.Order {
    const l_cost = ctx.cost_to.get(lhs).?;

    const l_distance: u32 = @intCast(u32, (std.math.absInt(@intCast(i32, lhs.row) - @intCast(i32, ctx.end.row)) catch unreachable) + (std.math.absInt(@intCast(i32, lhs.col) - @intCast(i32, ctx.end.col)) catch unreachable));
    const l_total = l_distance + l_cost;

    const r_cost = ctx.cost_to.get(rhs).?;
    const r_distance: u32 = @intCast(u32, (std.math.absInt(@intCast(i32, rhs.row) - @intCast(i32, ctx.end.row)) catch unreachable) + (std.math.absInt(@intCast(i32, rhs.col) - @intCast(i32, ctx.end.col)) catch unreachable));
    const r_total = r_cost + r_distance;

    return std.math.order(l_total, r_total);
}

fn astar(allocator: std.mem.Allocator, map: *const Map, start: Coord, end: Coord) !?u32 {
    var cost_to = std.AutoHashMap(Coord, u32).init(allocator);
    defer cost_to.deinit();
    try cost_to.put(start, 0);

    var to_search = std.PriorityQueue(Coord, SearchCtx, manhattanDistance).init(allocator, .{ .end = end, .cost_to = &cost_to });
    defer to_search.deinit();
    try to_search.add(start);

    // unneeded micro-optimization
    var neighbour_buf: [@sizeOf(Coord) * 4]u8 = undefined;
    var neighbour_alloc = std.heap.FixedBufferAllocator.init(&neighbour_buf);
    var neighbours = try std.ArrayList(Coord).initCapacity(neighbour_alloc.allocator(), 4);
    defer neighbours.deinit();

    while (to_search.len != 0) {
        const next = to_search.remove();
        const current_cost = cost_to.get(next).?;
        if (next.equals(end)) {
            return current_cost;
        }

        map.getNeighbours(next, &neighbours);
        for (neighbours.items) |neighbour| {
            const tentative_score = current_cost + 1;
            const neighbour_score = try cost_to.getOrPut(neighbour);
            if (!neighbour_score.found_existing or tentative_score < neighbour_score.value_ptr.*) {
                neighbour_score.value_ptr.* = tentative_score;
                // TODO why doesn't this work?
                // to_search.update(neighbour, neighbour) catch |err| {
                //     if (err == error.ElementNotFound) {
                //         try to_search.add(neighbour);
                //     } else unreachable;
                // };
                var present = false;
                var iter = to_search.iterator();
                while (iter.next()) |v| {
                    if (v.equals(neighbour)) {
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
    const height = lines.len;
    const width = lines[0].len;

    var as: std.ArrayList(Coord) = undefined;
    if (!part1) {
        as = std.ArrayList(Coord).init(allocator);
    }
    defer {
        if (!part1) {
            as.deinit();
        }
    }

    var mapdata = try allocator.alloc([]u8, height);
    defer {
        for (mapdata) |*row| {
            allocator.free(row.*);
        }
        allocator.free(mapdata);
    }

    var start: Coord = undefined;
    var end: Coord = undefined;

    for (lines) |line, row| {
        mapdata[row] = try allocator.alloc(u8, width);
        for (line) |cell, col| {
            if (cell == 'S') {
                start = Coord{ .row = row, .col = col };
                mapdata[row][col] = 'a';
                if (!part1) {
                    try as.append(start);
                }
            } else if (cell == 'E') {
                end = Coord{ .row = row, .col = col };
                mapdata[row][col] = 'z';
            } else {
                if (!part1 and cell == 'a') {
                    try as.append(Coord{ .row = row, .col = col });
                }
                mapdata[row][col] = cell;
            }
        }
    }

    const map = Map{ .width = width, .height = height, .data = mapdata };
    if (part1) {
        return (try astar(allocator, &map, start, end)).?;
    } else {
        // I should use a cache, but why not just use -Drelease-fast
        var min: u32 = std.math.maxInt(u32);
        for (as.items) |s| {
            if (try astar(allocator, &map, s, end)) |path_len| {
                if (path_len < min) {
                    min = path_len;
                }
            }
        }
        return min;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try utils.readLines(allocator, "input/twelve");
    defer utils.freeLines(allocator, lines);

    const one = try run(true, allocator, lines);
    const two = try run(false, allocator, lines);

    std.debug.print("1: {}\n2: {}\n", .{ one, two });
}
