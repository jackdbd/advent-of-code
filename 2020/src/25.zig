const std = @import("std");
const input = @embedFile("inputs/25.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

fn transform(value: usize, subject: usize) usize {
    return @rem(value * subject, 20201227);
}

fn loop(subject: usize, loop_size: usize) usize {
    var pubkey: usize = 1;
    var i: usize = 0;
    while (i < loop_size) : (i += 1) {
        pubkey = transform(pubkey, subject);
    }
    return pubkey;
}

fn findLoopSize(subject: usize, pubkey: usize) usize {
    var i: usize = 0;
    var value: usize = 1;
    while (value != pubkey) : (i += 1) {
        value = transform(value, subject);
    }
    return i;
}

fn answer1(allocator: *mem.Allocator) !usize {
    var lines = mem.split(input, "\n");
    const card_pubkey = try fmt.parseInt(usize, lines.next().?, 10);
    const door_pubkey = try fmt.parseInt(usize, lines.next().?, 10);
    const subject_number = 7;

    const card_loop = findLoopSize(subject_number, card_pubkey);
    const door_loop = findLoopSize(subject_number, door_pubkey);

    const encryption_key = loop(door_pubkey, card_loop);
    std.debug.assert(encryption_key == loop(card_pubkey, door_loop));
    return encryption_key;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a = try answer1(&arena.allocator);
    log.info("Part 1 (there is no part 2): {}", .{a});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 25 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "encryption key" {
    const subject_number = 7;
    const card_public_key = loop(subject_number, 8);
    testing.expectEqual(@intCast(usize, 5764801), card_public_key);

    const door_public_key = loop(subject_number, 11);
    testing.expectEqual(@intCast(usize, 17807724), door_public_key);

    testing.expectEqual(loop(door_public_key, 8), loop(card_public_key, 11));
}

test "Day 25" {
    const a = try answer1(testing.allocator);
    testing.expectEqual(@intCast(usize, 19414467), a);
}
