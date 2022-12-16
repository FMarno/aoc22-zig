const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input = try utils.readAll(allocator, "input/one");
    defer allocator.free(input);

    var lines = std.mem.split(u8, input, "\n");

    var max = [3]u32{ 0, 0, 0 };
    var current: u32 = 0;

    while (lines.next()) |line| {
        if (line.len == 0) {
            if (current > max[0]) {
                max[2] = max[1];
                max[1] = max[0];
                max[0] = current;
            } else if (current > max[1]) {
                max[2] = max[1];
                max[1] = current;
            } else if (current > max[2]) {
                max[2] = current;
            }

            current = 0;
        } else {
            const val: u32 = try std.fmt.parseUnsigned(u32, line, 10);
            current += val;
        }
    }

    var sum: u32 = 0;
    for (max) |v| {
        sum += v;
    }

    std.debug.print("1: {}\n2: {}\n", .{ max[0], sum });
}
