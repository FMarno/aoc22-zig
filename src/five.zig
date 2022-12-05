const std = @import("std");

const ParsePhase = enum { stacks, between, instructions };

const Stack = std.ArrayList(u8);
const StackList = []Stack;

fn parseStackLine(line: []u8, stacks: StackList) !void {
    for (stacks) |*stack, idx| {
        const val = line[idx * 4 + 1];
        if (val != ' ') {
            try stack.*.append(val);
        }
    }
}

fn parseInstructionLine(comptime part1: bool, line: []u8, stacks: StackList) !void {
    const move = std.mem.indexOf(u8, line, "move") orelse @panic("not found");
    const from = std.mem.indexOf(u8, line, "from") orelse @panic("not found");
    const to = std.mem.indexOf(u8, line, "to") orelse @panic("not found");
    const num_buf = line[move + 5 .. from - 1];
    const origin_buf = line[from + 5 .. to - 1];
    const dest_buf = line[to + 3 ..];
    const num = try std.fmt.parseUnsigned(u32, num_buf, 10);
    const origin = try std.fmt.parseUnsigned(usize, origin_buf, 10) - 1;
    const dest = try std.fmt.parseUnsigned(usize, dest_buf, 10) - 1;

    if (part1) {
        var i: u32 = 0;
        while (i < num) : (i += 1) {
            try stacks[dest].append(stacks[origin].pop());
        }
    } else {
        const range = stacks[origin].items[stacks[origin].items.len - num ..];
        try stacks[dest].appendSlice(range);
        var i: u32 = 0;
        while (i < num) : (i += 1) {
            _ = stacks[origin].pop();
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var buf: [1024]u8 = undefined;

    const file = try std.fs.cwd().openFile("input/five", .{ .mode = .read_only });
    defer file.close();

    var reader = file.reader();

    var phase = ParsePhase.stacks;

    var firstline = try reader.readUntilDelimiterOrEof(buf[0..], '\n') orelse @panic("no line");
    const num_stacks = firstline.len / 4 + 1;
    var all_stacks = try allocator.alloc(Stack, num_stacks * 2);
    defer allocator.free(all_stacks);
    for (all_stacks) |*stack| {
        stack.* = Stack.init(allocator);
    }
    defer {
        for (all_stacks) |stack| {
            stack.deinit();
        }
    }

    var stacks1 = all_stacks[0..num_stacks];
    var stacks2 = all_stacks[num_stacks..];
    try parseStackLine(firstline, stacks1);
    try parseStackLine(firstline, stacks2);

    while (reader.readUntilDelimiterOrEof(buf[0..], '\n')) |maybe_read| {
        if (maybe_read) |read| {
            switch (phase) {
                .stacks => {
                    if (read[1] == '1') {
                        phase = .between;
                    } else {
                        try parseStackLine(read, stacks1);
                        try parseStackLine(read, stacks2);
                    }
                },
                .between => {
                    for (all_stacks) |stack| {
                        std.mem.reverse(u8, stack.items);
                    }
                    phase = .instructions;
                },
                .instructions => {
                    try parseInstructionLine(true, read, stacks1);
                    try parseInstructionLine(false, read, stacks2);
                },
            }
        } else break;
    } else |_| @panic("unexpected error");

    for (stacks1) |stack| {
        std.debug.print("{c}", .{stack.items[stack.items.len - 1]});
    }
    std.debug.print("\n", .{});
    for (stacks2) |stack| {
        std.debug.print("{c}", .{stack.items[stack.items.len - 1]});
    }
    std.debug.print("\n", .{});
}
