const std = @import("std");
const utils = @import("utils.zig");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

fn answer(allocator: *mem.Allocator, dir: fs.Dir, sub_path: []const u8) !i32 {
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

pub fn main() !void {
    // var gpa = heap.GeneralPurposeAllocator(.{}){};
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a = try answer(&arena.allocator, fs.cwd(), "inputs/part1.txt");
    // const a = try answer(&arena.allocator, fs.cwd(), "inputs/sample1.txt");
    log.info("Answer: {}", .{a});
}

const testing = std.testing;

test "sample0.txt" {
    const a = try answer(testing.allocator, fs.cwd(), "inputs/sample1.txt");
    testing.expectEqual(a, 514579);
}
