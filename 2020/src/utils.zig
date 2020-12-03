const std = @import("std");
const fs = std.fs;
const mem = std.mem;

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

pub fn readFileLinesIter(allocator: *mem.Allocator, dir: fs.Dir, sub_path: []const u8) !mem.SplitIterator {
    const slice = try readFile(allocator, dir, sub_path);
    var it = mem.split(slice, "\n");
    // while (it.next()) |value| {
    //     log.info("value: {}", .{value});
    // }
    return it;
}

// const flags = .{ .read = true };
// const flags = .{ };
// var src_file = try source_dir.openFile("sample0.txt", flags);
// defer src_file.close();

const testing = std.testing;

test "memory allocator reminder how to use free()" {
    const allocator = testing.allocator;
    const n: usize = 10;
    var some_resource = try allocator.alloc([]const u8, n);
    defer allocator.free(some_resource);
    const expected_len: usize = n;
    testing.expectEqual(expected_len, some_resource.len);
}

test "splitByte" {
    const allocator = testing.allocator;
    const groups = try splitByte(allocator, "Hello\nWorld", '\n'); // split in 2
    defer allocator.free(groups);

    const expected_len: usize = 2;
    testing.expectEqual(expected_len, groups.len);
}

// test "readFileLines (memory leak)" {
//     const allocator = testing.allocator;
//     const slices = try readFileLines(allocator, fs.cwd(), "inputs/sample0.txt");
//     defer allocator.free(slices);

//     const expected_len: usize = 6;
//     testing.expectEqual(expected_len, slices.len);
// }

test "read file lines" {
    const allocator = testing.allocator;
    const slice = try readFile(allocator, fs.cwd(), "src/inputs/01_sample.txt");
    defer allocator.free(slice);
    const slices = try splitByte(allocator, slice, '\n');
    defer allocator.free(slices);

    const expected_len: usize = 6;
    testing.expectEqual(expected_len, slices.len);
}

test "readFileLinesIter" {
    const allocator = testing.allocator;
    var iter = try readFileLinesIter(allocator, fs.cwd(), "src/inputs/01_sample.txt");
    // readFileLinesIter created a buffer but it cannot free it, otherwise the
    // caller would get a segmentation fault when trying to call iter.next().
    // So it's the caller's responsability (i.e this test) to free the buffer.
    defer allocator.free(iter.buffer);
    // This file has 25 charactes, line feeds included.
    const expected_len: usize = 25;
    testing.expectEqual(expected_len, iter.buffer.len);
    const x = iter.next();
    // For zig iter.index might as well be null, since zig cannot know whether
    // the file has a next line or not. But I know that my file has 6 text lines,
    // so I ensure zig that iter.index is indeed not null.
    const idx: u64 = iter.index orelse unreachable;
    testing.expectEqual(@as(u64, 5), idx);
}
