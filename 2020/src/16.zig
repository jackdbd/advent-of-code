const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/16_sample.txt");
// const input = @embedFile("inputs/16_sample2.txt");
const input = @embedFile("inputs/16.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

// TODO: refactor part 1 to use the same structs used in part 2. And add docs to functions

const Range = struct {
    low: usize,
    high: usize,
};

const Field = struct {
    name: []const u8, // e.g. "row", "seat", "departure track"
    rng0: Range,
    rng1: Range,
    const Self = @This();

    fn fromLine(line: []const u8) fmt.ParseIntError!Self {
        var it = mem.tokenize(line, ":");
        const i_colon = mem.lastIndexOf(u8, line, ":").?;
        const name = line[0..i_colon];
        var it2 = mem.tokenize(line[i_colon + 1 ..], " ");

        var nn = mem.split(it2.next().?, "-");
        _ = it2.next(); // it's the "or"
        var mm = mem.split(it2.next().?, "-");

        const n0 = try fmt.parseInt(usize, nn.next().?, 10);
        const n1 = try fmt.parseInt(usize, nn.next().?, 10);
        const m0 = try fmt.parseInt(usize, mm.next().?, 10);
        const m1 = try fmt.parseInt(usize, mm.next().?, 10);

        return Self{
            .name = name,
            .rng0 = Range{ .low = n0, .high = n1 },
            .rng1 = Range{ .low = m0, .high = m1 },
        };
    }

    fn isDigitInRange(self: *const Self, d: usize) bool {
        return ((d >= self.rng0.low and d <= self.rng0.high) or (d >= self.rng1.low and d <= self.rng1.high));
    }
};

const Ticket = struct {
    digits: []usize,
    string: []const u8,
    const Self = @This();

    fn fromLine(allocator: *mem.Allocator, line: []const u8) !Self {
        const n_items = mem.count(u8, line, ",") + 1;
        const digits = try allocator.alloc(usize, n_items);
        var it = mem.tokenize(line, ",");
        var i: usize = 0;
        while (i < n_items) : (i += 1) {
            digits[i] = try fmt.parseInt(usize, it.next().?, 10);
        }
        return Ticket{ .digits = digits, .string = line };
    }

    fn isValid(self: *const Self, fields: std.ArrayList(Field)) bool {
        var invalid_digits: usize = 0;
        for (self.digits[0..]) |d| {
            var count: usize = 0;
            for (fields.items) |field| {
                if ((d >= field.rng0.low and d <= field.rng0.high) or (d >= field.rng1.low and d <= field.rng1.high)) {
                    count += 1;
                }
            }
            if (count == 0) invalid_digits += 1;
        }
        return if (invalid_digits == 0) true else false;
    }
};

const Rule = struct {
    n0: usize,
    n1: usize,
    m0: usize,
    m1: usize,
};

const WordRuleMap = std.AutoHashMap([]const u8, Rule);

// TODO: refactor. This is Field.fromLine()
fn parseRules(map: *WordRuleMap, line: []const u8) !void {
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

// TODO: refactor. This is almost the same as Ticket.isValid()
fn invalidDigitsInTicket(map: *WordRuleMap, ticket: []const u8) fmt.ParseIntError!usize {
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
    var map = WordRuleMap.init(allocator);
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

    return error_rate;
}

// I don't know how to use a set in zig, so I use a hash map with a value of null
const CandidatesMap = std.AutoHashMap([]const u8, void);

const PositionCandidatesMap = std.AutoHashMap(usize, CandidatesMap);

fn answer2(allocator: *mem.Allocator) !usize {
    var result: usize = 1;
    var fields = std.ArrayList(Field).init(allocator);
    var my_ticket: Ticket = undefined;
    var nearby_tickets = std.ArrayList(Ticket).init(allocator);

    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        if (mem.eql(u8, "", line)) break;
        try fields.append(try Field.fromLine(line));
    }

    while (lines.next()) |line| {
        if (mem.eql(u8, "your ticket:", line)) {
            continue;
        } else if (mem.eql(u8, "", line)) {
            break;
        }
        my_ticket = try Ticket.fromLine(allocator, line);
    }

    while (lines.next()) |line| {
        if (mem.eql(u8, "nearby tickets:", line)) {
            continue;
        }
        try nearby_tickets.append(try Ticket.fromLine(allocator, line));
    }

    var map = PositionCandidatesMap.init(allocator);
    const n_positions = nearby_tickets.items[0].digits.len;
    const n_tickets = nearby_tickets.items.len;

    var i_pos: usize = 0;
    var n_invalid_tickets: usize = 0;
    while (i_pos < n_positions) : (i_pos += 1) {
        var cmap = CandidatesMap.init(allocator);
        for (fields.items) |field| {
            try cmap.put(field.name, .{});
        }
        for (nearby_tickets.items) |ticket, i_ticket| {
            if (ticket.isValid(fields)) {
                const d = ticket.digits[i_pos];
                for (fields.items) |field| {
                    if (!field.isDigitInRange(d)) {
                        _ = cmap.remove(field.name);
                    }
                }
            } else {
                if (i_pos == 0) n_invalid_tickets += 1;
            }
        }
        try map.put(i_pos, cmap);
    }
    // log.debug("Skipped {} invalid tickets", .{n_invalid_tickets});

    // Keep iterating on `map` (a PositionCandidatesMap) and removing stuff/
    // Messy, but it works. TODO: think about a recursive approach.
    var it = map.iterator();
    while (it.next()) |e| {
        i_pos = e.key;
        const cmap = map.get(i_pos).?;
        var itc = cmap.iterator();
        if (cmap.count() == 1) {
            const key = itc.next().?.key; // e.g. "row", "seat"
            // log.debug("FOUND {} at position {}", .{ key, i_pos });
            if (mem.startsWith(u8, key, "departure")) {
                // log.debug("my_ticket[{}]={}", .{ i_pos, my_ticket.digits[i_pos] });
                result *= my_ticket.digits[i_pos];
            }
            // now remove key from all the CandidatesMap
            var it_cleaner = map.iterator();
            while (it_cleaner.next()) |ee| {
                _ = ee.value.remove(key);
            }
            _ = map.remove(i_pos);
            it.index = 0;
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
    log.info("Day 16 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 16, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 71), a);
    testing.expectEqual(@intCast(usize, 18142), a);
}

test "Day 16, part 2" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer2(&arena.allocator);
    testing.expectEqual(@intCast(usize, 1069784384303), a);
}
