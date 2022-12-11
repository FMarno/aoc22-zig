const std = @import("std");
const utils = @import("utils.zig");
const parseUnsigned = std.fmt.parseUnsigned;

const Operator = enum { add, mult, square };

const Item = u64;

const primes = Item{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97 };

const PrimeFactor = struct {
    value: Item,
    power: i32,
};

const PrimeFactorisation = struct {
    const Self = @This();
    factors: std.ArrayList(PrimeFactor),

    fn init(scalar:Item, allocator:std.mem.Allocator) Self {
        var new = PrimeFactorisation{
            .factors = std.ArrayList(PrimeFactor).init(allocator),
        };
        // start at 1
        new.factors.append(PrimeFactorisation{.value=2,.power=0});
        new.multByScalar(scalar);
        return new;
    }
    fn deinit(self : *Self) void {
        self.factors.deinit();
    }

    fn mult(self: *Self, other: Self) !void {
        for (other.factors.items) |factor| {
            self.multByPrime(factor);
        }
    }

    fn square(self: *Self) void {
        for (self.factors.items) |*own_factor| {
            own_factor.power *= 2;
        }
    }

    fn multByPrime(self: *Self, prime: PrimeFactor) void {
        for (self.factors.items) |*own_factor| {
            if (prime.value == own_factor.value) {
                own_factor.power += prime.power;
                return;
            }
            // can't find factor
            try self.factors.append(prime);
        }
    }

    fn multByScalar(self: *Self, scalar: Item) void {
        var s = scalar;
        for (primes) |prime| {
            while (s % prime == 0) {
                self.multByPrime(PrimeFactor{ .value = prime, .power = 1 });
                s = s/prime;
            }
            if (s == 1) return;
        }
        unreachable;
    }

    fn add(self: *Self, other: Self) !void {
        // (2*(3^5)*5) + (3*7) = 3*(2*5*(3^4)+7) = 3 * 817 = 3*19*43
        var lhs = try self.factors.clone();
        var rhs = try other.factors.clone();
        var multiplier = try std.Allocator(Item).init(lhs.allocator);

        for (lhs.items) |*lfactor| {
            for (lhs.items) |*rfactor| {
                if (lfactor.value == rfactor.value) {
                    const diff = std.math.absInt(lfactor.power - rfactor.power);
                    lfactor.power -= diff;
                    rfactor.power -= diff;
                    multiplier.append(PrimeFactor{ .value = lfactor.value, .power = diff });
                    break;
                }
            }
        }

        // actually calculate the numbers
        // hopefully small enough
        var sum: Item = 0;
        for (lhs.items) |factor| {
            sum += std.math.pow(Item, factor.value, factor.power);
        }
        for (rhs.items) |factor| {
            sum += std.math.pow(Item, factor.value, factor.power);
        }

        // prime factorize
        self.multByScalar(sum);
    }
};

fn Monkey(comptime part1: bool) type {
    return struct {
        const Self = @This();
        items: std.ArrayList(Item),
        op: Operator,
        opValue: Item,
        testValue: Item,
        true_monkey: usize,
        false_monkey: usize,
        inspections: u64,

        fn init(allocator: std.mem.Allocator, op: Operator, opValue: Item, testValue: Item, true_monkey: usize, false_monkey: usize) Self {
            return Self{
                .items = std.ArrayList(Item).init(allocator),
                .op = op,
                .opValue = opValue,
                .testValue = testValue,
                .true_monkey = true_monkey,
                .false_monkey = false_monkey,
                .inspections = 0,
            };
        }

        fn deinit(self: *Self) void {
            self.items.deinit();
        }

        fn throw_item(self: *Self, item: Item) !void {
            try self.items.append(item);
        }

        fn process_items(self: *Self, other_monkeys: []Self) !void {
            while (self.items.items.len != 0) {
                const item = self.items.orderedRemove(0);
                std.debug.print("{} {} {}\n", .{ item, self.op, self.opValue });
                var worry = switch (self.op) {
                    .add => item + self.opValue,
                    .mult => item * self.opValue,
                    .square => item * item,
                };
                if (part1) {
                    worry = worry / 3;
                }
                const target_monkey = if (worry % self.testValue == 0) self.true_monkey else self.false_monkey;
                try other_monkeys[target_monkey].throw_item(worry);
                self.inspections += 1;
            }
        }

        fn greaterThan(ctx: @TypeOf(.{}), lhs: Self, rhs: Self) bool {
            _ = ctx;
            return lhs.inspections > rhs.inspections;
        }
    };
}

fn run(comptime part1: bool, allocator: std.mem.Allocator, lines: []const []u8) !Item {
    var monkies = std.ArrayList(Monkey(part1)).init(allocator);
    defer {
        for (monkies.items) |*monkey| {
            monkey.deinit();
        }
        monkies.deinit();
    }

    var idx: usize = 0;
    while (idx < lines.len) : (idx += 7) {
        // Monkey 0:
        //   Starting items: 83, 88, 96, 79, 86, 88, 70
        //   Operation: new = old * 5
        //   Test: divisible by 11
        //     If true: throw to monkey 2
        //     If false: throw to monkey 3
        const items = lines[idx + 1]["  Starting items: ".len..];
        const opValueStr = lines[idx + 2]["  Operation: new = old * ".len..];
        var op: Operator = undefined;
        var opValue: Item = undefined;
        if (std.mem.eql(u8, opValueStr, "old")) {
            op = .square;
        } else {
            op = if (lines[idx + 2]["  Operation: new = old ".len] == '*') .mult else .add;
            opValue = try parseUnsigned(Item, opValueStr, 10);
        }
        const testValue = try parseUnsigned(Item, lines[idx + 3]["  Test: divisible by ".len..], 10);

        const true_monkey = try parseUnsigned(usize, lines[idx + 4]["    If true: throw to monkey ".len..], 10);
        const false_monkey = try parseUnsigned(usize, lines[idx + 5]["    If false: throw to monkey ".len..], 10);

        var monkey = Monkey(part1).init(allocator, op, opValue, testValue, true_monkey, false_monkey);

        var pos: usize = 0;
        while (std.mem.indexOfPos(u8, items, pos, ",")) |comma| {
            const new_item = try parseUnsigned(Item, items[pos..comma], 10);
            try monkey.throw_item(new_item);
            pos = comma + 2;
        }
        const final_item = try parseUnsigned(Item, items[pos..], 10);
        try monkey.throw_item(final_item);
        try monkies.append(monkey);
    }

    const loops = if (part1) 20 else 10000;

    var i: usize = 0;
    while (i < loops) : (i += 1) {
        for (monkies.items) |*monkey| {
            try monkey.process_items(monkies.items);
        }
    }

    std.sort.sort(Monkey(part1), monkies.items, .{}, Monkey(part1).greaterThan);

    for (monkies.items) |monkey| {
        std.debug.print("{}\n", .{monkey.inspections});
    }

    const monkey_business = monkies.items[0].inspections * monkies.items[1].inspections;
    return monkey_business;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try utils.readLines(allocator, "input/test");
    defer utils.freeLines(allocator, lines);

    const one = try run(true, allocator, lines);
    //const two = try run(false, allocator, lines);

    std.debug.print("1: {}\n2: {}\n", .{ one, one });
}
