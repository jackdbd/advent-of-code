const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/22_sample.txt");
const input = @embedFile("inputs/22.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

fn printRound(round: usize, slice_a: []usize, slice_b: []usize) void {
    std.debug.print("-- Round {} --\n", .{round});
    printDeck(1, slice_a);
    printDeck(2, slice_b);
}

fn printDeck(player: usize, slice: []usize) void {
    std.debug.print("Player {}'s deck: ", .{player});
    for (slice) |card, i| {
        if (i == slice.len - 1) {
            std.debug.print("{}\n", .{card});
        } else {
            std.debug.print("{}, ", .{card});
        }
    }
}

fn printPlay(card_a: usize, card_b: usize) void {
    std.debug.print("Player 1 plays: {}\n", .{card_a});
    std.debug.print("Player 2 plays: {}\n", .{card_b});
    const winner: usize = if (card_a > card_b) 1 else 2;
    std.debug.print("Player {} wins the round!\n", .{winner});
}

fn printResults(slices: Slices) void {
    std.debug.print("== Post-game results ==\n", .{});
    printDeck(1, slices.a);
    std.debug.print("\n", .{});
    printDeck(2, slices.b);
}

/// Return true if player 1 (slice_a) won this round.
fn playRound(slice_a: []usize, slice_b: []usize) bool {
    var x = slice_a[0];
    var y = slice_b[0];
    return x > y;
}

/// Create a new deck of cards for the player who won the round.
fn roundWinnerCards(allocator: *mem.Allocator, all_but_first: []usize, winner: usize, loser: usize) ![]usize {
    var cards = std.ArrayList(usize).fromOwnedSlice(allocator, all_but_first);
    try cards.append(winner);
    try cards.append(loser);
    return cards.toOwnedSlice();
}

const Slices = struct {
    a: []usize, // player 1's cards
    b: []usize, // player 2's cards
};

/// Play a two-player card game and return their final cards.
fn playGame(allocator: *mem.Allocator, slices: Slices) !Slices {
    var slice_a = slices.a;
    var slice_b = slices.b;

    var round: usize = 1;
    while (std.math.min(slice_a.len, slice_b.len) > 0) : (round += 1) {
        // printRound(round, slice_a, slice_b);
        if (playRound(slice_a, slice_b)) {
            // printPlay(slice_a[0], slice_b[0]);
            slice_a = try roundWinnerCards(allocator, slice_a[1..], slice_a[0], slice_b[0]);
            slice_b = slice_b[1..];
        } else {
            // printPlay(slice_a[0], slice_b[0]);
            slice_b = try roundWinnerCards(allocator, slice_b[1..], slice_b[0], slice_a[0]);
            slice_a = slice_a[1..];
        }
    }
    std.debug.assert(slice_a.len == 0 or slice_b.len == 0);
    return Slices{ .a = slice_a, .b = slice_b };
}

fn makeDecks(allocator: *mem.Allocator) ![][]usize {
    var decks = std.ArrayList([]usize).init(allocator);
    var itdecks = mem.split(input, "\n\n");
    while (itdecks.next()) |string| {
        var cards = std.ArrayList(usize).init(allocator);
        var itcards = mem.split(string, "\n");
        _ = itcards.next();
        while (itcards.next()) |s| {
            try cards.append(try fmt.parseInt(usize, s, 10));
        }
        try decks.append(cards.toOwnedSlice());
    }
    return decks.toOwnedSlice();
}

fn answer1(allocator: *mem.Allocator) !usize {
    const decks = try makeDecks(allocator);
    var slices = Slices{ .a = decks[0], .b = decks[1] };
    slices = try playGame(allocator, slices);
    // printResults(slices);

    const slice_winner = if (slices.a.len > 0) slices.a else slices.b;
    const n = slice_winner.len;
    var score: usize = 0;
    var j: usize = 0;
    while (j < n) : (j += 1) {
        score += (n - j) * slice_winner[j];
    }
    return score;
}

fn answer2(allocator: *mem.Allocator) !usize {
    var result: usize = 0;
    return result;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a1 = try answer1(&arena.allocator);
    const a2 = try answer2(&arena.allocator);
    log.info("Part 1: {}", .{a1});
    log.info("Part 2: {}", .{a2});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 22 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "roundWinnerCards()" {
    var arr = [_]usize{ 9, 2, 6, 3, 1 };
    var slice = try roundWinnerCards(testing.allocator, arr[1..], 9, 5); // TODO: invalid free?
    testing.expectEqual(@intCast(usize, 6), slice.len);
}

// test "Day 22, part 1" {
//     const a = try answer1(testing.allocator);
//     testing.expectEqual(@intCast(usize, 0), a);
// }

// test "Day 22, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     testing.expectEqual(@intCast(usize, 0), a);
// }
