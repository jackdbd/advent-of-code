const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/12_sample.txt");
const input = @embedFile("inputs/12.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;
const Dir = utils.Dir;
const Pos = utils.Pos;

const Action = enum {
    N,
    S,
    E,
    W,
    L,
    R,
    F,
};

// I chose this coordinate system:
// x are positive rightwards
// y are positive upwards

const Ship = struct {
    pos: Pos,
    dir: Dir,

    const Self = @This();

    fn move(self: *Self, dir: Dir, units: isize) void {
        return switch (dir) {
            Dir.Up => self.pos.y += units,
            Dir.Right => self.pos.x += units,
            Dir.Down => self.pos.y -= units,
            Dir.Left => self.pos.x -= units,
        };
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

    fn moveForward(self: *Self, units: isize) void {
        self.move(self.dir, units);
    }

    fn rotateCounterClockwise90(self: *Self) void {
        return switch (self.dir) {
            Dir.Up => self.dir = Dir.Left,
            Dir.Right => self.dir = Dir.Up,
            Dir.Down => self.dir = Dir.Right,
            Dir.Left => self.dir = Dir.Down,
        };
    }

    fn rotateLeft(self: *Self, degrees: isize) void {
        std.debug.assert(degrees == 90 or degrees == 180 or degrees == 270);
        var n = @divTrunc(degrees, 90);
        while (n > 0) : (n -= 1) {
            self.rotateCounterClockwise90();
        }
    }

    fn rotateClockwise90(self: *Self) void {
        return switch (self.dir) {
            Dir.Up => self.dir = Dir.Right,
            Dir.Right => self.dir = Dir.Down,
            Dir.Down => self.dir = Dir.Left,
            Dir.Left => self.dir = Dir.Up,
        };
    }

    fn rotateRight(self: *Self, degrees: isize) void {
        std.debug.assert(degrees == 90 or degrees == 180 or degrees == 270);
        var n = @divTrunc(degrees, 90);
        while (n > 0) : (n -= 1) {
            self.rotateClockwise90();
        }
    }
};

const Waypoint = struct {
    pos: Pos,
    ship: *Ship,

    const Self = @This();

    fn move(self: *Self, dir: Dir, units: isize) void {
        return switch (dir) {
            Dir.Up => self.pos.y += units,
            Dir.Right => self.pos.x += units,
            Dir.Down => self.pos.y -= units,
            Dir.Left => self.pos.x -= units,
        };
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

    fn moveForward(self: *Self, units: isize) void {
        self.ship.pos.x += self.pos.x * units;
        self.ship.pos.y += self.pos.y * units;
    }

    fn rotate(self: *Self, clockwise: bool) void {
        if (clockwise) {
            self.ship.rotateClockwise90();
            const tmp = self.pos.x;
            self.pos.x = self.pos.y;
            self.pos.y = tmp * (-1);
        } else {
            self.ship.rotateCounterClockwise90();
            const tmp = self.pos.x;
            self.pos.x = self.pos.y * (-1);
            self.pos.y = tmp;
        }
    }

    fn rotateLeft(self: *Self, degrees: isize) void {
        std.debug.assert(degrees == 90 or degrees == 180 or degrees == 270);
        var n = @divTrunc(degrees, 90);
        while (n > 0) : (n -= 1) {
            self.rotate(false);
        }
    }

    fn rotateRight(self: *Self, degrees: isize) void {
        std.debug.assert(degrees == 90 or degrees == 180 or degrees == 270);
        var n = @divTrunc(degrees, 90);
        while (n > 0) : (n -= 1) {
            self.rotate(true);
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
    const p0 = Pos{ .x = 0, .y = 0 };
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
            Action.L => ship.rotateLeft(units),
            Action.R => ship.rotateRight(units),
            Action.F => ship.moveForward(units),
        }
        // log.info("{} {} ship {}", .{ action, units, ship });
    }
    return utils.manhattan(p0, ship.pos);
}

fn answer2(allocator: *mem.Allocator) !usize {
    const p0 = Pos{ .x = 0, .y = 0 };
    var ship = Ship{ .pos = p0, .dir = Dir.Right };
    var waypoint = Waypoint{ .pos = Pos{ .x = ship.pos.x + 10, .y = ship.pos.y + 1 }, .ship = &ship };

    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        const units = try fmt.parseInt(isize, line[1..], 10);
        const action = parseAction(line[0..1]);
        switch (action) {
            Action.N => waypoint.moveNorth(units),
            Action.S => waypoint.moveSouth(units),
            Action.E => waypoint.moveEast(units),
            Action.W => waypoint.moveWest(units),
            Action.L => waypoint.rotateLeft(units),
            Action.R => waypoint.rotateRight(units),
            Action.F => waypoint.moveForward(units),
        }
        // log.info("{} {} waypoint (relative to ship) [{},{}] ship [{},{}]", .{ action, units, waypoint.pos.x, waypoint.pos.y, ship.pos.x, ship.pos.y });
    }
    return utils.manhattan(p0, ship.pos);
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

test "Day 12, part 2" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer2(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 286), a);
    testing.expectEqual(@intCast(usize, 101860), a);
}
