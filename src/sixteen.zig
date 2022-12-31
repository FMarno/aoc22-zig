const std = @import("std");
const utils = @import("utils.zig");
const parse = std.fmt.parseInt;
const print = std.debug.print;

const UInt = u32;
const State = struct {
    location: usize,
    valves: std.bit_set.IntegerBitSet(64),
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
    flow_rates: []UInt,
};

fn potential(cache: *Cache, map: Map, state: State) !UInt {
    if (state.time == 0 or state.valves.count() == map.flow_rates.len) return 0;
    if (cache.get(state)) |p| return p;
    var max_potential: UInt = 0;
    if (!state.valves.isSet(state.location)) {
        const p = map.flow_rates[state.location] * (state.time - 1) + try potential(cache, map, state.openValve(state.location));
        max_potential = std.math.max(max_potential, p);
    }
    for (map.tunnels[state.location]) |tunnel| {
        max_potential = std.math.max(max_potential, try potential(cache, map, state.changeLocation(tunnel)));
    }
    try cache.put(state, max_potential);
    return max_potential;
}

const NameMap = std.StringArrayHashMap(usize);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var all = try utils.readAll(allocator, "input/sixteen");
    defer allocator.free(all);

    var location_indexes = NameMap.init(allocator);
    defer {
        for (location_indexes.keys()) |k| {
            allocator.free(k);
        }
        location_indexes.deinit();
    }
    var flows = std.ArrayList(UInt).init(allocator);
    var tunnels = std.ArrayList([]usize).init(allocator);

    var lines = std.mem.tokenize(u8, all, "\n");
    var next_idx: usize = 0;
    while (lines.next()) |line| {
        // "Valve AA has flow rate=0; tunnels lead to valves DD, II, BB"
        const name = line["Valve ".len.."Valve AA".len];
        const semicolon = std.mem.indexOf(u8, line, ";").?;
        const rate = try parse(UInt, line["Valve AA has flow rate=".len..semicolon], 10);

        var name_copy = try allocator.alloc(u8, name.len);
        std.mem.copy(u8, name_copy, name);
        try location_indexes.put(name_copy, next_idx);
        next_idx += 1;
        try flows.append(rate);
    }
    lines.reset();
    // save connections for later so the names have the correct index
    while (lines.next()) |line| {
        // "Valve AA has flow rate=0; tunnels lead to valves DD, II, BB"
        const valve_list = blk: {
            if (std.mem.indexOf(u8, line, "valves ")) |idx| {
                break :blk idx + "valves ".len;
            } else {
                break :blk std.mem.indexOf(u8, line, "valve ").? + "valve ".len;
            }
        };
        var valves = std.mem.tokenize(u8, line[valve_list..], ", ");

        var connections = std.ArrayList(usize).init(allocator);
        while (valves.next()) |v| {
            const valve_idx = location_indexes.get(v).?;
            try connections.append(valve_idx);
        }
        try tunnels.append(connections.toOwnedSlice());
    }

    const map = Map{ .tunnels = tunnels.toOwnedSlice(), .flow_rates = flows.toOwnedSlice() };
    defer {
        for (map.tunnels) |t| {
            allocator.free(t);
        }
        allocator.free(map.tunnels);
        allocator.free(map.flow_rates);
    }
    var cache = Cache.init(allocator);
    defer cache.deinit();

    var state = State{ .location = location_indexes.get("AA").?, .time = 30, .valves = std.bit_set.IntegerBitSet(64).initEmpty() };
    for (map.flow_rates) |f, idx| {
        if (f == 0) {
            state.valves.set(idx);
        }
    }

    const one = try potential(&cache, map, state);

    print("1: {}\n2: {s}\n", .{ one, "TODO" });
}
