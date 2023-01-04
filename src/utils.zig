const std = @import("std");

pub fn readAll(allocator: std.mem.Allocator, comptime file_path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
    defer file.close();
    var reader = file.reader();

    return reader.readAllAlloc(allocator, 1024 * 1024);
}

pub fn readLines(allocator: std.mem.Allocator, comptime file_path: []const u8) ![][]u8 {
    var lines = std.ArrayList([]u8).init(allocator);

    const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
    defer file.close();
    var reader = file.reader();

    while (reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |maybe_read| {
        if (maybe_read) |read| {
            try lines.append(read);
        } else break;
    } else |e| return e;
    return lines.toOwnedSlice();
}

pub fn freeLines(allocator: std.mem.Allocator, lines: [][]u8) void {
    for (lines) |line| {
        allocator.free(line);
    }
    allocator.free(lines);
}

pub fn orderedInsert(comptime T: type, list: *std.ArrayList(T), value: T, comptime lessThan: fn (a: T, b: T) bool) !void {
    for (list.items) |item, idx| {
        if (lessThan(value, item)) {
            try list.insert(idx, value);
            return;
        }
    }
    try list.append(value);
}
