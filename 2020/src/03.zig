const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/03_sample.txt");
const input = @embedFile("inputs/03.txt");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const log = std.log;
const mem = std.mem;


fn answer1(allocator: *mem.Allocator, right_inc: u8, down_inc: u8) !i32 {
    var result: i32 = 0;
    const lines = try utils.splitByte(allocator, input, '\n');
    defer allocator.free(lines);

    var i_col:u32 = 0;
    var i:u32 = 0;
    while (i < lines.len) : (i += down_inc) {
        const i_row = i + down_inc;

        i_col += right_inc;
        if (i_row >= lines.len) {
            break;
        }

        // Each input line has a pattern made of . (ASCII 46) and X (ASCII 35)
        // Since i_col might exceed a line's length, we compute a new index idx
        // instead of explicitly repeating the pattern.
        var idx:usize = 0;
        const len = lines[i_row].len;
        if (i_col < len) {
            idx = i_col;
        } else {
            idx = i_col;
            while(idx >= len) {
                idx = idx - len;
            }
        }
        // How does std.fmt.digitToChar works?
        // log.debug("i_row: {}, i_col: {}, idx: {}, lines[{}]: {}, lines[{}][{}]: {}", .{i_row, i_col, idx, i_row, lines[i_row], i_row, idx, lines[i_row][idx]});
        if (lines[i_row][idx] == 35) {
            result += 1;
        }
    }
    return result;
}

fn answer2(allocator: *mem.Allocator) !i32 {
    const a11 = try answer1(allocator, 1, 1);
    const a31 = try answer1(allocator, 3, 1);
    const a51 = try answer1(allocator, 5, 1);
    const a71 = try answer1(allocator, 7, 1);
    const a12 = try answer1(allocator, 1, 2);
    return a11 * a31 * a51 * a71 * a12;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();
    
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a1 = try answer1(&arena.allocator, 3, 1);
    const a2 = try answer2(&arena.allocator);
    log.info("Part 1: {}", .{a1});
    log.info("Part 2: {}", .{a2});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 3 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 03, part 1" {
    const a = try answer1(testing.allocator, 3, 1);
    // testing.expectEqual(@as(i32, 7), a);
    testing.expectEqual(@as(i32, 257), a);
}

test "Day 03, part 2" {
    const a = try answer2(testing.allocator);
    // testing.expectEqual(@as(i32, 336), a);
    testing.expectEqual(@as(i32, 1744787392), a);
}
