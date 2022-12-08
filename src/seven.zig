const std = @import("std");
const utils = @import("utils.zig");

const File = struct {
    name: []u8,
    size: u32,
};

const Dir = struct {
    const Self = @This();
    name: []const u8,
    dirs: ?[]Dir,
    files: ?[]File,
    parent: *Dir,
    s: u32,

    fn free(dir: *Self, allocator: std.mem.Allocator) void {
        if (dir.files) |files| {
            allocator.free(files);
        }
        if (dir.dirs) |dirs| {
            for (dirs) |*d| {
                d.free(allocator);
            }
            allocator.free(dirs);
        }
    }

    fn size(dir: *Self, count: *u32) u32 {
        var sum: u32 = 0;
        if (dir.files) |files| {
            for (files) |f| {
                sum += f.size;
            }
        }
        if (dir.dirs) |dirs| {
            for (dirs) |*d| {
                sum += d.size(count);
            }
        }
        if (sum <= 100000) count.* += sum;
        dir.s = sum; // cache the size as we go
        return sum;
    }

    fn find(dir: Self, to_delete: u32) ?u32 {
        var smallest: ?u32 = null;
        if (dir.dirs) |dirs| {
            for (dirs) |d| {
                if (d.s > to_delete) {
                    const s = find(d, to_delete) orelse d.s;
                    if (s > to_delete) {
                        smallest = if (smallest == null) s else @min(smallest.?, s);
                    }
                }
            }
        }
        return smallest;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit(); // don't bother with frees...
    const allocator = gpa.allocator();

    const lines = try utils.readLines(allocator, "input/seven");
    defer utils.freeLines(allocator, lines);

    var root = Dir{ .name = "/"[0..], .dirs = null, .files = null, .parent = undefined, .s = undefined };
    defer root.free(allocator);
    var cwd = &root;

    var dirs = std.ArrayList(Dir).init(allocator);
    defer dirs.deinit();
    var files = std.ArrayList(File).init(allocator);
    defer files.deinit();

    outer: for (lines) |line| {
        if (line[0] == '$') {
            // commands
            if (std.mem.eql(u8, line[2..4], "cd")) {
                const location = line[5..];
                //save any dirs and files
                if (cwd.*.dirs == null) {
                    cwd.*.dirs = if (dirs.items.len == 0) &.{} else dirs.toOwnedSlice();
                    cwd.*.files = if (files.items.len == 0) &.{} else files.toOwnedSlice();
                }
                if (std.mem.eql(u8, location, "..")) {
                    cwd = cwd.parent;
                } else if (std.mem.eql(u8, location, "/")) {
                    cwd = &root;
                } else {
                    for (cwd.*.dirs.?) |*d| {
                        if (std.mem.eql(u8, d.name, location)) {
                            cwd = d;
                            continue :outer;
                        }
                    }
                    unreachable;
                }
            }
        } else {
            // reading ls
            if (std.mem.eql(u8, line[0..3], "dir")) {
                var dir = try dirs.addOne();
                dir.* = Dir{
                    // location should stay alive with lines
                    .name = line[4..],
                    .dirs = null,
                    .files = null,
                    .parent = cwd,
                    .s = undefined,
                };
            } else {
                const space = std.mem.indexOf(u8, line, " ").?;
                const size: u32 = try std.fmt.parseUnsigned(u32, line[0..space], 10);
                const name = line[space + 1 ..];
                try files.append(File{ .name = name, .size = size });
            }
        }
    }
    if (cwd.*.dirs == null) {
        cwd.*.dirs = if (dirs.items.len == 0) &.{} else dirs.toOwnedSlice();
        cwd.*.files = if (files.items.len == 0) &.{} else files.toOwnedSlice();
    }

    var count: u32 = 0;
    const total = root.size(&count);
    std.debug.print("1: {}\n", .{count});

    const remaining = 70000000 - total;
    const to_delete = 30000000 - remaining;
    const smallest = root.find(to_delete);
    std.debug.print("2: {}\n", .{smallest.?});
}
