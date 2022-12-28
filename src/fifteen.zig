const std = @import("std");
const utils = @import("utils.zig");
const parse = std.fmt.parseInt;
const print = std.debug.print;

const Int = i32;
const Range = struct {
    start: Int,
    end: Int,
};

const RangeList = std.ArrayList(Range);

fn manhattan(sx: Int, sy: Int, bx: Int, by: Int) !i32 {
    return (try std.math.absInt(sx - bx)) + (try std.math.absInt(sy - by));
}

fn addRange(ranges: *RangeList, new_range: Range) !void {
    for (ranges.items) |*range| {
        // check for any overlap
        if (new_range.end < range.start or range.end < new_range.start) continue;
        range.start = std.math.min(range.start, new_range.start);
        range.end = std.math.max(range.end, new_range.end);
        return;
    }
    try ranges.append(new_range);
}

fn countRange(ranges: RangeList) Int {
    var count: Int = 0;
    count += @intCast(Int,ranges.items.len); // range is inclusive
    for (ranges.items) |range| {
        count += range.end - range.start;
    }
    return count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var all = try utils.readAll(allocator, "input/fifteen");
    defer allocator.free(all);

    var ranges = RangeList.init(allocator);
    defer ranges.deinit();

    const target_line = 2000000;

    var lines = std.mem.tokenize(u8, all, "\n");
    while (lines.next()) |line| {
        // "Sensor at x=2, y=18: closest beacon is at x=-2,y=15"
        const x_mark = "x=";
        const y_mark = "y=";
        const x1 = std.mem.indexOf(u8, line, x_mark).? + x_mark.len;
        const comma1 = std.mem.indexOf(u8, line[x1..], ",").? + x1;
        const y1 = std.mem.indexOf(u8, line[comma1..], y_mark).? + y_mark.len + comma1;
        const colon = std.mem.indexOf(u8, line[y1..], ":").? + y1;

        const sx = try parse(Int, line[x1..comma1], 10);
        const sy = try parse(Int, line[y1..colon], 10);

        const x2 = std.mem.indexOf(u8, line[colon..], x_mark).? + x_mark.len + colon;
        const comma2 = std.mem.indexOf(u8, line[x2..], ",").? + x2;
        const y2 = std.mem.indexOf(u8, line[comma2..], y_mark).? + y_mark.len + comma2;

        const bx = try parse(Int, line[x2..comma2], 10);
        const by = try parse(Int, line[y2..], 10);

        var md = try manhattan(sx, sy, bx, by);
        var delta_y = try std.math.absInt(target_line - sy);
        if (md >= delta_y) {
            const extra = md - delta_y;
            try addRange(&ranges, Range{ .start = sx - extra, .end = sx + extra });
        }
    }

    const one = countRange(ranges);

    print("1: {}\n2: {s}\n", .{ one, "TODO" });
}
