const std = @import("std");
const utils = @import("utils.zig");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

fn answer1(allocator: *mem.Allocator, dir: fs.Dir, sub_path: []const u8) !i32 {
    // const lines = try utils.readFileLines(allocator, dir, sub_path); // memory leak (it doesn't free slice)
    const slice = try utils.readFile(allocator, dir, sub_path);
    defer allocator.free(slice);
    const lines = try utils.splitByte(allocator, slice, '\n');
    defer allocator.free(lines);

    var result: i32 = 0;
    outer: for (lines[0..]) |l0, i| {
        for (lines[1..]) |l1, j| {
            // log.debug("l0: {}, l1: {}", .{ l0, l1 });
            const n0 = try fmt.parseInt(i32, l0, 10);
            const n1 = try fmt.parseInt(i32, l1, 10);
            if (n0 + n1 == 2020) {
                log.debug("n0: {}, n1: {}, i: {}, j: {}", .{ n0, n1, i, j });
                result = n0 * n1;
                break :outer;
            } 
        }
    }
    return result;
}

fn answer2(allocator: *mem.Allocator, dir: fs.Dir, sub_path: []const u8) !i32 {
    const slice = try utils.readFile(allocator, dir, sub_path);
    defer allocator.free(slice);
    const lines = try utils.splitByte(allocator, slice, '\n');
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
                log.debug("n0: {}, n1: {}, n2: {}, i: {}, j: {} k: {}", .{ n0, n1, n2, i, j, k });
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

    // const a = try answer1(&arena.allocator, fs.cwd(), "inputs/sample1.txt");
    // const a = try answer1(&arena.allocator, fs.cwd(), "inputs/part1.txt");
    // const a = try answer2(&arena.allocator, fs.cwd(), "inputs/sample1.txt");
    const a = try answer2(&arena.allocator, fs.cwd(), "inputs/part2.txt");
    log.info("Answer: {}", .{a});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Program took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "part 1" {
    const a = try answer1(testing.allocator, fs.cwd(), "inputs/sample1.txt");
    testing.expectEqual(a, 514579);
}

test "part 2" {
    const a = try answer2(testing.allocator, fs.cwd(), "inputs/sample1.txt");
    testing.expectEqual(a, 241861950);
}
