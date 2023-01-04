const std = @import("std");
const utils = @import("utils.zig");
const parse = std.fmt.parseInt;
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const Action = enum { move, open };

const UInt = u32;
const State = struct {
    location: usize,
    elephant_location: usize,
    valves: std.bit_set.IntegerBitSet(64),
    time: u5,

    // a more accurate overestimate makes a very large difference to the time. (orders of magnitude)
    fn overestimate(self: State, flow_rate: []UInt, distances: [][]UInt) UInt {
        var sum: UInt = 0;
        var turns: UInt = 0;
        for (flow_rate) |f, idx| {
            if (!self.valves.isSet(idx)) {
                const distance = std.math.min(distances[self.location][idx], distances[self.elephant_location][idx]);
                const time_to_turn = distance + 1 + (turns / 2);
                if (time_to_turn < self.time) {
                    const remaining_time = self.time - time_to_turn;
                    sum += f * remaining_time;
                    turns += 1;
                }
            }
        }
        return sum;
    }

    fn update(self: State, my_action: Action, my_arg: usize, ele_action: Action, ele_arg: usize) State {
        var new = self;
        new.time -= 1;
        switch (my_action) {
            .move => new.location = my_arg,
            .open => new.valves.set(my_arg),
        }
        switch (ele_action) {
            .move => new.elephant_location = ele_arg,
            .open => new.valves.set(ele_arg),
        }
        // the elephant and person are equivalent so it could be an optimization to always make location <= elephant_location
        // since the cache will now recognise they are equivalent
        if (new.elephant_location < new.location) {
            const temp = new.location;
            new.location = new.elephant_location;
            new.elephant_location = temp;
        }
        return new;
    }

    fn getNeighbours(self: State, map: Map, neighbours: *std.ArrayList(State)) void {
        neighbours.clearRetainingCapacity();
        const my_location_set = self.valves.isSet(self.location);
        const ele_location_set = self.valves.isSet(self.elephant_location);
        const my_locations = map.tunnels[self.location];
        const elephant_locations = map.tunnels[self.elephant_location];

        if (!my_location_set and !ele_location_set and self.location != self.elephant_location) {
            neighbours.appendAssumeCapacity(self.update(.open, self.location, .open, self.elephant_location));
        }

        if (!my_location_set) {
            for (elephant_locations) |l| {
                neighbours.appendAssumeCapacity(self.update(.open, self.location, .move, l));
            }
        }

        if (!ele_location_set) {
            for (my_locations) |l| {
                neighbours.appendAssumeCapacity(self.update(.move, l, .open, self.elephant_location));
            }
        }

        for (my_locations) |my_l| {
            for (elephant_locations) |ele_l| {
                neighbours.appendAssumeCapacity(self.update(.move, my_l, .move, ele_l));
            }
        }
    }
};

const Map = struct {
    tunnels: [][]usize,
    flow_rates: []UInt,
    distances: [][]UInt,
};

fn distanceBetween(allocator: Allocator, tunnels: [][]usize, start: usize, end: usize, comptime timeout: usize) !?UInt {
    const SearchState = struct {
        const Self = @This();
        traveled: UInt,
        location: usize,
        fn lessThan(lhs: Self, rhs: Self) bool {
            return lhs.traveled < rhs.traveled;
        }
    };
    var to_search = std.ArrayList(SearchState).init(allocator);
    defer to_search.deinit();
    var best_to = std.AutoHashMap(usize, UInt).init(allocator);
    defer best_to.deinit();

    try to_search.append(SearchState{ .traveled = 0, .location = start });
    while (to_search.items.len != 0) {
        const next = to_search.orderedRemove(0);
        if (next.location == end) {
            return next.traveled;
        }

        if (next.traveled == timeout) continue;

        const neighbours = tunnels[next.location];
        const distance_for_neighbour = next.traveled + 1;
        for (neighbours) |n| {
            var entry = try best_to.getOrPut(n);
            if (entry.found_existing and entry.value_ptr.* <= distance_for_neighbour) continue;
            entry.value_ptr.* = distance_for_neighbour;
            // since the distance always go up by 1 then the order is always maintained
            try to_search.append(SearchState{ .traveled = distance_for_neighbour, .location = n });
        }
    }
    return null;
}

