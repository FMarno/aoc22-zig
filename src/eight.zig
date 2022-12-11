const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try utils.readLines(allocator, "input/eight");
    defer utils.freeLines(allocator, lines);

    const height = lines.len;
    const width = lines[0].len;

    const visible = try allocator.alloc([]bool, height);
    for (visible) |*row| {
        row.* = try allocator.alloc(bool, width);
        std.mem.set(bool, row.*, false);
    }
    defer {
        for (visible) |*row| {
            allocator.free(row.*);
        }
        allocator.free(visible);
    }

    //for (lines) |line| {
    //    for (line) |*char| {
    //        char.* = char.* - '0';
    //        std.debug.assert(char.* < 10);
    //    }
    //}

    { // left to right
        var row: usize = 0;
        while (row < height) : (row += 1) {
            visible[row][0] = true;
            var max_so_far = lines[row][0];
            var col: usize = 1;
            while (col < width) : (col += 1) {
                const h = lines[row][col];
                if (h > max_so_far) {
                    visible[row][col] = true;
                    max_so_far = h;
                }
            }
        }
    }
    { // right to left
        var row: usize = 0;
        while (row < height) : (row += 1) {
            visible[row][width - 1] = true;
            var max_so_far = lines[row][width - 1];
            var col: usize = width - 2;
            while (true) : (col -= 1) {
                const h = lines[row][col];
                if (h > max_so_far) {
                    visible[row][col] = true;
                    max_so_far = h;
                }
                if (col == 0) break;
            }
        }
    }
    { // top to bottom
        var col: usize = 0;
        while (col < width) : (col += 1) {
            visible[0][col] = true;
            var max_so_far = lines[0][col];
            var row: usize = 1;
            while (row < height) : (row += 1) {
                const h = lines[row][col];
                if (h > max_so_far) {
                    visible[row][col] = true;
                    max_so_far = h;
                }
            }
        }
    }
    { // bottom to top
        var col: usize = 0;
        while (col < width) : (col += 1) {
            visible[height - 1][col] = true;
            var max_so_far = lines[height - 1][col];
            var row: usize = height - 2;
            while (true) : (row -= 1) {
                const h = lines[row][col];
                if (h > max_so_far) {
                    visible[row][col] = true;
                    max_so_far = h;
                }
                if (row == 0) break;
            }
        }
    }

    var count: i32 = 0;
    for (visible) |row| {
        for (row) |tree| {
            count += if (tree) 1 else 0;
            // const char :u8 =if (tree) '#' else '.';
            // std.debug.print("{c}", .{char});
        }
        // std.debug.print("\n", .{});
    }

    std.debug.print("1: {}\n", .{count});
}
