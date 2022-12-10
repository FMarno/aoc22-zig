const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try utils.readLines(allocator, "input/ten");
    defer utils.freeLines(allocator, lines);

    const cycles = [_]usize{ 19, 59, 99, 139, 179, 219 };
    var values = std.mem.zeroes([240]i32);

    var cycle: usize = 0;
    var reg: i32 = 1;

    for (lines) |line| {
        values[cycle] = reg;
        if (!std.mem.eql(u8, "noop", line)) {
            const space = std.mem.indexOf(u8, line, " ").?;
            const val: i32 = try std.fmt.parseInt(i32, line[space + 1 ..], 10);

            cycle += 1;
            if (cycle == values.len) break;
            values[cycle] = reg;
            reg += val;
        }

        cycle += 1;
        if (cycle == values.len) break;
    }

    var sum: i32 = 0;
    for (cycles) |c| {
        const mult = @intCast(i32, c) + 1;
        sum += values[c] * (mult);
    }

    std.debug.print("1: {}\n", .{sum});

    var row: usize = 0;
    while (row < 6) : (row += 1) {
        var col: usize = 0;
        while (col < 40) : (col += 1) {
            const idx = row * 40 + col;
            const x = values[idx];
            const distance = try std.math.absInt(@intCast(i32, col) - x);
            const c :u8 = if (distance < 2) '#' else '.';
            std.debug.print("{c}", .{c});
        }
        std.debug.print("\n", .{});
    }
}
