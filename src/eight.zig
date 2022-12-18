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
        }
    }

    std.debug.print("1: {}\n", .{count});

    var max: u32 = 0;
    var row: usize = 0;
    while (row < height) : (row += 1) {
        var col: usize = 0;
        while (col < width) : (col += 1) {
            {
                const tree_h = lines[row][col];
                var right: u32 = 0;
                var left: u32 = 0;
                var up: u32 = 0;
                var down: u32 = 0;
                { // right
                    var c = col + 1;
                    while (c < width) : (c += 1) {
                        right += 1;
                        if (lines[row][c] >= tree_h) break;
                    }
                }
                { // down
                    var r = row + 1;
                    while (r < height) : (r += 1) {
                        down += 1;
                        if (lines[r][col] >= tree_h) break;
                    }
                }
                { // left
                    var c = col;
                    while (c != 0) {
                        c -= 1;
                        left += 1;
                        if (lines[row][c] >= tree_h) break;
                    }
                }
                { // up
                    var r = row;
                    while (r != 0) {
                        r -= 1;
                        up += 1;
                        if (lines[r][col] >= tree_h) break;
                    }
                }
                const score = right * left * up * down;
                if (score > max) {
                    max = score;
                }
            }
        }
    }
    std.debug.print("2: {}\n", .{max});
}
