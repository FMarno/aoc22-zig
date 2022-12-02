const std = @import("std");

const Hand = enum { rock, paper, scissors };
const Outcome = enum { lose, draw, win };

fn play(elf_hand: Hand, my_hand: Hand) Outcome {
    if (elf_hand == my_hand) return .draw;
    return switch (my_hand) {
        .rock => if (elf_hand == .scissors) .win else .lose,
        .paper => if (elf_hand == .rock) .win else .lose,
        .scissors => if (elf_hand == .paper) .win else .lose,
    };
}

fn one_score(elf_hand: Hand, my_hand: Hand) u32 {
    const hand_score: u32 = switch (my_hand) {
        .rock => 1,
        .paper => 2,
        .scissors => 3,
    };
    const game_score: u32 = switch (play(elf_hand, my_hand)) {
        .lose => 0,
        .draw => 3,
        .win => 6,
    };
    return hand_score + game_score;
}

fn hand(elf_hand: Hand, my_outcome: Outcome) Hand {
    if (my_outcome == .draw) return elf_hand;
    return switch (elf_hand) {
        .rock => if (my_outcome == .win) .paper else .scissors,
        .paper => if (my_outcome == .win) .scissors else .rock,
        .scissors => if (my_outcome == .win) .rock else .paper,
    };
}

fn two_score(elf_hand: Hand, my_outcome: Outcome) u32 {
    const my_hand = hand(elf_hand, my_outcome);
    const hand_score: u32 = switch (my_hand) {
        .rock => 1,
        .paper => 2,
        .scissors => 3,
    };
    const game_score: u32 = switch (my_outcome) {
        .lose => 0,
        .draw => 3,
        .win => 6,
    };
    return hand_score + game_score;
}

pub fn main() !void {
    var buf: [8]u8 = undefined;

    const file = try std.fs.cwd().openFile("input/two", .{ .mode = .read_only });
    defer file.close();

    var reader = file.reader();

    var one_sum: u32 = 0;
    var two_sum: u32 = 0;

    while (reader.readUntilDelimiter(buf[0..], '\n')) |read| {
        if (read.len == 0) break;
        const elf = read[0];
        const me = read[2];
        const elf_hand: Hand = switch (elf) {
            'A' => .rock,
            'B' => .paper,
            'C' => .scissors,
            else => @panic("unexpected letter"),
        };
        const my_hand: Hand = switch (me) {
            'X' => .rock,
            'Y' => .paper,
            'Z' => .scissors,
            else => @panic("unexpected letter"),
        };
        const my_outcome: Outcome = switch (me) {
            'X' => .lose,
            'Y' => .draw,
            'Z' => .win,
            else => @panic("unexpected letter"),
        };
        one_sum += one_score(elf_hand, my_hand);
        two_sum += two_score(elf_hand, my_outcome);
    } else |err| {
        if (err != error.EndOfStream) {
            @panic("unexpected error");
        }
    }

    std.debug.print("1: {}\n2: {}\n", .{ one_sum, two_sum });
}
