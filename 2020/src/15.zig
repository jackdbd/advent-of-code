const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/15_sample.txt");
const input = @embedFile("inputs/15.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

const Turn = struct {
    nth: usize,
    last_spoken: usize,
};

const Spoken = struct {
    times: usize,
    second_to_last: ?usize,
    last: usize,
};

const GameMap = std.AutoHashMap(usize, Spoken); // number which was spoken

fn playTurn(m: *GameMap, turn: *Turn) !usize {
    // log.debug("turn {}, last_spoken {}", .{turn.nth, turn.last_spoken});
    // log.debug("{}", .{turn});
    var num_to_speak: usize = 0;
    const spoken = m.get(turn.last_spoken).?;
    if (spoken.times == 1) {
        const maybe_spoken = m.get(num_to_speak);
        // log.debug("num_to_speak {} maybe_spoken {}", .{num_to_speak, maybe_spoken});
        const second_to_last = if (maybe_spoken == null) null else maybe_spoken.?.last;
        const times = if (maybe_spoken == null) 1 else maybe_spoken.?.times + 1;
        // log.debug("turn {} spoken.last {} spoken.second_to_last {} num_to_speak 0", .{ turn.nth, spoken.last, spoken.second_to_last});
        try m.put(num_to_speak, Spoken{ .times = times, .last = turn.nth, .second_to_last = second_to_last });
        turn.last_spoken = 0;
    } else {
        num_to_speak = if (spoken.second_to_last == null) 0 else spoken.last - spoken.second_to_last.?;
        // log.debug("num_to_speak {}", .{num_to_speak});
        const maybe_spoken = m.get(num_to_speak);
        const second_to_last = if (maybe_spoken == null) null else maybe_spoken.?.last;
        const times = if (maybe_spoken == null) 1 else maybe_spoken.?.times + 1;
        // log.debug("turn {} spoken.last {} second_to_last {} num_to_speak {}", .{ turn.nth, spoken.last, second_to_last, num_to_speak});
        try m.put(num_to_speak, Spoken{ .times = times, .last = turn.nth, .second_to_last = second_to_last });
        turn.last_spoken = num_to_speak;
    }
    turn.nth = turn.nth + 1;
    return num_to_speak;
}

fn answer1(allocator: *mem.Allocator) !usize {
    var num_to_speak: usize = 0;
    var game = GameMap.init(allocator);
    // var turns = std.AutoHashMap(usize, usize).init(allocator); // number spoken, turn
    // var spoken = std.AutoHashMap(usize, usize).init(allocator); // number spoken, times (i.e. how many times it was spoken)

    // var second_to_last_spoken: usize = 0; // just a starting point
    // var last_spoken: usize = 0; // just a starting point
    var turn = Turn{ .nth = 1, .last_spoken = 0 };
    var it = mem.split(input, ",");
    while (it.next()) |s| {
        const n = try fmt.parseInt(usize, s, 10);
        const maybe_spoken = game.get(n);
        const times = if (maybe_spoken == null) 1 else maybe_spoken.?.times + 1;
        const second_to_last = if (maybe_spoken == null) null else maybe_spoken.?.last;
        try game.put(n, Spoken{ .times = times, .last = turn.nth, .second_to_last = second_to_last });
        turn = Turn{ .nth = turn.nth + 1, .last_spoken = n };
    }

    while (turn.nth <= 2020) {
        num_to_speak = try playTurn(&game, &turn);
    }

    // const next_turn = try playTurn(&game, turn);
    // log.debug("next turn {}", .{ next_turn });

    // const next_turn2 = try playTurn(&game, next_turn);
    // log.debug("next turn2 {}", .{ next_turn2 });

    // var game_it = game.iterator();
    // while(game_it.next()) |e| {
    //     log.debug("e {}", .{e});
    // }

    // const ntimes = spoken.get(last_spoken);
    // if (ntimes != null and ntimes.? == 1) {
    //     try turns.put(0, turn + 1);
    //     const z = spoken.get(0).?;
    //     try spoken.put(0, z+1);
    //     last_spoken = 0;
    //     turn += 1;
    //     // log.debug("times zero now {}", .{ z+1 });
    // } else {
    //     const turn = turns.get(last_spoken).?;
    //     const n = 4;
    // }

    return num_to_speak;
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
    log.info("Day 15 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 15, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 436), a);
    testing.expectEqual(@intCast(usize, 1015), a);
}

// test "Day 15, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     // testing.expectEqual(@intCast(usize, 8), a);
//     testing.expectEqual(@intCast(usize, 1235), a);
// }
