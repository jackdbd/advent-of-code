const std = @import("std");
const utils = @import("utils.zig");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

fn answer1(allocator: *mem.Allocator, dir: fs.Dir, sub_path: []const u8) !i32 {
    var result: i32 = 0;
    var iter = try utils.readFileLinesIter(allocator, dir, sub_path);
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

        var n:i32 = 0;
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

fn answer2(allocator: *mem.Allocator, dir: fs.Dir, sub_path: []const u8) !i32 {
    var result: i32 = 0;
    var iter = try utils.readFileLinesIter(allocator, dir, sub_path);
    // defer allocator.free(iter.buffer);

    while (iter.next()) |line| {
        const groups = try utils.splitByte(allocator, line, ' ');
        // defer allocator.free(groups);
        const digits = try utils.splitByte(allocator, groups[0], '-');
        // defer allocator.free(digits);
        var idx0 = try fmt.parseInt(i32, digits[0], 10);
        idx0 -= 1;
        var idx1 = try fmt.parseInt(i32, digits[1], 10);
        idx1 -=1;
        const char = try utils.splitByte(allocator, groups[1], ':');
        // defer allocator.free(char);
        const password = groups[2];

        // log.debug("line: {} (idx0: {}, idx1: {}, char: {}, password: {})", .{line, idx0, idx1, char[0], password});

        var matches:i32 = 0;
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

    // const a = try answer1(&arena.allocator, fs.cwd(), "sample1.txt");
    // const a = try answer1(&arena.allocator, fs.cwd(), "part1.txt");
    const a = try answer2(&arena.allocator, fs.cwd(), "part1.txt");
    log.info("Answer: {}", .{a});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Program took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "part 1" {
    const a = try answer1(testing.allocator, fs.cwd(), "sample1.txt");
    testing.expectEqual(@as(i32, 2), a);
}

test "part 2" {
    const a = try answer2(testing.allocator, fs.cwd(), "sample1.txt");
    testing.expectEqual(@as(i32, 1), a);
}
