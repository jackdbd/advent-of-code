const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/09_sample.txt");
const input = @embedFile("inputs/09.txt");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const log = std.log;
const math = std.math;
const mem = std.mem;

const Map = std.AutoHashMap(usize, usize); // index, value

fn isValidGivenPreable(haystack: *Map, needle: usize, i_start: usize, preamble: usize) !bool {
    var i = i_start;
    while (i < i_start + preamble - 1) : (i += 1) {
        var j = i + 1;
        while (j < i_start + preamble) : (j += 1) {
            const n1 = haystack.get(i) orelse unreachable;
            const n2 = haystack.get(j) orelse unreachable;
            if ((needle == n1 + n2) and (n1 != n2)) {
                // log.debug("FOUND i: {}, j: {}, n1: {}, n2: {}, needle: {}", .{ i, j, n1, n2, n1 + n2 });
                return true;
            }
        }
    }
    return false;
}

fn answer1(allocator: *mem.Allocator, preamble: usize) !usize {
    var result: usize = 0;
    var map = Map.init(allocator);

    var lines = mem.split(input, "\n");
    var i: usize = 0;
    while (lines.next()) |line| {
        const x = try fmt.parseInt(usize, line, 10);
        try map.put(i, x);
        i += 1;
    }

    i = 0;
    const num_entries = map.count();
    while (i < num_entries - preamble) : (i += 1) {
        const x = map.get(i + preamble) orelse unreachable;
        const is_valid = try isValidGivenPreable(&map, x, i, preamble);
        // log.debug("i: {}, x: {}, is_valid: {}", .{ i, x, is_valid });
        if (!is_valid) {
            return x;
        }
    }
    return result;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a1 = answer1(&arena.allocator, 25); // 5 for sample, 25 for input
    // const a2 = try answer(&arena.allocator, false);
    log.info("Part 1: {}", .{a1});
    // log.info("Part 2: {}", .{a2});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 9 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 09, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const preamble = 25; // 5 for sample, 25 for input
    const a = try answer1(&arena.allocator, preamble);
    // testing.expectEqual(@intCast(usize, 127), a);
    testing.expectEqual(@intCast(usize, 1639024365), a);
}

// test "Day 09, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer(&arena.allocator);
//     // testing.expectEqual(@intCast(u32, 6), a);
//     testing.expectEqual(@intCast(u32, 3356), a);
// }
