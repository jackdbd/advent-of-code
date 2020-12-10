const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/10_sample.txt");
const input = @embedFile("inputs/10.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

fn lessThan(_: void, a: usize, b: usize) bool {
    return a < b;
}

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
    std.sort.sort(usize, list.items, {}, lessThan);

    var diff_1: usize = 1;
    var diff_3: usize = 1;
    for (list.items) |n, i| {
        if (map.get(n + 1) != null) {
            diff_1 += 1;
        } else if (map.get(n + 3) != null) {
            diff_3 += 1;
        }
    }
    result = diff_1 * diff_3;
    return result;
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

// test "Day 10, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     // testing.expectEqual(@intCast(i32, 8), a);
//     testing.expectEqual(@intCast(i32, 1235), a);
// }
