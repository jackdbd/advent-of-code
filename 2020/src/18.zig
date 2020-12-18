const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/18_sample.txt");
// const input = @embedFile("inputs/18_sample2.txt");
const input = @embedFile("inputs/18.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

const Op = enum { sum, prod }; // not really necessary but I wanted to try out enums :)

/// Compute a math expression that has no parentheses and no operator precedence.
fn solve(expr: []const u8) fmt.ParseIntError!usize {
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

/// Compute a math expression that has no parentheses, but where the + operator
/// has precedence over the * operator.
fn solvePart2(allocator: *mem.Allocator, expr: []const u8) MyError!usize {
    std.debug.assert(mem.lastIndexOf(u8, expr, "(") == null);
    std.debug.assert(mem.lastIndexOf(u8, expr, ")") == null);

    var i_prod = mem.lastIndexOf(u8, expr, "*");
    if (i_prod == null) {
        return solve(expr);
    }

    var i_sum = mem.lastIndexOf(u8, expr, "+");
    if (i_sum == null) {
        return solve(expr);
    }

    const i_rl = mem.lastIndexOf(u8, expr[0..i_sum.?], "*"); // relative index
    const i_left = if (i_rl == null) 0 else i_rl.? + 2;
    const i_rr = mem.indexOf(u8, expr[i_sum.?..], "*"); // relative index
    const i_right = if (i_rr == null) expr.len else i_sum.? + i_rr.? - 1;

    const left = expr[0..i_left];
    const n = solve(expr[i_left..i_right]);
    const right = expr[i_right..];
    const next_expr = try fmt.allocPrint(allocator, "{}{}{}", .{ left, n, right });
    return solvePart2(allocator, next_expr);
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
fn simplifyAndSolve(allocator: *mem.Allocator, is_part_1: bool, expr: []const u8) MyError!usize {
    const i = mem.lastIndexOf(u8, expr, "(");
    if (i == null) {
        if (is_part_1) {
            return try solve(expr);
        } else {
            return try solvePart2(allocator, expr);
        }
    } else {
        var i_start = i.?;
        var i_stop = expr.len - 1;
        var idx: ?usize = expr.len - 1;
        while (idx != null) {
            idx = mem.lastIndexOf(u8, expr[i_start..i_stop], ")");
            i_stop = if (idx == null) i_stop else i_start + idx.?;
        }
        const left = expr[0..i_start];
        var n: usize = undefined;
        if (is_part_1) {
            n = try solve(expr[i_start + 1 .. i_stop]);
        } else {
            n = try solvePart2(allocator, expr[i_start + 1 .. i_stop]);
        }
        const right = expr[i_stop + 1 ..];
        const next_expr = try fmt.allocPrint(allocator, "{}{}{}", .{ left, n, right });
        // log.debug("next_expr {}", .{next_expr});
        return try simplifyAndSolve(allocator, is_part_1, next_expr);
    }
}

fn answer1(allocator: *mem.Allocator) !usize {
    var sum: usize = 0;
    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        sum += try simplifyAndSolve(allocator, true, line);
    }
    return sum;
}

fn answer2(allocator: *mem.Allocator) !usize {
    var sum: usize = 0;
    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        sum += try simplifyAndSolve(allocator, false, line);
    }
    return sum;
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

test "Day 18, part 2" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer2(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 694173), a);
    testing.expectEqual(@intCast(usize, 94240043727614), a);
}
