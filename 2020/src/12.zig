const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/12_sample.txt");
const input = @embedFile("inputs/12.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;
const Dir = utils.Dir;

const Action = enum {
    N,
    S,
    E,
    W,
    L,
    R,
    F,
};

const Ship = struct {
    pos: utils.Pos,
    dir: Dir,

    const Self = @This();

    fn move(self: *Self, dir: Dir, units: isize) void {
        return switch (dir) {
            Dir.Up => self.pos.y -= units,
            Dir.Right => self.pos.x += units,
            Dir.Down => self.pos.y += units,
            Dir.Left => self.pos.x -= units,
        };
    }

    fn moveForward(self: *Self, units: isize) void {
        self.move(self.dir, units);
    }

    fn moveNorth(self: *Self, units: isize) void {
        self.move(Dir.Up, units);
    }

    fn moveSouth(self: *Self, units: isize) void {
        self.move(Dir.Down, units);
    }

    fn moveEast(self: *Self, units: isize) void {
        self.move(Dir.Right, units);
    }

    fn moveWest(self: *Self, units: isize) void {
        self.move(Dir.Left, units);
    }

    fn turnLeft90(self: *Self) void {
        return switch (self.dir) {
            Dir.Up => self.dir = Dir.Left,
            Dir.Right => self.dir = Dir.Up,
            Dir.Down => self.dir = Dir.Right,
            Dir.Left => self.dir = Dir.Down,
        };
    }

    fn turnLeft(self: *Self, degrees: isize) void {
        std.debug.assert(degrees == 90 or degrees == 180 or degrees == 270);
        var n = @divTrunc(degrees, 90);
        while (n > 0) : (n -= 1) {
            self.turnLeft90();
        }
    }

    fn turnRight90(self: *Self) void {
        return switch (self.dir) {
            Dir.Up => self.dir = Dir.Right,
            Dir.Right => self.dir = Dir.Down,
            Dir.Down => self.dir = Dir.Left,
            Dir.Left => self.dir = Dir.Up,
        };
    }

    fn turnRight(self: *Self, degrees: isize) void {
        std.debug.assert(degrees == 90 or degrees == 180 or degrees == 270);
        var n = @divTrunc(degrees, 90);
        while (n > 0) : (n -= 1) {
            self.turnRight90();
        }
    }
};

fn parseAction(s: *const [1]u8) Action {
    // I tried a switch but it didn't work...
    if (mem.eql(u8, s, "N")) {
        return Action.N;
    } else if (mem.eql(u8, s, "S")) {
        return Action.S;
    } else if (mem.eql(u8, s, "E")) {
        return Action.E;
    } else if (mem.eql(u8, s, "W")) {
        return Action.W;
    } else if (mem.eql(u8, s, "L")) {
        return Action.L;
    } else if (mem.eql(u8, s, "R")) {
        return Action.R;
    } else if (mem.eql(u8, s, "F")) {
        return Action.F;
    } else unreachable;
}

fn answer1(allocator: *mem.Allocator) !usize {
    var result: usize = 0;
    const p0 = utils.Pos{ .x = 0, .y = 0 };
    var ship = Ship{ .pos = p0, .dir = Dir.Right };

    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        const units = try fmt.parseInt(isize, line[1..], 10);
        const action = parseAction(line[0..1]);
        // log.info("line: {}, action: {}, units: {}", .{ line, action, units });
        switch (action) {
            Action.N => ship.moveNorth(units),
            Action.S => ship.moveSouth(units),
            Action.E => ship.moveEast(units),
            Action.W => ship.moveWest(units),
            Action.L => ship.turnLeft(units),
            Action.R => ship.turnRight(units),
            Action.F => ship.moveForward(units),
        }
        // log.info("{} {} ship {}", .{ action, units, ship });
    }
    // log.info("p0 {}, ship.pos {}", .{ p0, ship.pos });
    return utils.manhattan(p0, ship.pos);
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
    // const a2 = try answer2(&arena.allocator);
    log.info("Part 1: {}", .{a1});
    // log.info("Part 2: {}", .{a2});

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("Day 12 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 12, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 25), a);
    testing.expectEqual(@intCast(usize, 562), a);
}

// test "Day 12, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     // testing.expectEqual(@intCast(i32, 8), a);
//     testing.expectEqual(@intCast(i32, 1235), a);
// }
