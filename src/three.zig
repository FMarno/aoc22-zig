const std = @import("std");

const Rucksake = struct {
    const Self = @This();
    set: u52,

    fn new() Self {
        return Self{
            .set = 0,
        };
    }

    fn add(self: *Self, c: u8) void {
        const idx = if (c <= 'Z') c - 'A' + 26 else c - 'a';
        self.set = self.set | (@as(u52, 1) << @intCast(u6, idx));
    }

    fn common_items(self: Self, other: Self) Self {
        return Self{ .set = self.set & other.set };
    }

    fn all_items(self: Self, other: Self) Self {
        return Self{ .set = self.set | other.set };
    }

    fn priority(self: Self) u32 {
        return @ctz(self.set) + 1;
    }
};

pub fn main() !void {
    var buf: [1024]u8 = undefined;

    const file = try std.fs.cwd().openFile("input/three", .{ .mode = .read_only });
    defer file.close();

    var reader = file.reader();

    var one_sum: u32 = 0;
    var two_sum: u32 = 0;

    var common = Rucksake.new();
    var group_idx: usize = 0;

    while (reader.readUntilDelimiterOrEof(buf[0..], '\n')) |maybe_read| {
        if (maybe_read) |read| {

            // Stupid Bill Microsoft
            const line = if (read[read.len - 1] == '\r') read[0 .. read.len - 1] else read;

            std.debug.assert(line.len & 1 == 0);
            var first = Rucksake.new();
            var second = Rucksake.new();
            var i: usize = 0;
            while (i < line.len / 2) : (i += 1) {
                first.add(line[i]);
            }
            while (i < line.len) : (i += 1) {
                second.add(line[i]);
            }
            one_sum += first.common_items(second).priority();

            common = if (group_idx == 0) first.all_items(second) else common.common_items(first.all_items(second));
            group_idx += 1;
            if (group_idx == 3) {
                two_sum += common.priority();
                group_idx = 0;
                common = Rucksake.new();
            }
        } else break;
    } else |err| {
        if (err != error.EndOfStream) {
            @panic("unexpected error");
        }
    }

    std.debug.print("1: {}\n2: {}\n", .{ one_sum, two_sum });
}
