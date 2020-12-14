const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/14_sample.txt");
const input = @embedFile("inputs/14.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

const Instruction = struct {
    address: usize,
    value: usize,
};

fn parseInstruction(address_s: []const u8, value_s: []const u8) std.fmt.ParseIntError!Instruction {
    const address = try fmt.parseInt(usize, address_s, 10);
    const value = try fmt.parseInt(usize, value_s, 10);
    return Instruction{ .address = address, .value = value };
}

fn toBinary(out_stream: anytype, value: usize) ![36]u8 {
    std.debug.assert(out_stream.context.buffer.len == 36);
    try std.fmt.format(out_stream, "{b:0>36}", .{value});
    const bits: [36]u8 = out_stream.context.buffer[0..36].*;
    out_stream.context.pos = 0;
    return bits;
}

fn toDecimal(bits: [36]u8) !usize {
    // log.debug("toDecimal {}", .{bits});
    var value: usize = 0;
    var i: usize = bits.len;
    // i=36 -> n=0 -> bits[0]=LSB
    // i=1 -> n=35 -> bits[35]=MSB
    while (i > 0) : (i -= 1) {
        const n = bits.len - i;
        const bit: u8 = if (bits[i - 1] == 48) 0 else 1;
        // log.debug("i {} bits[{}]={}", .{ i, n, bit });
        if (bit == 1) value += std.math.pow(usize, 2, n);
    }
    return value;
}

const Mask = struct {
    map: std.AutoHashMap(usize, u8),

    const Self = @This();

    fn init(allocator: *mem.Allocator) Self {
        return Self{ .map = std.AutoHashMap(usize, u8).init(allocator) };
    }

    fn update(self: *Self, bits: []const u8) !void {
        // log.debug("MASK      {}", .{bits});
        for (bits) |bit, i| {
            // const idx = bits.len - i - 1;
            switch (bit) {
                48 => try self.map.put(i, 48), // "0"
                49 => try self.map.put(i, 49), // "1"
                else => try self.map.put(i, 88), // "X" means don't care
            }
        }
    }

    fn apply(self: *Self, bits: [36]u8) [36]u8 {
        std.debug.assert(bits.len == 36);
        var updated_bits = bits;
        var it = self.map.iterator();
        while (it.next()) |e| {
            const i = e.key;
            if (e.value == 48) {
                updated_bits[i] = 48;
            } else if (e.value == 49) {
                updated_bits[i] = 49;
            }
        }
        std.debug.assert(updated_bits.len == 36);
        return updated_bits;
    }

    // index 0 = MSB; index 35 = LSB
    fn print(self: *Self) void {
        var it = self.map.iterator();
        while (it.next()) |e| {
            log.debug("bit {} at index {}", .{ e.value, e.key });
        }
    }
};

fn answer1(allocator: *mem.Allocator) !usize {
    var buf: [36]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const out_stream = fbs.writer();

    var mask = Mask.init(allocator);
    var memory_map = std.AutoHashMap(usize, usize).init(allocator);
    // var list = std.ArrayList([36]u8).init(allocator);
    var sum_in_memory: usize = 0;

    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        // log.debug("line: {}", .{line});
        var it = mem.tokenize(line, "[] =");
        if (mem.eql(u8, "mask", it.next().?)) {
            try mask.update(it.next().?);
        } else {
            const instr = try parseInstruction(it.next().?, it.next().?);
            const bits_pre = try toBinary(out_stream, instr.value);
            // log.debug("bits_pre  {} ({})", .{bits_pre, instr.value});
            const bits_post = mask.apply(bits_pre);
            const value = try toDecimal(bits_post);
            // log.debug("bits_post {} ({})", .{bits_post, value});
            // log.debug("write {} at mem[{}]", .{ value, instr.address });
            try memory_map.put(instr.address, value);
        }
    }

    var memory_it = memory_map.iterator();
    // log.debug("{} memory addresses contain values", .{ memory_map.count() });
    while (memory_it.next()) |e| {
        // log.info("mem[{}]={}", .{ e.key, e.value });
        sum_in_memory += e.value;
    }
    return sum_in_memory;
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
    log.info("Day 14 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 14, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 165), a);
    testing.expectEqual(@intCast(usize, 11926135976176), a);
}

// test "Day 14, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     // testing.expectEqual(@intCast(i32, 8), a);
//     testing.expectEqual(@intCast(i32, 1235), a);
// }
