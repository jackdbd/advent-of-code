const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/19_sample.txt");
const input = @embedFile("inputs/19.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

const Rule = union(enum) {
    terminal: u8,
    productions: [][]usize,
};

const RulesMap = std.AutoHashMap(usize, Rule);

const RulesDb = struct {
    allocator: *mem.Allocator,
    map: RulesMap,

    const Self = @This();

    fn init(allocator: *mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .map = RulesMap.init(allocator),
        };
    }

    fn put(self: *Self, nrule: usize, rule: Rule) !void {
        try self.map.put(nrule, rule);
    }

    /// Parse a line and update the DB with a new rule.
    /// Some of the rules have multiple lists of sub-rules separated by a pipe.
    /// E.g. 1: 2 3 | 3 2
    /// means that rule 1 has 2 subrules, the 2 3 subrule, and the 3 2 subrule.
    /// TODO: fix memory leaks
    fn putFromLine(self: *Self, line: []const u8) !void {
        var subrule = std.ArrayList(usize).init(self.allocator);
        defer subrule.deinit();
        var subrules = std.ArrayList([]usize).init(self.allocator);
        defer subrules.deinit();

        var it = mem.tokenize(line, ": ");
        const nrule = try fmt.parseInt(usize, it.next().?, 10);
        while (it.next()) |item| {
            if (item[0] == '"') {
                try self.put(nrule, .{ .terminal = item[1] });
                return;
            } else if (mem.eql(u8, item, "|")) {
                try subrules.append(subrule.toOwnedSlice());
                continue;
            } else {
                try subrule.append(try fmt.parseInt(usize, item, 10));
            }
        }
        try subrules.append(subrule.toOwnedSlice());
        try self.put(nrule, .{ .productions = subrules.toOwnedSlice() });
    }

    /// check whether a message satisfies the set of rules in the db.
    fn query(self: *Self, msg: []const u8) bool {
        var parser = Parser{
            .map = &self.map,
            .msg = msg,
            .offset = 0,
        };
        return match(&parser, 0) and parser.offset == msg.len;
    }
};

const Parser = struct {
    map: *RulesMap,
    msg: []const u8,
    offset: usize,

    fn save(self: Parser) usize {
        return self.offset;
    }

    fn restore(self: *Parser, state: usize) void {
        self.offset = state;
    }
};

fn match(parser: *Parser, nrule: usize) bool {
    const rule = parser.map.get(nrule).?;
    // log.debug("nrule {} rule {}", .{nrule, rule});
    switch (rule) {
        .terminal => |term| {
            if (parser.offset < parser.msg.len and parser.msg[parser.offset] == term) {
                parser.offset += 1;
                return true;
            }
            return false;
        },
        .productions => |prods| {
            for (prods) |prod| {
                const state = parser.save();
                for (prod) |r| {
                    if (!match(parser, r)) break;
                } else {
                    // std.debug.print("match {} ->", .{ nrule });
                    // for (prod) |r| {
                    //     std.debug.print(" {}", .{ r });
                    // }
                    // std.debug.print("\n", .{});
                    return true;
                }
                parser.restore(state);
            }
            return false;
        },
    }
}

fn answer1(allocator: *mem.Allocator) !usize {
    var db = RulesDb.init(allocator);

    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) break;
        try db.putFromLine(line);
    }

    var valid_messages: usize = 0;
    while (lines.next()) |msg| {
        if (msg.len == 0) break;
        if (db.query(msg)) valid_messages += 1;
    }
    return valid_messages;
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
    log.info("Day 19 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 19, part 1" {
    const a = try answer1(testing.allocator);
    // testing.expectEqual(@intCast(usize, 2), a);
    testing.expectEqual(@intCast(usize, 109), a);
}

// test "Day 19, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     // testing.expectEqual(@intCast(usize, 8), a);
//     testing.expectEqual(@intCast(usize, 1235), a);
// }
