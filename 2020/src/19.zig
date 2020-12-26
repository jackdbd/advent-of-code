const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/19_sample.txt");
const input = @embedFile("inputs/19.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

/// A rule can be either atomic, or composite.
/// E.g.
/// 5: "b" is an atomic rule
/// 4: "a" is an atomic rule
/// 3: 4 5 | 5 4 is a composite rule made of atomic rules
/// 2: 4 4 | 5 5 is a composite rule made of atomic rules
/// 1: 2 3 | 3 2 is a composite rule made of composite rules
/// 0: 4 1 5 is a composite rule made of atomic and composite rules
const Rule = union(enum) {
    atomic: u8,
    composite: [][]usize,

    const Self = @This();

    // TODO: this method has a memory leak for .composite rules (it's fine for
    // .atomic rules). I tried to use errdefer but it didn't seem to work. I'm
    // pretty sure I need to use errdefer, I just don't know where to use it.
    fn fromString(allocator: *mem.Allocator, string: []const u8) !Self {
        std.debug.assert(mem.indexOf(u8, string, ":") == null);
        var subrule = std.ArrayList(usize).init(allocator);
        defer subrule.deinit();
        var subrules = std.ArrayList([]usize).init(allocator);
        defer subrules.deinit();
        // errdefer allocator.free(subrules);

        var it = mem.tokenize(string, " ");
        while (it.next()) |item| {
            if (item[0] == '"') {
                return Self{ .atomic = item[1] };
            } else if (mem.eql(u8, item, "|")) {
                try subrules.append(subrule.toOwnedSlice()); // no memory leaks here?
            } else {
                const n = try fmt.parseInt(usize, item, 10);
                try subrule.append(n); // memory leak
            }
        }
        try subrules.append(subrule.toOwnedSlice()); // memory leak
        return Self{ .composite = subrules.toOwnedSlice() };
    }
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

    /// Parse a line and update the rules DB with a new rule.
    /// Some of the rules have multiple lists of sub-rules separated by a pipe.
    /// E.g. 1: 2 3 | 3 2
    /// means that rule 1 has 2 subrules, the 2 3 subrule, and the 3 2 subrule.
    fn putFromLine(self: *Self, line: []const u8) !void {
        std.debug.assert(mem.indexOf(u8, line, ":") != null);
        const i_colon = mem.indexOf(u8, line, ":").?;
        const nrule = try fmt.parseInt(usize, line[0..i_colon], 10);
        const rule = try Rule.fromString(self.allocator, line[i_colon + 2 ..]);
        try self.put(nrule, rule);
    }

    /// check whether a message satisfies the set of rules in the DB.
    fn query(self: *Self, msg: []const u8) bool {
        var parser = Parser{
            .map = &self.map,
            .msg = msg,
            .offset = 0,
        };
        return match(&parser, 0) and parser.offset == msg.len;
    }

    fn query2(self: *Self, msg: []const u8) bool {
        var parser = Parser{
            .map = &self.map,
            .msg = msg,
            .offset = 0,
        };

        var i: usize = 0;
        while (match(&parser, 42)) : (i += 1) {}

        var j: usize = 0;
        while (match(&parser, 31)) : (j += 1) {}

        return i > j and j > 0 and parser.offset == msg.len;
    }
};

const Parser = struct {
    map: *RulesMap,
    msg: []const u8,
    offset: usize,

    fn save(self: Parser) usize {
        return self.offset;
    }

    fn restore(self: *Parser, offset: usize) void {
        self.offset = offset;
    }
};

fn match(parser: *Parser, nrule: usize) bool {
    const rule = parser.map.get(nrule).?;
    switch (rule) {
        .atomic => |term| {
            if (parser.offset < parser.msg.len and parser.msg[parser.offset] == term) {
                parser.offset += 1;
                return true;
            }
            return false;
        },
        .composite => |subrules| {
            for (subrules) |subrule| {
                const offset = parser.save();
                for (subrule) |r| {
                    if (!match(parser, r)) break;
                } else {
                    // std.debug.print("match {} ->", .{ nrule });
                    // for (subrule) |r| {
                    //     std.debug.print(" {}", .{ r });
                    // }
                    // std.debug.print("\n", .{});
                    return true;
                }
                parser.restore(offset);
            }
            return false;
        },
    }
}

fn answer1(db: *RulesDb, lines: *mem.SplitIterator) !usize {
    var valid_messages: usize = 0;
    while (lines.next()) |msg| {
        if (msg.len == 0) break;
        if (db.query(msg)) valid_messages += 1;
    }
    return valid_messages;
}

fn answer2(db: *RulesDb, lines: *mem.SplitIterator) !usize {
    var valid_messages: usize = 0;
    while (lines.next()) |msg| {
        if (msg.len == 0) break;
        if (db.query2(msg)) valid_messages += 1;
    }
    return valid_messages;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    var db = RulesDb.init(&arena.allocator);

    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) break;
        try db.putFromLine(line);
    }
    const idx = lines.index;

    const a1 = try answer1(&db, &lines);
    lines.index = idx;
    log.info("Part 1: {}", .{a1});
    const a2 = try answer2(&db, &lines);
    log.info("Part 2: {}", .{a2});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 19 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Rule.fromString() rule.atomic" {
    var rule = try Rule.fromString(testing.allocator, "\"a\"");
    testing.expectEqual(@intCast(usize, 97), rule.atomic);
}

test "Rule.fromString() rule.composite without pipe" {
    // var arena = heap.ArenaAllocator.init(heap.page_allocator);
    // defer arena.deinit();
    var rule = try Rule.fromString(testing.allocator, "4 1 5");
    testing.expectEqual(@intCast(usize, 1), rule.composite.len);
    testing.expectEqual(@intCast(usize, 4), rule.composite[0][0]);
    testing.expectEqual(@intCast(usize, 1), rule.composite[0][1]);
    testing.expectEqual(@intCast(usize, 5), rule.composite[0][2]);
}

test "Rule.fromString() rule.composite with pipe" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    var rule = try Rule.fromString(&arena.allocator, "4 5 | 5 4");
    testing.expectEqual(@intCast(usize, 2), rule.composite.len);
    testing.expectEqual(@intCast(usize, 4), rule.composite[0][0]);
    testing.expectEqual(@intCast(usize, 5), rule.composite[0][1]);
    testing.expectEqual(@intCast(usize, 5), rule.composite[1][0]);
    testing.expectEqual(@intCast(usize, 4), rule.composite[1][1]);
}

test "Day 19, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    var db = RulesDb.init(&arena.allocator);
    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) break;
        try db.putFromLine(line);
    }

    const a = try answer1(&db, &lines);
    // testing.expectEqual(@intCast(usize, 2), a);
    testing.expectEqual(@intCast(usize, 109), a);
}

test "Day 19, part 2" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    var db = RulesDb.init(&arena.allocator);
    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) break;
        try db.putFromLine(line);
    }

    const a = try answer2(&db, &lines);
    testing.expectEqual(@intCast(usize, 301), a);
}
