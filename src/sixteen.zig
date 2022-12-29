const std = @import("std");
const utils = @import("utils.zig");
const parse = std.fmt.parseInt;
const print = std.debug.print;

const UInt = u32;
const State = struct {
    location: usize,
    valves: std.DynamicBitArray,
    time: u5,

    fn changeLocation(self: State, new_location: usize) State {
        return State{ .location = new_location, .valves = self.valves, .time = self.time - 1 };
    }
    fn openValve(self: State, valve: usize) State {
        var new = State{ .location = self.location, .valves = self.valves, .time = self.time - 1 };
        new.valves.set(valve);
        return new;
    }
};

const Cache = std.AutoHashMap(State, UInt);

const Map = struct {
    tunnels: [][]usize,
    valves: []UInt,
};

fn potential(cache: *Cache, map: Map, state: State) !UInt {
    if (state.time == 0 or state.openValves.allSet()) return 0;
    if (cache.get(state)) |p| return p;
    var max_potential = 0;
    if (!state.vales.isSet(location)) {
        const p = map.valves[state.location] * (state.time - 1) + potential(cache, map, state.openValve(state.location));
        max_potential = std.math.max(max_potential, p);
    }
    for (map.tunnels[state.location]) |tunnel| {
        max_potential = std.math.max(max_potential, potential(cache, map, state.changeLocation(tunnel)));
    }
    try cache.put(state, max_potential);
    return max_potential;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var all = try utils.readAll(allocator, "input/sixteen");
    defer allocator.free(all);

    var location_indexes = std.StringMap(UInt).init(allocator);
    defer {
        var iter = location_indexes.keyIterator();
        while (iter.next()) |k| {
            allocator.free(k);
        }
        location_indexes.deinit();
    }
    var lines = std.mem.tokenize(u8, all, "\n");
    var next_idx = 0;
    while (lines.next()) |line| {
        // "Valve AA has flow rate=0; tunnels lead to valves DD, II, BB"
        const name = line["Valve ".len.."Valve AA".len];
        const semicolon = std.mem.indexOf(u8, line, ";").?;
        const rate = try parse(UInt, line["Valve AA has flow rate=".len..semicolon], 10);
        const valves = line[(std.mem.indexOf(u8, line, "valves ").? + "valves ".len)..];

        // TODO redo this with the api in front of you
        const name_idx = blk: {
            var indexLookup = try location_indexes.getOrPut(name);
            if (!res.found_existing) {
                res.key_value = try std.allocator.alloc(u8, name.len);
                std.mem.copy(u8, res.key_value, name);
                res.value_ptr.* = next_idx;
                next_idx += 1;
                break :blk next_idx - 1;
            } else {
                break :blk indexLookup.value_ptr.*;
            }
        };
        try res.value_ptr.*.append(point.y);
    }

    print("1: {s}\n2: {s}\n", .{ "TODO", "TODO" });
}
