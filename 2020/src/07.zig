const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/07_sample.txt");
const input = @embedFile("inputs/07.txt");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const log = std.log;
const math = std.math;
const mem = std.mem;

const Bag = struct {
    bag_type: []const u8,
    quantity: u32,
};

fn checkGoldBag(map: std.StringHashMap(std.ArrayList([]u8)), kv: std.ArrayList([]u8), parent: []const u8) bool {
    for (kv.items) |kvv| {
        if (std.mem.eql(u8, kvv, "shinygold")) {
            return true;
        }
        var t = map.get(kvv).?;
        if (checkGoldBag(map, t, kvv)) {
            return true;
        }
    }
    return false;
}

fn answer1(allocator: *mem.Allocator) !u32 {
    var result: u32 = 0;

    var map = std.StringHashMap(std.ArrayList([]u8)).init(allocator);
    defer map.deinit();

    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        var words = mem.split(line, " ");
        var parentBag = try utils.concat(allocator, words.next().?, words.next().?);
        _ = words.next();
        _ = words.next();

        var list = std.ArrayList([]u8).init(allocator);

        const number_or_no = words.next().?; // a number or "no"
        if (!mem.eql(u8, number_or_no, "no")) {
            while (words.next()) |w| {
                if (!(mem.eql(u8, w[0 .. w.len - 1], "bags") or mem.eql(u8, w[0 .. w.len - 1], "bag"))) {
                    var childBag = try utils.concat(allocator, w, words.next().?);
                    try list.append(childBag);
                } else {
                    _ = words.next();
                }
            }
        }
        try map.put(parentBag, list);
    }

    var it = map.iterator();
    while (it.next()) |entry| {
        if (checkGoldBag(map, entry.value, entry.key)) {
            result += 1;
        }
    }
    return result;
}

fn countGoldBag(map: std.StringHashMap(std.ArrayList(Bag)), parent: []const u8) u32 {
    var items = map.get(parent).?;
    var count: u32 = 0;
    for (items.items) |i| {
        count += i.quantity + (i.quantity * countGoldBag(map, i.bag_type));
    }
    return count;
}

fn answer2(allocator: *mem.Allocator) !u32 {
    var map = std.StringHashMap(std.ArrayList(Bag)).init(std.testing.allocator);
    defer map.deinit();

    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        var words = mem.split(line, " ");
        var parentBag = try utils.concat(std.testing.allocator, words.next().?, words.next().?);

        _ = words.next();
        _ = words.next();
        var list = std.ArrayList(Bag).init(std.testing.allocator);

        while (words.next()) |no| {
            if (!std.mem.eql(u8, no, "no")) {
                var w = words.next().?;
                if (!(std.mem.eql(u8, w[0 .. w.len - 1], "bags") or std.mem.eql(u8, w[0 .. w.len - 1], "bag"))) {
                    var childBag = try utils.concat(std.testing.allocator, w, words.next().?);
                    var bagWithCount = Bag{
                        .bag_type = childBag,
                        .quantity = std.fmt.parseInt(u8, no, 10) catch unreachable,
                    };

                    try list.append(bagWithCount);
                }
                _ = words.next();
            } else {
                _ = words.next();
                _ = words.next();
            }
        }

        try map.put(parentBag, list);
    }

    return countGoldBag(map, "shinygold");
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
    log.info("Day 7 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 07, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@intCast(u32, 4), a);
    testing.expectEqual(@intCast(u32, 272), a);
}

// TODO: there is a memory leak here
// test "Day 07, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     // testing.expectEqual(@intCast(u32, 32), a);
//     testing.expectEqual(@intCast(u32, 172246), a);
// }
