const std = @import("std");
// const input = @embedFile("inputs/15_sample.txt");
const input = @embedFile("inputs/15.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

/// the current turn
const Turn = struct {
    nth: usize, // the current turn is the n-th turn
    last_spoken: ?usize, // the number which was spoken last turn
};

/// info about a spoken number
const Spoken = struct {
    times: usize, // how many times the number was spoken
    second_to_last: ?usize, // when this number was spoken the second-to-last time
    last: usize, // when this number was spoken the last time
};

/// the game status
/// key: number which was spoken
/// value: how many times and when this number was spoken (last and second-to-last time)
const NumberMap = std.AutoHashMap(usize, Spoken);
/// play a game turn and update game status and current turn
// n_initial_turns is not null only for the initial turns
fn playTurn(m: *NumberMap, turn: *Turn, n_initial_turns: ?usize) !usize {
    // log.debug("{}", .{turn});
    var num_to_speak: usize = 0;
    if (n_initial_turns != null) {
        // zig: it's a bit annoying having to unwrap the optional value here. In
        // this branch we KNOW n_initial_turns can't possibly be null.
        // For example, Typescript would have been able to understand that.
        num_to_speak = n_initial_turns.?;
    }

    // const spoken = if (turn.last_spoken != null) m.get(turn.last_spoken.?).? else Spoken{ .times = 1, .last = turn.nth, .second_to_last = null };
    // same code, arguably more readable
    const spoken = blk: {
        if (turn.last_spoken != null) {
            break :blk m.get(turn.last_spoken.?).?;
        } else {
            break :blk Spoken{ .times = 1, .last = turn.nth, .second_to_last = null };
        }
    };

    if (spoken.times != 1) {
        num_to_speak = if (spoken.second_to_last == null) 0 else spoken.last - spoken.second_to_last.?;
    }

    const maybe_spoken = m.get(num_to_speak);
    const second_to_last = if (maybe_spoken == null) null else maybe_spoken.?.last;
    const times = if (maybe_spoken == null) 1 else maybe_spoken.?.times + 1;
    try m.put(num_to_speak, Spoken{ .times = times, .last = turn.nth, .second_to_last = second_to_last });
    turn.last_spoken = num_to_speak;
    turn.nth = turn.nth + 1;
    return num_to_speak;
}

fn answer(allocator: *mem.Allocator, last_turn: usize) !usize {
    var m = NumberMap.init(allocator);
    var num_to_speak: usize = undefined;
    var turn = Turn{ .nth = 1, .last_spoken = null };

    var it = mem.split(input, ",");
    while (it.next()) |s| {
        num_to_speak = try fmt.parseInt(usize, s, 10);
        _ = try playTurn(&m, &turn, num_to_speak);
    }

    while (turn.nth <= last_turn) {
        num_to_speak = try playTurn(&m, &turn, null);
    }

    return num_to_speak;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a1 = try answer(&arena.allocator, 2020);
    const a2 = try answer(&arena.allocator, 30000000);
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
    const a = try answer(&arena.allocator, 2020);
    // testing.expectEqual(@intCast(usize, 436), a);
    testing.expectEqual(@intCast(usize, 1015), a);
}

test "Day 15, part 2" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer(&arena.allocator, 30000000);
    // testing.expectEqual(@intCast(usize, 175594), a);
    testing.expectEqual(@intCast(usize, 201), a);
}
