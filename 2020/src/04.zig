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
    const list = try passports(allocator);
    for (list.items) |pass, i| {
        // log.info("pass {} i {}", .{ pass, i });

        var fields: u8 = 0;
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
            // log.info("VALID (fields: {}, cid missing? {})", .{ fields, cid_missing });
            result += 1;
        }

        // log.info("Fields: {}, cid field missing: {}", .{fields, cid_missing});
    }
    return result;
}

fn isHex(c: u8) bool {
    return (c >= 'a' and c <= 'f') or (c >= '0' and c <= '9');
}

const eye_colors = [_][]const u8{ "amb", "blu", "brn", "gry", "grn", "hzl", "oth" };

fn isHeighValid(val: []const u8) bool {
    const v = fmt.parseInt(usize, val[0 .. val.len - 2], 10) catch |err| {
        std.debug.assert(err == error.InvalidCharacter);
        return false;
    };

    if (mem.endsWith(u8, val, "cm")) {
        if (v < 150 or v > 193) {
            return false;
        }
    } else if (mem.endsWith(u8, val, "in")) {
        if (v < 59 or v > 76) {
            return false;
        }
    }
    return true;
}

fn isHairColorValid(val: []const u8) bool {
    if (val.len != 7 or val[0] != '#') {
        return false;
    }
    for (val[1..]) |c| {
        if (!isHex(c)) {
            return false;
        }
    }
    return true;
}

fn isPassportIdValid(val: []const u8) bool {
    if (val.len != 9) {
        return false;
    }
    for (val[1..]) |c| {
        if (c < '0' or c > '9') {
            return false;
        }
    }
    return true;
}

fn answer2(allocator: *mem.Allocator) !i32 {
    var result: i32 = 0;
    const list = try passports(allocator);
    for (list.items) |pass, i| {
        // log.info("pass {} i {}", .{ pass, i });
        var fields: u8 = 0;
        var fields_valid = true;
        var cid_missing = true;

        var it = mem.split(pass, " ");
        while (it.next()) |s| {
            var key_and_value = try utils.splitByte(allocator, s, ':');
            const key = key_and_value[0];
            const val = key_and_value[1];

            if (mem.eql(u8, key, "byr")) {
                const v = try fmt.parseInt(usize, val, 10);
                if (v < 1920 or v > 2002) {
                    fields_valid = false;
                }
            } else if (mem.eql(u8, key, "iyr")) {
                const v = try fmt.parseInt(usize, val, 10);
                if (v < 2010 or v > 2020) {
                    fields_valid = false;
                }
            } else if (mem.eql(u8, key, "eyr")) {
                const v = try fmt.parseInt(usize, val, 10);
                if (v < 2020 or v > 2030) {
                    fields_valid = false;
                }
            } else if (mem.eql(u8, key, "hgt")) {
                if (!isHeighValid(val)) {
                    fields_valid = false;
                }
            } else if (mem.eql(u8, key, "hcl")) {
                if (!isHairColorValid(val)) {
                    fields_valid = false;
                }
            } else if (mem.eql(u8, key, "ecl")) {
                for (eye_colors) |eye_color| {
                    if (mem.eql(u8, eye_color, val)) {
                        break;
                    }
                } else {
                    fields_valid = false;
                }
            } else if (mem.eql(u8, key, "pid")) {
                if (!isPassportIdValid(val)) {
                    fields_valid = false;
                }
            } else if (mem.eql(u8, key, "cid")) {
                cid_missing = false;
            }
            fields += 1;
        }
        if ((fields == 8 and fields_valid) or (fields == 7 and fields_valid and cid_missing)) {
            // log.info("VALID (fields: {}, cid missing? {}, fields_valid: {})", .{ fields, cid_missing, fields_valid });
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

    const a1 = try answer1(&arena.allocator);
    const a2 = try answer2(&arena.allocator);
    log.info("Part 1: {}", .{a1});
    log.info("Part 2: {}", .{a2});

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

test "Day 04, part 2" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer2(&arena.allocator);
    // testing.expectEqual(@as(i32, 2), a);
    testing.expectEqual(@as(i32, 101), a);
}
