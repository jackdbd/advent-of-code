const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/18_sample.txt");
const input = @embedFile("inputs/18.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

const Op = enum { sum, prod };

/// Compute a math expression that has no parentheses.
fn solve(allocator: *mem.Allocator, expr: []const u8) fmt.ParseIntError!usize {
    std.debug.assert(mem.lastIndexOf(u8, expr, "(") == null);
    std.debug.assert(mem.lastIndexOf(u8, expr, ")") == null);
    // log.debug("solve {}", .{expr});
    var it = mem.tokenize(expr, " +*");
    var i: usize = 0;
    var res: usize = 0;
    var op: Op = Op.sum;
    while (i < expr.len) : (i += 1) {
        switch (expr[i]) {
            '+' => op = Op.sum,
            '*' => op = Op.prod,
            ' ' => {},
            else => {
                const n = try fmt.parseInt(usize, it.next().?, 10);
                res = if (op == Op.sum) res + n else res * n;
                i = it.index;
            },
        }
    }
    return res;
}

// TODO: find out how to use ParseIntError, not Overflow and InvalidCharacter
// ParseIntError = union of Overflow and InvalidCharacter
const MyError = error{
    // ParseIntError
    InvalidCharacter,
    Overflow,

    // AllocPrintError
    OutOfMemory,
};

/// Recursively simplify a math expression, solving operations between parentheses.
fn simplifyAndSolve(allocator: *mem.Allocator, expr: []const u8) MyError!usize {
    const i = mem.lastIndexOf(u8, expr, "(");
    if (i == null) {
        return try solve(allocator, expr);
    } else {
        var i_start = i.?;
        var i_stop = expr.len - 1;
        var idx: ?usize = expr.len - 1;
        while (idx != null) {
            idx = mem.lastIndexOf(u8, expr[i_start..i_stop], ")");
            i_stop = if (idx == null) i_stop else i_start + idx.?;
        }
        const pre = expr[0..i_start];
        const n = try solve(allocator, expr[i_start + 1 .. i_stop]);
        const post = expr[i_stop + 1 ..];
        const next_expr = try fmt.allocPrint(allocator, "{}{}{}", .{ pre, n, post });
        // log.debug("next_expr {}", .{next_expr});
        return try simplifyAndSolve(allocator, next_expr);
    }
}

fn answer1(allocator: *mem.Allocator) !usize {
    var sum: usize = 0;
    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        sum += try simplifyAndSolve(allocator, line);
    }
    return sum;
}

fn answer2(allocator: *mem.Allocator) !usize {
    var result: usize = 0;
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
    log.info("Day 18 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 18, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 26406), a);
    testing.expectEqual(@intCast(usize, 12956356593940), a);
}

// test "Day 18, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     testing.expectEqual(@intCast(i32, 8), a);
//     // testing.expectEqual(@intCast(i32, 1235), a);
// }
