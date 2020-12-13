const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/13_sample.txt");
const input = @embedFile("inputs/13.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

fn answer1(allocator: *mem.Allocator) !usize {
    var result: usize = 0;
    const lines = try utils.splitByte(allocator, input, '\n');
    defer allocator.free(lines);

    const ts = try fmt.parseInt(usize, lines[0], 10);
    var earliest_ts = ts + 1000000000; // an arbitrary big number (math.inf() is for floats only)
    var token_iter = mem.tokenize(lines[1], ",x");
    while (token_iter.next()) |s| {
        // log.debug("{}", .{s});
        var wait_minutes: usize = 0;
        const bus_id = try fmt.parseInt(usize, s, 10);

        if (bus_id == ts) {
            return 0; // bus id * wait for 0 minutes
        } else if (bus_id > ts) {
            if (bus_id < earliest_ts) {
                earliest_ts = bus_id;
                wait_minutes = bus_id - ts;
            }
        } else {
            const dExact = @floatToInt(usize, @intToFloat(f64, ts) / @intToFloat(f64, bus_id));
            const dCeil = @floatToInt(usize, std.math.ceil(@intToFloat(f64, ts) / @intToFloat(f64, bus_id)));
            // const y = @intToFloat(f64, @divFloor(ts, bus_id));
            if (dExact == dCeil) {
                return 0; // earliest_ts = bus_id * dExact --> earliest_ts * wait for 0 minutes
            } else if (dCeil > dExact) {
                if (dCeil * bus_id < earliest_ts) {
                    earliest_ts = dCeil * bus_id;
                    wait_minutes = earliest_ts - ts;
                    result = bus_id * wait_minutes;
                }
            } else unreachable;
        }
    }

    return result;
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
    log.info("Day 13 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 13, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 295), a);
    testing.expectEqual(@intCast(usize, 6568), a);
}

// test "Day 13, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     // testing.expectEqual(@intCast(i32, 8), a);
//     testing.expectEqual(@intCast(i32, 1235), a);
// }
