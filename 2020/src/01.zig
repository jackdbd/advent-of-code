const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/01_sample.txt");
const input = @embedFile("inputs/01.txt");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

fn answer1(allocator: *mem.Allocator) !i32 {
    const lines = try utils.splitByte(allocator, input, '\n');
    defer allocator.free(lines);

    var result: i32 = 0;
    outer: for (lines[0..]) |l0, i| {
        for (lines[1..]) |l1, j| {
            // log.debug("l0: {}, l1: {}", .{ l0, l1 });
            const n0 = try fmt.parseInt(i32, l0, 10);
            const n1 = try fmt.parseInt(i32, l1, 10);
            if (n0 + n1 == 2020) {
                // log.debug("n0: {}, n1: {}, i: {}, j: {}", .{ n0, n1, i, j });
                result = n0 * n1;
                break :outer;
            }
        }
    }
    return result;
}

fn answer2(allocator: *mem.Allocator) !i32 {
    const lines = try utils.splitByte(allocator, input, '\n');
    defer allocator.free(lines);

    var result: i32 = 0;
    outer: for (lines[0..]) |l0, i| {
        for (lines[1..]) |l1, j| {
            for (lines[2..]) |l2, k| {
                // log.debug("l0: {}, l1: {}", .{ l0, l1 });
                const n0 = try fmt.parseInt(i32, l0, 10);
                const n1 = try fmt.parseInt(i32, l1, 10);
                const n2 = try fmt.parseInt(i32, l2, 10);
                if (n0 + n1 + n2 == 2020) {
                    // log.debug("n0: {}, n1: {}, n2: {}, i: {}, j: {} k: {}", .{ n0, n1, n2, i, j, k });
                    result = n0 * n1 * n2;
                    break :outer;
                }
            }
        }
    }
    return result;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    // var gpa = heap.GeneralPurposeAllocator(.{}){};
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a1 = try answer1(&arena.allocator);
    const a2 = try answer2(&arena.allocator);
    log.info("Part 1: {}", .{a1});
    log.info("Part 2: {}", .{a2});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 1 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 01, part 1" {
    const a = try answer1(testing.allocator);
    // testing.expectEqual(@as(i32, 514579), a);
    testing.expectEqual(@as(i32, 805731), a);
}

test "Day 01, part 2" {
    const a = try answer2(testing.allocator);
    // testing.expectEqual(@as(i32, 241861950), a);
    testing.expectEqual(@as(i32, 192684960), a);
}
