const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/08_sample.txt");
const input = @embedFile("inputs/08.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

const Instruction = struct {
    instr: []const u8,
    sign: []const u8,
    operand: []const u8,
};

fn answer1(allocator: *mem.Allocator) !i32 {
    var instructions = std.ArrayList(Instruction).init(allocator);
    defer instructions.deinit();

    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        const instr = line[0..3];
        const sign = line[4..5];
        const operand = line[5..];
        // log.debug("inst: {}, sign: {}, operand: {}", .{ instr, sign, operand });
        try instructions.append(Instruction{ .instr = instr, .sign = sign, .operand = operand });
    }

    var map = std.AutoHashMap(usize, bool).init(allocator);
    defer map.deinit();

    var idx: usize = 0;
    var count: i32 = 0;

    while (true) {
        const item = instructions.items[idx];
        const found = map.get(idx);
        if (found != null) {
            // break;
            return count;
        } else {
            try map.put(idx, true);
        }

        if (mem.eql(u8, item.instr, "nop")) {
            idx += 1;
            // log.debug("NOP i: {} count: {}", .{ idx, count });
            continue;
        } else if (mem.eql(u8, item.instr, "acc")) {
            idx += 1;
            const n = try fmt.parseInt(i32, item.operand, 10);
            count = if (mem.eql(u8, item.sign, "+")) count + n else (count - n);
            // log.debug("ACC i: {} count: {}", .{ idx, count });
            continue;
        } else {
            const n = try fmt.parseInt(i32, item.operand, 10);
            idx = if (mem.eql(u8, item.sign, "+")) @intCast(usize, @intCast(i32, idx) + n) else @intCast(usize, @intCast(i32, idx) - n);
            // log.debug("JMP i: {} count: {}", .{ idx, count });
            continue;
        }
    }
}

fn answer2(allocator: *mem.Allocator) !u32 {
    var result: u32 = 0;
    return result;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a1 = answer1(&arena.allocator);
    const a2 = try answer2(&arena.allocator);
    log.info("Part 1: {}", .{a1});
    log.info("Part 2: {}", .{a2});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 8 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 08, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@intCast(i32, 5), a);
    testing.expectEqual(@intCast(u32, 1859), a);
}

// test "Day 08, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     // testing.expectEqual(@intCast(u32, 123), a);
//     testing.expectEqual(@intCast(u32, 123), a);
// }
