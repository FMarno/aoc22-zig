const std = @import("std");

pub fn main() !void {
    var buf: [1024]u8 = std.mem.zeroes([1024]u8);

    const file = try std.fs.cwd().openFile("input/one", .{ .mode = .read_only });
    defer file.close();

    var reader = file.reader();

    var max = [3]u32{ 0, 0, 0 };
    var current: u32 = 0;

    while (reader.readUntilDelimiter(buf[0..], '\n')) |read| {
        if (read.len == 0) {
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
            const val: u32 = try std.fmt.parseUnsigned(u32, read, 10);
            current += val;
        }
    } else |err| {
        if (err != error.EndOfStream) {
            @panic("unexpected error");
        }
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
    }

    var sum: u32 = 0;
    for (max) |v| {
        sum += v;
    }

    std.debug.print("1: {}\n2: {}\n", .{ max[0], sum });
}
