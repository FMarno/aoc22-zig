const std = @import("std");
const utils = @import("utils.zig");
const parseUnsigned = std.fmt.parseUnsigned;
const print = std.debug.print;

const Operator = enum { add, mult, square };

// Spoilers:
// The monkey only questions if something divides equally by a constant value
// so we only need to keep the remainder up to data
// but we do need to track it for all monkies at all times
// clever monkies!
const Remainders = []u32;

const Monkey = struct {
    const Self = @This();
    items: std.ArrayList(Remainders),
    divisors: []u32,
    op: Operator,
    opValue: u32,
    remainder_idx: usize,
    true_monkey: usize,
    false_monkey: usize,
    inspections: u32,

    // still need to setup items and divisors after this
    fn init(allocator: std.mem.Allocator, op: Operator, opValue: u32, remainder_idx: usize, true_monkey: usize, false_monkey: usize) Self {
        return Self{
            .items = std.ArrayList(Remainders).init(allocator),
            .divisors = undefined,
            .op = op,
            .opValue = opValue,
            .remainder_idx = remainder_idx,
            .true_monkey = true_monkey,
            .false_monkey = false_monkey,
            .inspections = 0,
        };
    }

    fn deinit(self: *Self) void {
        for (self.items.items) |i| {
            self.items.allocator.free(i);
        }
        self.items.deinit();
    }

    fn throw_item(self: *Self, item: Remainders) !void {
        try self.items.append(item);
    }

    fn process_items(self: *Self, other_monkeys: []Self) !void {
        while (self.items.items.len != 0) {
            var remainders = self.items.orderedRemove(0);
            for (self.divisors) |divisor, idx| {
                switch (self.op) {
                    // I did a bit of math to prove this was all ok,
                    // but couldn't figure out the /3.
                    .add => remainders[idx] = (remainders[idx] + self.opValue) % divisor,
                    .mult => remainders[idx] = (remainders[idx] * self.opValue) % divisor,
                    .square => remainders[idx] = (remainders[idx] * remainders[idx]) % divisor,
                }
            }
            const target_monkey = if (remainders[self.remainder_idx] == 0) self.true_monkey else self.false_monkey;
            try other_monkeys[target_monkey].throw_item(remainders);
            self.inspections += 1;
        }
    }

    fn greaterThan(ctx: @TypeOf(.{}), lhs: Self, rhs: Self) bool {
        _ = ctx;
        return lhs.inspections > rhs.inspections;
    }
};

fn run(allocator: std.mem.Allocator, lines: []const []u8) !u64 {
    var monkies = std.ArrayList(Monkey).init(allocator);
    defer {
        for (monkies.items) |*monkey| {
            monkey.deinit();
        }
        monkies.deinit();
    }
    var divisors = std.ArrayList(u32).init(allocator);
    var items = std.ArrayList(std.ArrayList(u32)).init(allocator);
    defer {
        for (items.items) |*i| {
            i.deinit();
        }
        items.deinit();
    }

    var idx: usize = 0;
    while (idx < lines.len) : (idx += 7) {
        // Monkey 0:
        //   Starting items: 83, 88, 96, 79, 86, 88, 70
        //   Operation: new = old * 5
        //   Test: divisible by 11
        //     If true: throw to monkey 2
        //     If false: throw to monkey 3
        const starting_items = lines[idx + 1]["  Starting items: ".len..];
        const opValueStr = lines[idx + 2]["  Operation: new = old * ".len..];
        var op: Operator = undefined;
        var opValue: u32 = undefined;
        if (std.mem.eql(u8, opValueStr, "old")) {
            op = .square;
            opValue = 1;
        } else {
            op = if (lines[idx + 2]["  Operation: new = old ".len] == '*') .mult else .add;
            opValue = try parseUnsigned(u32, opValueStr, 10);
        }
        const testValue = try parseUnsigned(u32, lines[idx + 3]["  Test: divisible by ".len..], 10);
        try divisors.append(testValue);

        const true_monkey = try parseUnsigned(usize, lines[idx + 4]["    If true: throw to monkey ".len..], 10);
        const false_monkey = try parseUnsigned(usize, lines[idx + 5]["    If false: throw to monkey ".len..], 10);

        var monkey = Monkey.init(allocator, op, opValue, idx / 7, true_monkey, false_monkey);

        var monkey_items = std.ArrayList(u32).init(allocator);

        var pos: usize = 0;
        while (std.mem.indexOfPos(u8, starting_items, pos, ",")) |comma| {
            const new_item = try parseUnsigned(u32, starting_items[pos..comma], 10);
            try monkey_items.append(new_item);
            pos = comma + 2;
        }
        const final_item = try parseUnsigned(u32, starting_items[pos..], 10);
        try monkey_items.append(final_item);
        try items.append(monkey_items);

        try monkies.append(monkey);
    }

    var divisor_slice = divisors.toOwnedSlice();
    defer allocator.free(divisor_slice);
    for (monkies.items) |*monkey| {
        monkey.divisors = divisor_slice;
        for (items.items[monkey.remainder_idx].items) |item| {
            var remainders = try allocator.alloc(u32, divisor_slice.len);
            std.mem.set(u32, remainders, item);
            try monkey.throw_item(remainders);
        }
    }

    const loops = 10000;

    var i: usize = 0;
    while (i < loops) : (i += 1) {
        for (monkies.items) |*monkey| {
            try monkey.process_items(monkies.items);
        }
    }

    std.sort.sort(Monkey, monkies.items, .{}, Monkey.greaterThan);

    const monkey_business = @intCast(u64, monkies.items[0].inspections) * @intCast(u64, monkies.items[1].inspections);
    return monkey_business;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try utils.readLines(allocator, "input/eleven");
    defer utils.freeLines(allocator, lines);

    const two = try run(allocator, lines);

    std.debug.print("1: TODO\n2: {}\n", .{ two });
}
