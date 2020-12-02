const std = @import("std");
const fs = std.fs;
const log = std.log;
const mem = std.mem;

// TODO: do not use this file. Use the utils from 01 and move them to the root directory.

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

pub fn readFileLinesIter(allocator: *mem.Allocator, dir: fs.Dir, sub_path: []const u8) !mem.SplitIterator {
    const slice = try readFile(allocator, dir, sub_path);
    return mem.split(slice, "\n");
}

const testing = std.testing;

test "splitByte" {
    const allocator = testing.allocator;
    const groups = try splitByte(allocator, "Hello\nWorld", '\n'); // split in 2
    defer allocator.free(groups);

    const expected_len: usize = 2;
    testing.expectEqual(expected_len, groups.len);
}