fn potential(allocator: Allocator, map: Map, initial_state: State) !UInt {
    const SearchState = struct {
        const Self = @This();
        current_flow: UInt,
        state: State,
        est: UInt,
        fn greaterThan(lhs: Self, rhs: Self) bool {
            //  return lhs.current_flow > rhs.current_flow;
            return lhs.est > rhs.est;
        }
    };
    var to_search = std.ArrayList(SearchState).init(allocator);
    defer to_search.deinit();
    var best_to = std.AutoHashMap(State, UInt).init(allocator);
    defer best_to.deinit();

    var neighbours = std.ArrayList(State).init(allocator);
    defer neighbours.deinit();
    // up to 5 neighbours for a tunnel so 5*5 + 5 + 5 + 1
    try neighbours.ensureTotalCapacity(36);

    try to_search.append(SearchState{ .current_flow = 0, .state = initial_state, .est = 0 });
    var max: UInt = 0;
    var count: usize = 0;
    while (to_search.items.len != 0) {
        const next = to_search.orderedRemove(0);
        count += 1;
        //print("{} - m:{} e:{} v:{b}\n", .{ next.current_flow, next.state.location, next.state.elephant_location, next.state.valves.mask });
        if (next.state.valves.count() == map.flow_rates.len or next.state.time == 0) {
            continue;
        }

        next.state.getNeighbours(map, &neighbours);

        for (neighbours.items) |n| {
            var valves_set = next.state.valves;
            valves_set.toggleSet(n.valves);
            var gain: UInt = 0;
            while (valves_set.mask != 0) {
                const idx = valves_set.findFirstSet().?;
                gain += n.time * map.flow_rates[idx];
                valves_set.unset(idx);
            }
            const new_flow = next.current_flow + gain;
            if (new_flow > max) {
                max = new_flow;
                // prune the search space
                var left: usize = 0;
                var right = to_search.items.len;

                while (left < right) {
                    const mid = left + (right - left) / 2;
                    switch (std.math.order(to_search.items[mid].est, max)) {
                        .gt => left = mid + 1,
                        .lt => right = mid,
                        .eq => left = mid + 1,
                    }
                }
                to_search.items.len = left;
            }
            const final_est = new_flow + next.state.overestimate(map.flow_rates, map.distances);
            if (final_est < max) continue;
            var entry = try best_to.getOrPut(n);
            if (entry.found_existing and entry.value_ptr.* >= new_flow) continue;
            entry.value_ptr.* = new_flow;
            try utils.orderedInsert(SearchState, &to_search, SearchState{ .current_flow = new_flow, .state = n, .est = final_est }, SearchState.greaterThan);
        }
    }
    print("{} nodes analysed\n", .{count});
    return max;
}

const TunnelData = struct {
    name: []u8,
    flow: UInt,
};

fn tunnelGreaterThan(ctx: void, lhs: TunnelData, rhs: TunnelData) bool {
    _ = ctx;
    return lhs.flow > rhs.flow;
}

fn findTunnel(tunnels: []TunnelData, name: []const u8) ?usize {
    for (tunnels) |t, i| {
        if (std.mem.eql(u8, t.name, name)) return i;
    }
    return null;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var all = try utils.readAll(allocator, "input/sixteen");
    defer allocator.free(all);

    var tunnels = std.ArrayList(TunnelData).init(allocator);
    defer {
        for (tunnels.items) |n| {
            allocator.free(n.name);
        }
        tunnels.deinit();
    }

    var lines = std.mem.tokenize(u8, all, "\n");
    while (lines.next()) |line| {
        // "Valve AA has flow rate=0; tunnels lead to valves DD, II, BB"
        const name = line["Valve ".len.."Valve AA".len];
        const semicolon = std.mem.indexOf(u8, line, ";").?;
        const rate = try parse(UInt, line["Valve AA has flow rate=".len..semicolon], 10);

        var name_copy = try allocator.dupe(u8, name[0..]);
        try tunnels.append(.{ .name = name_copy, .flow = rate });
    }

    // sort tunnels by flow rate to make estimation heuristic easier
    std.sort.sort(TunnelData, tunnels.items, {}, tunnelGreaterThan);

    lines.reset();
    var connections = try allocator.alloc([]usize, tunnels.items.len);
    defer {
        for (connections) |c| {
            allocator.free(c);
        }
        allocator.free(connections);
    }
    // save connections for later so the names have the correct index
    while (lines.next()) |line| {
        const name = line["Valve ".len.."Valve AA".len];
        const tunnel_idx = findTunnel(tunnels.items, name[0..]).?;

        // "Valve AA has flow rate=0; tunnels lead to valves DD, II, BB"
        const valve_list = if (std.mem.indexOf(u8, line, "valves ")) |idx| idx + "valves ".len else std.mem.indexOf(u8, line, "valve ").? + "valve ".len;
        var valves = std.mem.tokenize(u8, line[valve_list..], ", ");

        var tunnel_connections = std.ArrayList(usize).init(allocator);
        while (valves.next()) |v| {
            const valve_idx = findTunnel(tunnels.items, v).?;
            try tunnel_connections.append(valve_idx);
        }
        connections[tunnel_idx] = tunnel_connections.toOwnedSlice();
    }

    const flows = try allocator.alloc(UInt, tunnels.items.len);
    defer allocator.free(flows);
    for (tunnels.items) |t, i| {
        flows[i] = t.flow;
    }

    const num_of_tunnels = tunnels.items.len;
    var distances = try allocator.alloc([]UInt, num_of_tunnels);

    for (distances) |*d| {
        d.* = try allocator.alloc(UInt, num_of_tunnels);
    }
    defer {
        for (distances) |d| {
            allocator.free(d);
        }
        allocator.free(distances);
    }

    var s: usize = 0;
    while (s != num_of_tunnels) : (s += 1) {
        var e: usize = 0;
        while (e != num_of_tunnels) : (e += 1) {
            distances[s][e] = (try distanceBetween(allocator, connections, s, e, 26)).?;
        }
    }

    const map = Map{ .tunnels = connections, .flow_rates = flows, .distances = distances };

    const start = findTunnel(tunnels.items, "AA").?;
    var state = State{ .location = start, .elephant_location = start, .time = 26, .valves = std.bit_set.IntegerBitSet(64).initEmpty() };
    std.debug.assert(tunnels.items.len <= state.valves.capacity());
    for (map.flow_rates) |f, idx| {
        if (f == 0) {
            state.valves.set(idx);
        }
    }

    const two = try potential(allocator, map, state);

    print("1: {s}\n2: {}\n", .{ "TODO", two });
}
