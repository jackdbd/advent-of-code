const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/10_minisample.txt");
// const input = @embedFile("inputs/10_sample.txt");
const input = @embedFile("inputs/10.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

fn answer1(allocator: *mem.Allocator) !usize {
    var result: usize = 0;

    var map = std.AutoHashMap(usize, void).init(allocator);
    var list = std.ArrayList(usize).init(allocator);

    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        const n = try fmt.parseInt(usize, line, 10);
        try map.put(n, {});
        try list.append(n);
    }

    // I would have preferred to use only a hash map and sort it, but I still
    // don't know how to do it in zig.
    std.sort.sort(usize, list.items, {}, comptime std.sort.asc(usize));

    var diff_1: usize = 1; // I think this might start from 0 or 1
    var diff_3: usize = 1; // I think this might start from 1 or 2
    for (list.items) |n, i| {
        if (map.get(n + 1) != null) {
            diff_1 += 1;
        } else if (map.get(n + 3) != null) {
            diff_3 += 1;
        }
    }
    result = diff_1 * diff_3;
    // log.debug("diff_1 {}, diff_3 {}", .{diff_1, diff_3});
    return result;
}

fn maxKey(map: std.AutoHashMap(usize, usize)) usize {
    var res: usize = 0;
    var map_it = map.iterator();
    while (map_it.next()) |v| {
        if (v.key > res) res = v.key;
    }
    return res;
}

fn answer2(allocator: *mem.Allocator) !usize {
    var list = std.ArrayList(usize).init(allocator);

    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        const n = try fmt.parseInt(usize, line, 10);
        try list.append(n);
    }
    std.sort.sort(usize, list.items, {}, comptime std.sort.asc(usize));

    var ways = std.AutoHashMap(usize, usize).init(allocator);

    // v's solutions are ((v-1) + (v-2) + (v-3))'s solutions.\
    // E.g. when v=7 we take the sum of solutions from v=6, v=5 and v=4
    try ways.put(0, 1);
    for (list.items) |v| {
        const x = ways.get(v - 1) orelse 0;
        const y = if (v < 2) 0 else ways.get(v - 2) orelse 0;
        const z = if (v < 3) 0 else ways.get(v - 3) orelse 0;
        // log.debug("v: {} == x: {}, y: {}, z: {}, x+y+z: {}", .{ v, x, y, z, x + y + z });
        ways.put(v, (x + y + z)) catch unreachable;
    }
    return ways.get(maxKey(ways)).?;
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
    log.info("Day 10 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 10, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 220), a);
    testing.expectEqual(@intCast(usize, 2760), a);
}

test "Day 10, part 2" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer2(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 19208), a);
    testing.expectEqual(@intCast(usize, 13816758796288), a);
}
