const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try utils.readLines(allocator, "input/eight");
    defer utils.freeLines(allocator, lines);

    for (lines) |line| {
        for (line) |*char| {
            char.* = char.* - '0';
            std.debug.assert(char.* < 10);
            std.debug.print("{}", .{char.*});
        }
        std.debug.print("\n", .{});
    }

    var sum: i32 = 0;
    std.debug.print("1: {}\n", .{sum});
}
