const std = @import("std");

fn UniqueStream(comptime size: usize) type {
    return struct {
        const Self = @This();
        ring: [size]u8,
        idx: usize,

        fn new() Self {
            return Self{ .ring = std.mem.zeroes([size]u8), .idx = 0 };
        }

        fn add(self: *Self, l: u8) void {
            self.ring[self.idx] = l;
            self.idx += 1;
            if (self.idx == size) self.idx = 0;
        }

        fn unique(self: Self) bool {
            var code: u26 = 0;
            for (self.ring) |c| {
                code = code | (@as(u26, 1) << @intCast(u5, (c - 'a')));
            }

            return @popCount(code) == size;
        }
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input/six", .{ .mode = .read_only });
    defer file.close();

    var reader = file.reader();

    var letters = try reader.readAllAlloc(allocator, 4294967296);
    defer allocator.free(letters);

    var ring = UniqueStream(4).new();
    ring.add(letters[0]);
    ring.add(letters[1]);
    ring.add(letters[2]);

    var idx: usize = 3;
    for (letters[3..]) |l| {
        ring.add(l);
        if (ring.unique()) break;
        idx += 1;
    }
    std.debug.print("{}\n", .{idx + 1});
}
