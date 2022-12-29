const std = @import("std");
const utils = @import("utils.zig");
const parse = std.fmt.parseInt;
const print = std.debug.print;

const Int = i32;
const Range = struct {
    start: Int,
    end: Int,

    fn overlapsWith(self: Range, other: Range) bool {
        return !(self.end < other.start or other.end < self.start);
    }

    fn merge(self: *Range, other: Range) void {
        self.start = std.math.min(self.start, other.start);
        self.end = std.math.max(self.end, other.end);
    }
};

const RangeList = std.ArrayList(Range);

fn manhattan(sx: Int, sy: Int, bx: Int, by: Int) !i32 {
    return (try std.math.absInt(sx - bx)) + (try std.math.absInt(sy - by));
}

const Sensor = struct {
    x: Int,
    y: Int,
    d: Int,
};
const SensorList = std.ArrayList(Sensor);

fn addRange(ranges: *RangeList, new_range: Range) !void {
    for (ranges.items) |*range, idx| {
        // check for any overlap
        if (range.overlapsWith(new_range)) {
            range.merge(new_range);
            while (idx + 1 != ranges.items.len and range.overlapsWith(ranges.items[idx + 1])) {
                range.merge(ranges.items[idx + 1]);
                _ = ranges.orderedRemove(idx + 1);
            }
            return;
        } else if (new_range.start < range.start) {
            try ranges.insert(idx, new_range);
            return;
        }
    }
    try ranges.append(new_range);
}

fn countRange(ranges: RangeList) Int {
    var count: Int = 0;
    for (ranges.items) |range| {
        count += range.end - range.start;
    }
    return count;
}

fn getRanges(ranges: *RangeList, sensors: []Sensor, y: Int) !void {
    ranges.clearRetainingCapacity();
    for (sensors) |sensor| {
        const delta_y = try std.math.absInt(y - sensor.y);
        if (sensor.d >= delta_y) {
            const extra = sensor.d - delta_y;
            try addRange(ranges, Range{ .start = sensor.x - extra, .end = sensor.x + extra });
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const filename = "input/fifteen";
    var all = try utils.readAll(allocator, filename);
    defer allocator.free(all);

    var sensors = SensorList.init(allocator);
    defer sensors.deinit();

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

        try sensors.append(Sensor{ .x = sx, .y = sy, .d = md });
    }

    var ranges = RangeList.init(allocator);
    defer ranges.deinit();
    const target_line: Int = if (std.mem.eql(u8, "input/test", filename)) 10 else 2000000;

    try getRanges(&ranges, sensors.items, target_line);
    const one = countRange(ranges);

    print("1: {}\n", .{one});

    for (sensors.items) |s|{
        print("{}\n", .{s.d});
    }
}
