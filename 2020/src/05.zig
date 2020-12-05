const std = @import("std");
const utils = @import("utils.zig");
const input = @embedFile("inputs/05_sample.txt");
// const input = @embedFile("inputs/05.txt");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const log = std.log;
const math = std.math;
const mem = std.mem;

fn binary_space_partition(slice: []const u8) u32 {
    var low: u32 = 0;
    var high: u32 = math.pow(u32, 2, @intCast(u32, slice.len)) - 1;
    var cursor = high + 1;
    var i: u8 = 0;
    while (cursor > 1) : ({
        i += 1;
    }) {
        cursor /= 2;
        // L=left, F=front (else is for R=right and B=back)
        if (slice[i] == 'L' or slice[i] == 'F') {
            high -= cursor;
        } else {
            low += cursor;
        }
        // log.debug("low: {}, high: {}, cursor: {}, i: {}", .{ low, high, cursor, i });
    }
    if (slice[i - 1] == 'L' or slice[i - 1] == 'F') {
        return low;
    } else {
        return high;
    }
}

fn answer1(allocator: *mem.Allocator) u32 {
    var result: u32 = 0;
    var it = std.mem.split(input, "\n");
    while (it.next()) |string| {
        const rows = string[0..7];
        const columns = string[7..];
        const seat_row = binary_space_partition(rows);
        const seat_column = binary_space_partition(columns);
        const seat_id: u32 = seat_row * 8 + seat_column;
        // log.debug("string: {}, rows: {}, columns: {}, seat_row: {}, seat_column: {}, seat_id: {}", .{ string, rows, columns, seat_row, seat_column, seat_id });
        if (seat_id > result) {
            result = seat_id;
        }
    }
    return result;
}

fn answer2(allocator: *mem.Allocator) u32 {
    var result: u32 = 0;
    return result;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a1 = answer1(&arena.allocator);
    const a2 = answer2(&arena.allocator);
    log.info("Part 1: {}", .{a1});
    log.info("Part 2: {}", .{a2});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 5 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 05, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = answer1(&arena.allocator);
    testing.expectEqual(@intCast(u32, 820), a);
    // testing.expectEqual(@intCast(u32, 911), a);
}

test "Day 05, part 2" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = answer2(&arena.allocator);
    testing.expectEqual(@intCast(u32, 911), a);
    // testing.expectEqual(@intCast(u32, 911), a);
}
