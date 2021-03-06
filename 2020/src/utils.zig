const std = @import("std");
const fs = std.fs;
const math = std.math;
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
    // where do I free a slice?
    // defer allocator.free(slice);
    return splitByte(allocator, slice, '\n');
}

pub fn readFileLinesIter(allocator: *mem.Allocator, dir: fs.Dir, sub_path: []const u8) !mem.SplitIterator {
    const slice = try readFile(allocator, dir, sub_path);
    var it = mem.split(slice, "\n");
    return it;
}

pub fn range(comptime T: type, allocator: *mem.Allocator, begin: T, end: T, step: T) !std.ArrayList(T) {
    var list = std.ArrayList(T).init(allocator);
    var i = begin;
    while (i < end) : (i += step) {
        try list.append(i);
    }
    return list;
}

/// Concat 2 strings into one.
pub fn concat(allocator: *mem.Allocator, a: []const u8, b: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, a.len + b.len);
    std.mem.copy(u8, result, a);
    std.mem.copy(u8, result[a.len..], b);
    return result;
}

pub const Pos = struct {
    x: isize = 0,
    y: isize = 0,
};

pub const Dir = enum {
    Up,
    Down,
    Left,
    Right,
};

pub fn manhattan(p0: Pos, p1: Pos) usize {
    return math.absCast(p1.x - p0.x) + math.absCast(p1.y - p0.y);
}

/// Check whether string `a` comes before string `b` alphabetically.
/// Useful when sorting strings.
/// std.sort.sort([]const u8, list.items, {}, comptime lessThan);
pub fn lessThan(foo: void, a: []const u8, b: []const u8) bool {
    var min = std.math.min(a.len, b.len);
    var i: usize = 0;
    while (i < min) : (i += 1) {
        // log.debug("a[{}]={} b[{}]={}", .{i, a[i], i, b[i]});
        if (a[i] < b[i]) {
            return true;
        } else if (a[i] > b[i]) {
            return false;
        }
    }
    // a and b match up to the i-th element, so the shortest string wins.
    return a.len < b.len;
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
    const expected: usize = n;
    testing.expectEqual(expected, some_resource.len);
}

test "splitByte" {
    const allocator = testing.allocator;
    const groups = try splitByte(allocator, "Hello\nWorld", '\n'); // split in 2
    defer allocator.free(groups);
    const expected: usize = 2;
    testing.expectEqual(expected, groups.len);
}

test "readFile" {
    const allocator = testing.allocator;
    const slices = try readFile(allocator, fs.cwd(), "src/inputs/01_sample.txt");
    defer allocator.free(slices);
    const expected: usize = 25;
    testing.expectEqual(expected, slices.len);
}

// test "readFileLines (memory leak)" {
//     const allocator = testing.allocator;
//     const slices = try readFileLines(allocator, fs.cwd(), "src/inputs/01_sample.txt");
//     defer allocator.free(slices);
//     const expected: usize = 6;
//     testing.expectEqual(expected, slices.len);
// }

test "read file lines" {
    const allocator = testing.allocator;
    const slice = try readFile(allocator, fs.cwd(), "src/inputs/01_sample.txt");
    defer allocator.free(slice);
    const slices = try splitByte(allocator, slice, '\n');
    defer allocator.free(slices);
    const expected: usize = 6;
    testing.expectEqual(expected, slices.len);
}

test "readFileLinesIter" {
    const allocator = testing.allocator;
    var iter = try readFileLinesIter(allocator, fs.cwd(), "src/inputs/01_sample.txt");
    // readFileLinesIter created a buffer but it cannot free it, otherwise the
    // caller would get a segmentation fault when trying to call iter.next().
    // So it's the caller's responsability (i.e this test) to free the buffer.
    defer allocator.free(iter.buffer);
    // This file has 25 charactes, line feeds included.
    const expected: usize = 25;
    testing.expectEqual(expected, iter.buffer.len);
    const x = iter.next();
    // For zig iter.index might as well be null, since zig cannot know whether
    // the file has a next line or not. But I know that my file has 6 text lines,
    // so I ensure zig that iter.index is indeed not null.
    const idx: u64 = iter.index orelse unreachable;
    testing.expectEqual(@as(u64, 5), idx);
}

test "lessThan" {
    testing.expectEqual(false, lessThan({}, "foo", "bar"));
    testing.expectEqual(true, lessThan({}, "bar", "foo"));
    testing.expectEqual(true, lessThan({}, "bar", "barb"));
    testing.expectEqual(false, lessThan({}, "barb", "bar"));
    testing.expectEqual(false, lessThan({}, "barb", "barb"));
    testing.expectEqual(true, lessThan({}, "barb", "barba"));
}
