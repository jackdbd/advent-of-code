const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/04_sample.txt");
const input = @embedFile("inputs/04.txt");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

/// Create list of passports from input file.
fn passports(allocator: *mem.Allocator) !std.ArrayList([]const u8) {
    var it = std.mem.split(input, "\n\n");
    var list = std.ArrayList([]const u8).init(allocator);
    while (it.next()) |string| {
        var passport_chunks = try utils.splitByte(allocator, string, '\n');
        const passport = try mem.join(allocator, " ", passport_chunks);
        // log.info("passport: {}", .{passport});
        try list.append(passport);
    }
    return list;
}


fn answer1(allocator: *mem.Allocator) !i32 {
    var result: i32 = 0;
    // var lines = try utils.splitByte(allocator, input, '\n');
    // defer allocator.free(lines);
    const list = try passports(allocator);
    for (list.items) |pass, i| {
        log.info("pass {} i {}", .{pass, i});

        var fields:u8 = 0;
        var cid_missing = true;
        var it = mem.split(pass, " ");
        while (it.next()) |s| {
            var key_and_value = try utils.splitByte(allocator, s, ':');
            const key = key_and_value[0];
            const val = key_and_value[1];
            if (mem.eql(u8, key, "cid")) {
                cid_missing = false;
            }
            // log.info("key: {}, value: {}", .{key, val});
            fields += 1;
        }
        if (fields == 8 or (fields == 7 and cid_missing)) {
            // log.info("Pass: {}, is valid", .{i});
            log.info("VALID (fields: {}, cid missing? {})", .{fields, cid_missing});
            result += 1;
        }

        // log.info("Fields: {}, cid field missing: {}", .{fields, cid_missing});
    }
    return result;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();
    
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const a1 = try answer1(&arena.allocator);
    // const a2 = try answer2(&arena.allocator);
    log.info("Part 1: {}", .{a1});
    // log.info("Part 2: {}", .{a2});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 4 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 04, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@as(i32, 2), a);
    testing.expectEqual(@as(i32, 192), a);
}

// test "Day 04, part 2" {
//     const a = try answer2(testing.allocator);
//     testing.expectEqual(@as(i32, 336), a);
//     // testing.expectEqual(@as(i32, 1744787392), a);
// }
