const std = @import("std");

const Range = struct {
    const Self = @This();
    low: u32,
    high: u32,

    fn eq(self: Self, other: Self) bool {
        return self.low == other.low and self.high == other.high;
    }
    fn overlaps(self: Self, other: Self) bool {
        if (self.low < other.low) {
            return (self.high - self.low) >= (other.low - self.low);
        } else {
            return (other.high - other.low) >= (self.low - other.low);
        }
    }
};

pub fn main() !void {
    var buf: [1024]u8 = undefined;

    const file = try std.fs.cwd().openFile("input/four", .{ .mode = .read_only });
    defer file.close();

    var reader = file.reader();

    var one_sum: u32 = 0;
    var two_sum: u32 = 0;

    while (reader.readUntilDelimiterOrEof(buf[0..], '\n')) |maybe_read| {
        if (maybe_read) |read| {
            const dash = std.mem.indexOf(u8, read, "-") orelse @panic("not found");
            const comma = (std.mem.indexOf(u8, read[dash..], ",") orelse @panic("not found")) + dash;
            const dash2 = (std.mem.indexOf(u8, read[comma..], "-") orelse @panic("not found")) + comma;

            const a_low = try std.fmt.parseUnsigned(u32, read[0..dash], 10);
            const a_high = try std.fmt.parseUnsigned(u32, read[dash + 1 .. comma], 10);
            const b_low = try std.fmt.parseUnsigned(u32, read[comma + 1 .. dash2], 10);
            const b_high = try std.fmt.parseUnsigned(u32, read[dash2 + 1 .. read.len], 10);

            const a = Range{ .low = a_low, .high = a_high };
            const b = Range{ .low = b_low, .high = b_high };

            const full_range = Range{ .low = std.math.min(a.low, b.low), .high = std.math.max(a.high, b.high) };
            one_sum += if (full_range.eq(a) or full_range.eq(b)) 1 else 0;
            two_sum += if (a.overlaps(b)) 1 else 0;
        } else break;
    } else |_| @panic("unexpected error");

    std.debug.print("1: {}\n2: {}\n", .{ one_sum, two_sum });
}
