const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/02_sample.txt");
const input = @embedFile("inputs/02.txt");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

fn answer1(allocator: *mem.Allocator) !i32 {
    var result: i32 = 0;
    var iter = mem.split(input, "\n");
    while (iter.next()) |line| {
        const groups = try utils.splitByte(allocator, line, ' ');
        const digits = try utils.splitByte(allocator, groups[0], '-');
        const min = try fmt.parseInt(i32, digits[0], 10);
        const max = try fmt.parseInt(i32, digits[1], 10);
        const char = try utils.splitByte(allocator, groups[1], ':');
        const password = groups[2];

        // log.debug("line: {} (min: {}, max: {}, char: {}, password: {})", .{line, min, max, char[0], password});

        // log.info("char: {} {}", .{char[0].len, @typeInfo(@TypeOf(char))});
        // log.info("password: {} {}", .{password.len, @typeInfo(@TypeOf(password[0]))});

        var n: i32 = 0;
        for (password) |p, i| {
            if (p == char[0][0]) {
                n += 1;
            }
        }
        // log.info("p: {} i: {}, eql: {}", .{p, i, p == char[0][0]});

        // log.info("char: {}, charToDigit: {}", .{char[0][0], fmt.charToDigit(char[0][0], 10)});
        // log.info("char: {}, digitToChar: {}", .{char[0][0], fmt.digitToChar(99, true)});

        if (min <= n and n <= max) {
            // log.info("Done: {}", .{n.len});
            result += 1;
        }
    }
    return result;
}

fn answer2(allocator: *mem.Allocator) !i32 {
    var result: i32 = 0;
    var iter = mem.split(input, "\n");
    // defer allocator.free(iter.buffer);

    while (iter.next()) |line| {
        const groups = try utils.splitByte(allocator, line, ' ');
        // defer allocator.free(groups);
        const digits = try utils.splitByte(allocator, groups[0], '-');
        // defer allocator.free(digits);
        var idx0 = try fmt.parseInt(i32, digits[0], 10);
        idx0 -= 1;
        var idx1 = try fmt.parseInt(i32, digits[1], 10);
        idx1 -= 1;
        const char = try utils.splitByte(allocator, groups[1], ':');
        // defer allocator.free(char);
        const password = groups[2];

        // log.debug("line: {} (idx0: {}, idx1: {}, char: {}, password: {})", .{line, idx0, idx1, char[0], password});

        var matches: i32 = 0;
        for (password) |p, i| {
            if (i == idx0 or i == idx1) {
                if (p == char[0][0]) {
                    // log.info("p: {} i: {}, idx0: {}, idx1: {}", .{p, i, idx0, idx1});
                    matches += 1;
                }
            }
        }
        const valid = if (matches == 1) true else false;
        if (valid) {
            result += 1;
        }
    }
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
    log.info("Day 2 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 02, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    // TODO: memory leaks when running the testing allocator!
    // const a = try answer1(testing.allocator);
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@as(i32, 2), a);
    testing.expectEqual(@as(i32, 378), a);
}

test "Day 02, part 2" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer2(&arena.allocator);
    // testing.expectEqual(@as(i32, 1), a);
    testing.expectEqual(@as(i32, 280), a);
}
