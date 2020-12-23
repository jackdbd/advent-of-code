const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

const Link = struct {
    next: u32,
};

fn move(current: u32, cups: []Link) u32 {
    const i = current - 1;
    // scratch is the 3 picked-up cups, and the cup to their right
    var scratch: [4]u32 = undefined;
    for (scratch) |*x, j| {
        x.* = if (j == 0) cups[i].next else cups[scratch[j - 1] - 1].next;
    }

    // the destination cup cannot be one of the picked-up cups
    var dst = if (current > 1) current - 1 else cups.len;
    while (mem.indexOfScalar(u32, scratch[0..3], @intCast(u32, dst)) != null) {
        dst = if (dst > 1) dst - 1 else cups.len;
    }

    cups[scratch[2] - 1].next = cups[dst - 1].next;
    cups[dst - 1].next = scratch[0];
    cups[i].next = scratch[3];

    return scratch[3];
}

fn moveFor(amt: usize, initial: u32, cups: []Link) void {
    var i: usize = 0;
    var current = initial;
    while (i < amt) : (i += 1) {
        current = move(current, cups);
    }
}

fn answer1(allocator: *mem.Allocator, cups: [9]u32, moves: usize) !usize {
    // I allocate here instead of in the play function to avoid a memory leak.
    // One alternative would be to create an ArrayList in the play function and
    // use list.toOwnedSlice() to pass the ownership back to this function.
    var index = try allocator.alloc(u32, cups.len + 1);
    defer allocator.free(index);
    mem.set(u32, index, 0);

    play(cups, &index, moves);

    var solution: usize = 0;
    var i: usize = 1;
    while (index[i] != 1) {
        solution *= 10;
        solution += index[i];
        i = index[i];
    }
    return solution;
}

/// Perform all moves and update index in place.
fn play(cups: [9]u32, index: *[]u32, moves: usize) void {
    for (cups) |c, i| {
        const i_next = (i + 1) % cups.len;
        index.*[cups[i]] = cups[i_next];
    }

    var curr: u32 = cups[0];

    var i: usize = 0;
    while (i < moves) : (i += 1) {
        const p1 = index.*[curr];
        const p2 = index.*[p1];
        const p3 = index.*[p2];

        index.*[curr] = index.*[p3];

        var dst = if (curr > 1) curr - 1 else cups.len;
        while (dst == p1 or dst == p2 or dst == p3) {
            dst = if (dst > 1) dst - 1 else cups.len;
        }

        var tmp = index.*[dst];
        index.*[dst] = p1;
        index.*[p1] = p2;
        index.*[p2] = p3;
        index.*[p3] = tmp;

        curr = index.*[curr];
    }
}

fn answer2(allocator: *mem.Allocator, cups: [9]u32) !usize {
    const next_cups = try allocator.alloc(Link, 1_000_000);
    defer allocator.free(next_cups);

    for (cups) |c, i| {
        next_cups[c - 1].next = cups[(i + 1) % cups.len];
    }

    if (next_cups.len > cups.len) {
        var i: u32 = cups.len;
        while (i < next_cups.len) : (i += 1) {
            next_cups[i].next = (i + 1) % @intCast(u32, next_cups.len) + 1;
        }

        next_cups[cups[cups.len - 1] - 1].next = cups.len + 1;
        next_cups[next_cups.len - 1].next = cups[0];
    }

    moveFor(10_000_000, cups[0], next_cups);
    const a = next_cups[0].next;
    const b = next_cups[a - 1].next;
    return @as(usize, a) * b;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const input = [_]u32{ 1, 5, 8, 9, 3, 7, 4, 6, 2 };

    const a1 = try answer1(&arena.allocator, input, 100);
    log.info("Part 1: {}", .{a1});
    const a2 = try answer2(&arena.allocator, input);
    log.info("Part 2: {}", .{a2});
}

const testing = std.testing;

test "Day 23, sample 10 moves" {
    const input = [_]u32{ 3, 8, 9, 1, 2, 5, 4, 6, 7 };
    const moves: usize = 10;
    const a = try answer1(testing.allocator, input, moves);
    testing.expectEqual(@intCast(usize, 92658374), a);
}

test "Day 23, sample 100 moves" {
    const input = [_]u32{ 3, 8, 9, 1, 2, 5, 4, 6, 7 };
    const moves: usize = 100;
    const a = try answer1(testing.allocator, input, moves);
    testing.expectEqual(@intCast(usize, 67384529), a);
}

test "Day 23, part 1" {
    const input = [_]u32{ 1, 5, 8, 9, 3, 7, 4, 6, 2 };
    const moves: usize = 100;
    const a = try answer1(testing.allocator, input, moves);
    testing.expectEqual(@intCast(usize, 69473825), a);
}

test "Day 23, part 2" {
    const input = [_]u32{ 3, 8, 9, 1, 2, 5, 4, 6, 7 };
    const a = try answer2(testing.allocator, input);
    testing.expectEqual(@intCast(usize, 149245887792), a);
}
