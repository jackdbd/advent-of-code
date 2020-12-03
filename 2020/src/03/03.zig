const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

////////////////////////////////////////////////////////////////////////////////

/// Count the units of type `T` needed, if we want to split the single slice
/// `in` into `c` slices, using a separator `b`. Useful for preallocating memory.
/// Similar to std.fmt.count
pub fn count(comptime T: type, in: []const T, b: T) usize {
    var c: usize = 0;
    for (in) |x| {
        // std.debug.print("\nin: {} - x {} - b: {}", .{in, x, b});
        if (x == b) {
            c += 1;
        }
    }
    return c;
}

// Let's say that we expect the input text files to be less than 1MB each.
//https://en.wikipedia.org/wiki/Megabyte
const max_bytes = 1e6;

/// Read an entire file into memory, trimming "line feed" characters at the
/// beginning and at the end.
/// error{FileTooBig}
pub fn readFile(allocator: *mem.Allocator, dir: fs.Dir, sub_path: []const u8) ![]const u8 {
    const slice = try dir.readFileAlloc(allocator, sub_path, max_bytes);
    return mem.trim(u8, slice, "\n");
}

/// Split a buffer `buf` (i.e. a single []const u8 slice) into multiple
/// []const u8 slices, every time a separator `b` is encountered.
///
/// Note: b = '\n' is the line feed character, the "\n" separator.
/// Depending on the Allocator implementation, it may be required to call free
/// once the memory is no longer needed, to avoid a resource leak.
pub fn splitByte(allocator: *mem.Allocator, buf: []const u8, b: u8) ![][]const u8 {
    var sep = [_]u8{b};
    const n = count(u8, buf, b) + 1;
    var slices = try allocator.alloc([]const u8, n);

    var it = mem.split(buf, sep[0..]);
    for (slices) |_, i| {
        slices[i] = it.next() orelse unreachable;
        // std.debug.print("\ni: {} slices[i]: {}", .{i, slices[i]});
    }
    return slices;
}

pub fn readFileLines(allocator: *mem.Allocator, dir: fs.Dir, sub_path: []const u8) ![][]const u8 {
    const slice = try readFile(allocator, dir, sub_path);
    // TODO: we cannot call free here, otherwise we get a segmentation fault in
    // the program. But if we don't free slice we have a memory leak. How and
    // where do I free slice?
    // defer allocator.free(slice);
    return splitByte(allocator, slice, '\n');
}

////////////////////////////////////////////////////////////////////////////////

fn answer1(allocator: *mem.Allocator, dir: fs.Dir, sub_path: []const u8) !i32 {
    var result: i32 = 0;

    const slice = try readFile(allocator, dir, sub_path);
    defer allocator.free(slice);
    const lines = try splitByte(allocator, slice, '\n');
    defer allocator.free(lines);

    var i_col:u32 = 0;
    for (lines[0..]) |line, i| {
        const i_row = i + 1;
        i_col += 3;
        if (i_row == lines.len) {
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
        // log.debug("lines[i_row]: {}, i_col: {}, len: {}, idx: {}, lines[i_row][idx]: {}", .{lines[i_row], i_col, lines[i_row].len, idx, lines[i_row][idx]});
        if (lines[i_row][idx] == 35) {
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
    const a = try answer1(&arena.allocator, fs.cwd(), "part1.txt");
    log.info("Answer: {}", .{a});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Program took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "part 1" {
    const a = try answer1(testing.allocator, fs.cwd(), "sample1.txt");
    testing.expectEqual(@as(i32, 7), a);
}

// test "part 2" {
//     const a = try answer2(testing.allocator, fs.cwd(), "sample1.txt");
//     testing.expectEqual(@as(i32, 1), a);
// }
