const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/16_sample.txt");
const input = @embedFile("inputs/16.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

const Rule = struct {
    n0: usize,
    n1: usize,
    m0: usize,
    m1: usize,
};

const TicketMap = std.AutoHashMap([]const u8, Rule);

fn parseRules(map: *TicketMap, line: []const u8) !void {
    var it = mem.tokenize(line, ":");
    const i_colon = mem.lastIndexOf(u8, line, ":").?;
    const word = line[0..i_colon];
    var it2 = mem.tokenize(line[i_colon + 1 ..], " ");
    const rng0 = it2.next().?;
    _ = it2.next();
    const rng1 = it2.next().?;

    var nn = mem.split(rng0, "-");
    const n0 = try fmt.parseInt(usize, nn.next().?, 10);
    const n1 = try fmt.parseInt(usize, nn.next().?, 10);

    var mm = mem.split(rng1, "-");
    const m0 = try fmt.parseInt(usize, mm.next().?, 10);
    const m1 = try fmt.parseInt(usize, mm.next().?, 10);

    try map.put(word, Rule{ .n0 = n0, .n1 = n1, .m0 = m0, .m1 = m1 });
}

fn invalidDigitsInTicket(map: *TicketMap, ticket: []const u8) fmt.ParseIntError!usize {
    // log.debug("TICKET {}", .{ticket});
    var invalid_sum: usize = 0;
    var digits = mem.split(ticket, ",");
    while (digits.next()) |s| {
        const d = try fmt.parseInt(usize, s, 10);
        var count: usize = 0;
        var it = map.iterator();
        while (it.next()) |e| {
            const n0 = e.value.n0;
            const n1 = e.value.n1;
            const m0 = e.value.m0;
            const m1 = e.value.m1;
            if ((d >= n0 and d <= n1) or (d >= m0 and d <= m1)) {
                count += 1;
            }
        }
        if (count == 0) invalid_sum += d;
        // log.debug("count {} d {} invalid_sum {}", .{count, d, invalid_sum});
    }
    return invalid_sum;
}

fn answer1(allocator: *mem.Allocator) !usize {
    var error_rate: usize = 0;

    var map = TicketMap.init(allocator);

    var parsing_rules = true;
    var parsing_my_ticket = false;
    var parsing_nearby_tickets = false;

    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        // this is horrible...
        if (mem.eql(u8, "", line)) {
            if (parsing_rules) {
                parsing_rules = false;
                parsing_my_ticket = true;
            } else if (parsing_my_ticket) {
                parsing_my_ticket = false;
                parsing_nearby_tickets = true;
            }
            continue;
        }
        if (mem.eql(u8, "your ticket:", line) or mem.eql(u8, "nearby tickets:", line)) {
            continue;
        }

        if (parsing_rules) {
            try parseRules(&map, line);
        } else if (parsing_my_ticket) {
            log.debug("my ticket {}", .{line});
            var digits = mem.split(line, ",");
            while (digits.next()) |s| {
                const d = try fmt.parseInt(usize, s, 10);
                // log.debug("parsing MY ticket {}", .{d});
            }
        } else {
            error_rate += try invalidDigitsInTicket(&map, line);
        }
    }

    // var it = map.iterator();
    // while (it.next()) |e| {
    //     log.debug("e {}", .{e});
    // }

    return error_rate;
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
    log.info("Day 16 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 16, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    testing.expectEqual(@intCast(usize, 71), a);
    testing.expectEqual(@intCast(usize, 18142), a);
}

// test "Day 16, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     // testing.expectEqual(@intCast(i32, 8), a);
//     testing.expectEqual(@intCast(i32, 1235), a);
// }
