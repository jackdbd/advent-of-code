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

fn answer(allocator: *mem.Allocator, is_part_one: bool) !u32 {
    var result: u32 = 0;
    var groups = mem.split(input, "\n\n");
    while (groups.next()) |string| {
        var map = std.AutoHashMap(u8, u32).init(allocator);
        // log.debug("GROUP", .{});
        var n_persons: u32 = 0;
        var persons = mem.split(string, "\n");
        while (persons.next()) |answers| {
            n_persons += 1;
            for (answers) |a, i| {
                const n = map.get(a);
                if (n == null) {
                    try map.put(a, 1);
                } else {
                    try map.put(a, n.? + 1);
                }
            }
        }

        if (is_part_one) {
            result += map.count();
        } else {
            var it = map.iterator();
            while (it.next()) |entry| {
                if (entry.value == n_persons) {
                    result += 1;
                }
            }
        }
    }
    return result;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a1 = answer(&arena.allocator, true);
    const a2 = try answer(&arena.allocator, false);
    log.info("Part 1: {}", .{a1});
    log.info("Part 2: {}", .{a2});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 6 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 06, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer(&arena.allocator, true);
    // testing.expectEqual(@intCast(u32, 11), a);
    testing.expectEqual(@intCast(u32, 6775), a);
}

test "Day 06, part 2" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer(&arena.allocator, false);
    // testing.expectEqual(@intCast(u32, 6), a);
    testing.expectEqual(@intCast(u32, 3356), a);
}
