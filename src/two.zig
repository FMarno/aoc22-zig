const std = @import("std");

const Hand = enum(i32) { rock = 0, paper = 1, scissors = 2 };
const Outcome = enum(i32) { draw = 0, win = 1, lose = 2 };

fn play(elf_hand: Hand, my_hand: Hand) Outcome {
    return @intToEnum(Outcome, @mod(@enumToInt(my_hand) - @enumToInt(elf_hand), 3));
    // if (elf_hand == my_hand) return .draw;
    // return switch (my_hand) {
    //     .rock => if (elf_hand == .scissors) .win else .lose,
    //     .paper => if (elf_hand == .rock) .win else .lose,
    //     .scissors => if (elf_hand == .paper) .win else .lose,
    // };
}

fn find_hand(elf_hand: Hand, my_outcome: Outcome) Hand {
    return @intToEnum(Hand, @mod(@enumToInt(elf_hand) + @enumToInt(my_outcome), 3));
    // if (my_outcome == .draw) return elf_hand;
    // return switch (elf_hand) {
    //     .rock => if (my_outcome == .win) .paper else .scissors,
    //     .paper => if (my_outcome == .win) .scissors else .rock,
    //     .scissors => if (my_outcome == .win) .rock else .paper,
    // };
}

fn score(hand: Hand, outcome: Outcome) i32 {
    const hand_score: i32 = @enumToInt(hand) + 1;
    const game_score: i32 = switch (outcome) {
        .lose => 0,
        .draw => 3,
        .win => 6,
    };
    return hand_score + game_score;
}

fn one_score(elf_hand: Hand, my_hand: Hand) i32 {
    return score(my_hand, play(elf_hand, my_hand));
}

fn two_score(elf_hand: Hand, my_outcome: Outcome) i32 {
    return score(find_hand(elf_hand, my_outcome), my_outcome);
}

pub fn main() !void {
    var buf: [8]u8 = undefined;

    const file = try std.fs.cwd().openFile("input/two", .{ .mode = .read_only });
    defer file.close();

    var reader = file.reader();

    var one_sum: i32 = 0;
    var two_sum: i32 = 0;

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
