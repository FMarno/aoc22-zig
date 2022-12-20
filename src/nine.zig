const std = @import("std");
const utils = @import("utils.zig");
const print = std.debug.print;

const Pos = struct {
    x: i32,
    y: i32,
};

fn follow(lead: Pos, tail: *Pos) void {
    const x_diff = lead.x - tail.x;
    const y_diff = lead.y - tail.y;
    const move = if (x_diff > 1 or x_diff < -1 or y_diff > 1 or y_diff < -1) Pos{ .x = std.math.sign(x_diff), .y = std.math.sign(y_diff) } else Pos{ .x = 0, .y = 0 };
    tail.* = Pos{ .x = tail.x + move.x, .y = tail.y + move.y };
}

fn run(comptime tail_len: usize, all: []u8, pos_set: *std.AutoHashMap(Pos, void)) !u32 {
    var lines = std.mem.split(u8, all, "\n");

    var head = Pos{ .x = 0, .y = 0 };
    var chain: [tail_len]Pos = undefined;
    std.mem.set(Pos, &chain, Pos{ .x = 0, .y = 0 });

    while (lines.next()) |line| {
        if (line.len == 0) break;
        const direction = line[0];
        const distance = try std.fmt.parseUnsigned(u32, line[2..], 10);

        var i: usize = 0;
        while (i < distance) : (i += 1) {
            switch (direction) {
                'U' => head.y += 1,
                'D' => head.y -= 1,
                'R' => head.x += 1,
                'L' => head.x -= 1,
                else => unreachable,
            }
            follow(head, &chain[0]);
            for (chain[1..]) |*tail, idx| {
                follow(chain[idx], tail);
            }
            try pos_set.put(chain[chain.len - 1], {});
        }
    }

    return pos_set.count();
}

pub fn main() !void {
    //    var gpa = std.heap.GeneralPurposeAllocator(.{.enable_memory_limit=true}){};
    //    defer _ = gpa.deinit();
    //    const allocator = gpa.allocator();
    var buff: [1024 * 512]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buff);
    const allocator = fba.allocator();

    const all = try utils.readAll(allocator, "input/nine");
    defer allocator.free(all);

    var pos_set = std.AutoHashMap(Pos, void).init(allocator);
    defer pos_set.deinit();

    const before = std.time.nanoTimestamp();
    const one = try run(1, all, &pos_set);
    pos_set.clearRetainingCapacity();
    const two = try run(9, all, &pos_set);
    const after = std.time.nanoTimestamp();

    print("1:{}\n2:{}\ntime:{} ns", .{ one, two, after - before });
}
