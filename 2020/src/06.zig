const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/06_sample.txt");
const input = @embedFile("inputs/06.txt");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const log = std.log;
const math = std.math;
const mem = std.mem;

fn answer1(allocator: *mem.Allocator) !u32 {
    var result: u32 = 0;

    var groups = mem.split(input, "\n\n");
    while (groups.next()) |string| {
        var map = std.AutoHashMap(u8, u32).init(allocator);
        // log.debug("GROUP", .{});
        var persons = mem.split(string, "\n");
        while (persons.next()) |answers| {
            // log.debug("answers: {}", .{answers});
            for (answers) |a, i| {
                const n = map.get(a);
                if (n == null) {
                    try map.put(a, 1);
                } else {
                    try map.put(a, n.? + 1);
                }
            }
        }
        result += map.count();
    }
    return result;
}

// fn answer2(allocator: *mem.Allocator) !u32 {
// }

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a1 = answer1(&arena.allocator);
    // const a2 = try answer2(&arena.allocator);
    log.info("Part 1: {}", .{a1});
    // log.info("Part 2: {}", .{a2});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 6 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 06, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = answer1(&arena.allocator);
    testing.expectEqual(@intCast(u32, 11), a);
    // testing.expectEqual(@intCast(u32, 6775), a);
}

// test "Day 06, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     testing.expectEqual(@intCast(u32, 629), a);
// }
