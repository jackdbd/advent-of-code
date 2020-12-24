const std = @import("std");
// const input = @embedFile("inputs/24_sample.txt");
const input = @embedFile("inputs/24.txt");
const heap = std.heap;
const log = std.log;
const mem = std.mem;

/// Axial coordinate for a hexagon grid that has a pointy topped orientation.
/// https://www.redblobgames.com/grids/hexagons/
const AxialCoord = struct {
    q: isize,
    r: isize,
    const Self = @This();

    fn toCubeCoord(self: *Self) CubeCoord {
        const x = self.q;
        const z = self.r;
        const y = -x - z;
        return .{ .x = x, .y = y, .z = z };
    }
};

/// Cube coordinate for a hexagon grid that has a pointy topped orientation.
/// https://www.redblobgames.com/grids/hexagons/#coordinates-cube
const CubeCoord = struct {
    x: isize,
    y: isize,
    z: isize,
    const Self = @This();

    fn toAxialCoord(self: *Self) AxialCoord {
        return AxialCoord{ .q = self.x, .r = self.z };
    }
};

const TileMap = std.AutoHashMap(CubeCoord, bool);

/// Coordinate expressed in the cardinal directions East, North-West, South-West
/// (West = -East, South-East = - North-West, North-East = - South-West)
/// Note: this coordinate is easy to interpret and handy when parsing the input,
/// but it's better not to store this coordinate in the TileMap because one
/// point can be reached from more than one coordinate. For example, the
/// coordinate (e: 1, nw: -2, sw: 0) and the coordinate (e: 2, nw: -1, sw: 1)
/// end up in the same point on the hexagonal tiles grid.
const TileCoord = struct {
    e: isize, // east
    nw: isize, // north west
    sw: isize, // south west
    const Self = @This();

    fn fromLine(line: []const u8) Self {
        var i: usize = 0;
        var step: usize = 1;
        var e: isize = 0;
        var nw: isize = 0;
        var sw: isize = 0;
        while (i < line.len) {
            const x = line[i .. i + step];
            if (mem.eql(u8, x, "e")) {
                e += 1;
                i += 1;
                step = 1;
            } else if (mem.eql(u8, x, "w")) {
                e -= 1;
                i += 1;
                step = 1;
            } else if (mem.eql(u8, x, "nw")) {
                nw += 1;
                i += 2;
                step = 1;
            } else if (mem.eql(u8, x, "se")) {
                nw -= 1;
                i += 2;
                step = 1;
            } else if (mem.eql(u8, x, "sw")) {
                sw += 1;
                i += 2;
                step = 1;
            } else if (mem.eql(u8, x, "ne")) {
                sw -= 1;
                i += 2;
                step = 1;
            } else {
                step = 2;
            }
        }
        return Self{ .e = e, .nw = nw, .sw = sw };
    }

    fn toCubeCoord(self: *Self) CubeCoord {
        const x = self.e - self.sw;
        const y = -self.e + self.nw;
        const z = self.sw - self.nw; // z = -1 * (x + y)
        return .{ .x = x, .y = y, .z = z };
    }
};

fn answer1(allocator: *mem.Allocator) !usize {
    var map = TileMap.init(allocator);
    defer map.deinit();

    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        var tile_coord = TileCoord.fromLine(line);
        var cube_coord = tile_coord.toCubeCoord();
        // log.debug("{} => {}", .{tile_coord, cube_coord});
        const b = map.get(cube_coord);
        if (b != null) {
            // log.debug("Tile {} already flipped {}. Flipping it to {}", .{cube_coord, b, !b.?});
            try map.put(cube_coord, !b.?);
        } else {
            try map.put(cube_coord, true);
        }
    }

    var black_tiles: usize = 0;
    var it = map.iterator();
    while (it.next()) |e| {
        // log.debug("{}", .{e.value});
        if (e.value == true) black_tiles += 1;
    }
    return black_tiles;
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
    log.info("Day 24 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "TileCoord.fromLine()" {
    const tile_coord = TileCoord.fromLine("esew");
    testing.expectEqual(@intCast(isize, 0), tile_coord.e); // 1 w cancels out 1 e
    testing.expectEqual(@intCast(isize, -1), tile_coord.nw); // 1 se is -1 nw
    testing.expectEqual(@intCast(isize, 0), tile_coord.sw); // there are sw nor ne
}

test "TileCoord.fromLine(), back to reference tile" {
    var tile_coord = TileCoord.fromLine("nwwswee");
    testing.expectEqual(@intCast(isize, 1), tile_coord.e);
    testing.expectEqual(@intCast(isize, 1), tile_coord.nw);
    testing.expectEqual(@intCast(isize, 1), tile_coord.sw);
}

test "from Cube to Axial coordinates" {
    var cube = CubeCoord{ .x = 1, .y = -2, .z = 1 };
    var axial = cube.toAxialCoord();
    testing.expectEqual(@intCast(isize, 1), axial.q);
    testing.expectEqual(@intCast(isize, 1), axial.r);
}

test "from Axial to Cube coordinates" {
    var axial = AxialCoord{ .q = 1, .r = 1 };
    var cube = axial.toCubeCoord();
    testing.expectEqual(@intCast(isize, 1), cube.x);
    testing.expectEqual(@intCast(isize, -2), cube.y);
    testing.expectEqual(@intCast(isize, 1), cube.z);
}

test "Day 24, part 1" {
    const a = try answer1(testing.allocator);
    // testing.expectEqual(@intCast(usize, 10), a);
    testing.expectEqual(@intCast(usize, 277), a);
}

test "Day 24, part 2" {
    const a = try answer2(testing.allocator);
    testing.expectEqual(@intCast(usize, 0), a);
}
