const std = @import("std");
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

fn printRecursiveRound(game: usize, round: usize, slice_a: []usize, slice_b: []usize) void {
    std.debug.print("-- Round {} (Game {}) --\n", .{ round, game });
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
    std.debug.print("Player {} wins the round!\n\n", .{winner});
}

fn printResults(slices: Slices) void {
    std.debug.print("\n== Post-game results ==\n", .{});
    printDeck(1, slices.a);
    std.debug.print("\n", .{});
    printDeck(2, slices.b);
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

/// Generate a unique string hash from the two players' cards.
/// Thanks to the hash we will know if there was a previous round in this game
/// that had exactly the same cards in the same order in the same players' decks
fn stringHash(allocator: *mem.Allocator, slice_a: []usize, slice_b: []usize) ![]const u8 {
    // either Crc32 or Wyhash are fine, but Adler32 doesn't work. I don't know why...
    var hasher = std.hash.Crc32.init();
    hasher.update(mem.sliceAsBytes(slice_a));
    // we need to add a delimiter (it could be anything) to split the player's 1
    // contribute to the hash, from player's 2 contribute. Without a delimiter
    // [[1 2 3] [4 5]] would produce the same hash as [[1 2] [3 4 5]]
    hasher.update("x");
    hasher.update(mem.sliceAsBytes(slice_b));
    return try fmt.allocPrint(allocator, "{}", .{hasher.final()});
}

/// Play a two-player card game and return their final cards.
fn combat(allocator: *mem.Allocator, slices: Slices) !Slices {
    var slice_a = slices.a;
    var slice_b = slices.b;

    var round: usize = 1;
    while (slice_a.len > 0 and slice_b.len > 0) : (round += 1) {
        // printRound(round, slice_a, slice_b);
        // printPlay(slice_a[0], slice_b[0]);
        if (slice_a[0] > slice_b[0]) {
            slice_a = try roundWinnerCards(allocator, slice_a[1..], slice_a[0], slice_b[0]);
            slice_b = slice_b[1..];
        } else {
            slice_b = try roundWinnerCards(allocator, slice_b[1..], slice_b[0], slice_a[0]);
            slice_a = slice_a[1..];
        }
    }
    std.debug.assert(slice_a.len == 0 or slice_b.len == 0);
    return Slices{ .a = slice_a, .b = slice_b };
}

fn playRecursiveRound(allocator: *mem.Allocator, slice_a: []usize, slice_b: []usize, game: usize) !bool {
    var x = slice_a[0];
    var y = slice_b[0];
    if (x < slice_a.len and y < slice_b.len) {
        var slices = Slices{ .a = slice_a[1 .. x + 1], .b = slice_b[1 .. y + 1] };
        slices = try recursiveCombat(allocator, slices, game + 1);
        return slices.a.len > 0;
    } else {
        return x > y;
    }
}

/// Play a two-player card game (recursively) and return their final cards.
/// Note: we need to explicitly declare the error set because this is a recursive
/// function. If we don't do declare the error set,this function would fail to
/// compile with:
/// error: cannot resolve inferred error set.
fn recursiveCombat(allocator: *mem.Allocator, slices: Slices, game: usize) error{OutOfMemory}!Slices {
    // std.debug.print("\n=== Game {} ===\n\n", .{game});
    // defer std.debug.print("=== Exit Game {} ===\n\n", .{game});
    var seen = std.BufSet.init(allocator);
    var slice_a = slices.a;
    var slice_b = slices.b;

    var round: usize = 1;
    while (slice_a.len > 0 and slice_b.len > 0) : (round += 1) {
        const s = try stringHash(allocator, slice_a, slice_b);
        if (seen.exists(s)) {
            return Slices{ .a = slice_a, .b = slice_b };
        }

        try seen.put(s);

        if (try playRecursiveRound(allocator, slice_a, slice_b, game)) {
            slice_a = try roundWinnerCards(allocator, slice_a[1..], slice_a[0], slice_b[0]);
            slice_b = slice_b[1..];
        } else {
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

fn score(slices: Slices) usize {
    const slice_winner = if (slices.a.len > 0) slices.a else slices.b;
    const n = slice_winner.len;

    var result: usize = 0;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        result += (n - i) * slice_winner[i];
    }
    return result;
}

fn answer1(allocator: *mem.Allocator) !usize {
    const decks = try makeDecks(allocator);
    var slices = Slices{ .a = decks[0], .b = decks[1] };
    slices = try combat(allocator, slices);
    // printResults(slices);
    return score(slices);
}

fn answer2(allocator: *mem.Allocator) !usize {
    const decks = try makeDecks(allocator);
    var slices = Slices{ .a = decks[0], .b = decks[1] };
    slices = try recursiveCombat(allocator, slices, 1);
    // printResults(slices);
    return score(slices);
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a1 = try answer1(&arena.allocator);
    log.info("Part 1: {}", .{a1});
    const a2 = try answer2(&arena.allocator);
    log.info("Part 2: {}", .{a2});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 22 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

// TODO: memory leak
test "makeDecks()" {
    const decks = try makeDecks(testing.allocator);
    testing.expectEqual(@intCast(usize, 2), decks.len);
}

// TODO: double free
// test "roundWinnerCards()" {
//     var arr = [_]usize{ 9, 2, 6, 3, 1 };
//     var slice = try roundWinnerCards(testing.allocator, arr[1..], 9, 5); // TODO: invalid free?
//     testing.expectEqual(@intCast(usize, 6), slice.len);
// }

test "Day 22, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    testing.expectEqual(@intCast(usize, 32448), a);
}
