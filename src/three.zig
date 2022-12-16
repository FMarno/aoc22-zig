const std = @import("std");

const Rucksack = std.bit_set.IntegerBitSet(52);
fn find_idx(c: u8) usize {
    return if (c <= 'Z') c - 'A' + 26 else c - 'a';
}

pub fn main() !void {
    var buf: [1024]u8 = undefined;

    const file = try std.fs.cwd().openFile("input/three", .{ .mode = .read_only });
    defer file.close();

    var reader = file.reader();

    var one_sum: usize = 0;
    var two_sum: usize = 0;

    var common_alt: Rucksack = undefined;
    var group_idx: usize = 0;

    while (reader.readUntilDelimiterOrEof(buf[0..], '\n')) |maybe_read| {
        if (maybe_read) |read| {

            // Stupid Bill Microsoft
            const line = if (read[read.len - 1] == '\r') read[0 .. read.len - 1] else read;

            std.debug.assert(line.len & 1 == 0);
            var first = Rucksack.initEmpty();
            var second = Rucksack.initEmpty();
            { // part 1
                var i: usize = 0;
                while (i < line.len / 2) : (i += 1) {
                    first.set(find_idx(line[i]));
                }
                while (i < line.len) : (i += 1) {
                    second.set(find_idx(line[i]));
                }
                var bag_intersect = first;
                bag_intersect.setIntersection(second);
                one_sum += bag_intersect.findFirstSet().? + 1;
            }
            { // part2
                var bag_union = first;
                bag_union.setUnion(second);
                if (group_idx == 0) {
                    common_alt = bag_union;
                } else {
                    common_alt.setIntersection(bag_union);
                }
                group_idx += 1;
            }
            if (group_idx == 3) {
                two_sum += common_alt.findFirstSet().? + 1;
                group_idx = 0;
            }
        } else break;
    } else |_| @panic("unexpected error");

    try std.io.getStdOut().writer().print("1: {}\n2: {}\n", .{ one_sum, two_sum });
}
