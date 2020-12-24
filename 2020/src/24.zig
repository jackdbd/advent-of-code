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

    /// Neighbors of an axial coordinate
    /// https://www.redblobgames.com/grids/hexagons/#neighbors
    fn neighbors(self: *Self) [6]AxialCoord {
        return [6]AxialCoord{
            AxialCoord{ .q = 1, .r = -1 },
            AxialCoord{ .q = 1, .r = 0 },
            AxialCoord{ .q = 0, .r = 1 },
            AxialCoord{ .q = -1, .r = 1 },
            AxialCoord{ .q = -1, .r = 0 },
            AxialCoord{ .q = 0, .r = -1 },
        };
    }
};

/// Cube coordinate for a hexagon grid that has a pointy topped orientation.
/// https://www.redblobgames.com/grids/hexagons/#coordinates-cube
/// Note: I tried to use cube coordinates first, and they are fine for part 1,
/// but I need to use axial coordinates to solve part 2 in a reasonable time.
const CubeCoord = struct {
    x: isize,
    y: isize,
    z: isize,
    const Self = @This();

    fn toAxialCoord(self: *Self) AxialCoord {
        return AxialCoord{ .q = self.x, .r = self.z };
    }

    /// Neighbors of a cube coordinate
    /// https://www.redblobgames.com/grids/hexagons/#neighbors
    fn neighbors(self: *Self) [6]CubeCoord {
        return [6]CubeCoord{
            CubeCoord{ .x = 1, .y = 0, .z = -1 },
            CubeCoord{ .x = 1, .y = -1, .z = 0 },
            CubeCoord{ .x = 0, .y = -1, .z = 1 },
            CubeCoord{ .x = -1, .y = 0, .z = 1 },
            CubeCoord{ .x = -1, .y = 1, .z = 0 },
            CubeCoord{ .x = 0, .y = 1, .z = -1 },
        };
    }
};

const TileMapCube = std.AutoHashMap(CubeCoord, bool);
const TileMapAxial = std.AutoHashMap(AxialCoord, bool);

fn setTileMapCube(map: *TileMapCube) !void {
    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        var tile_coord = TileCoord.fromLine(line);
        var cube_coord = tile_coord.toCubeCoord();
        const b = map.get(cube_coord); // false = white side up, true = black side up
        if (b != null) {
            try map.put(cube_coord, !b.?);
        } else {
            try map.put(cube_coord, true);
        }
    }
}

fn setTileMapAxial(map: *TileMapAxial) !void {
    var lines = mem.split(input, "\n");
    while (lines.next()) |line| {
        var tile_coord = TileCoord.fromLine(line);
        var axial_coord = tile_coord.toCubeCoord().toAxialCoord();
        const b = map.get(axial_coord); // false = white side up, true = black side up
        if (b != null) {
            try map.put(axial_coord, !b.?);
        } else {
            try map.put(axial_coord, true);
        }
    }
}

/// Fill with white tiles any missing holes in an hexagonal grid.
/// Note: this is extremely inefficient, especially for cube coordinates. Is
/// there a better way?
fn fillUpWithWhiteTiles(map: *TileMapAxial) !void {
    const tiles_pre = map.count();
    const blacks_before = countBlackTilesAxial(map);
    var q_min: isize = 0;
    var q_max: isize = 0;
    var r_min: isize = 0;
    var r_max: isize = 0;

    // I really don't know why I need to expand the grid by at least this amout.
    const expand = 50;

    var it = map.iterator();
    while (it.next()) |e| {
        const c = e.key;
        if (c.q < q_min) q_min = c.q - expand;
        if (c.q > q_max) q_max = c.q + expand;
        if (c.r < r_min) r_min = c.r - expand;
        if (c.r > r_max) r_max = c.r + expand;
    }

    var q = q_min;
    while (q <= q_max) : (q += 1) {
        var r = r_min;
        while (r <= r_max) : (r += 1) {
            const c = AxialCoord{ .q = q, .r = r };
            const color = map.get(c) orelse false; // false means white
            try map.put(c, color);
        }
    }
    const tiles_after = map.count();
    const blacks_after = countBlackTilesAxial(map);
    std.debug.assert(tiles_after >= tiles_pre);
    std.debug.assert(blacks_after == blacks_before);
    // log.debug("q: [{},{}] r: [{},{}]", .{ q_min, q_max, r_min, r_max });
}

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

fn countBlackTilesCube(map: *TileMapCube) usize {
    var count: usize = 0;
    var it = map.iterator();
    while (it.next()) |e| {
        if (e.value == true) count += 1;
    }
    return count;
}

fn countBlackTilesAxial(map: *TileMapAxial) usize {
    var count: usize = 0;
    var it = map.iterator();
    while (it.next()) |e| {
        if (e.value == true) count += 1;
    }
    return count;
}

fn answer1(allocator: *mem.Allocator) !usize {
    var map = TileMapCube.init(allocator);
    defer map.deinit();
    try setTileMapCube(&map);
    return countBlackTilesCube(&map);
}

/// Every day the floor tiles are flipped according to a set of rules.
/// Keep in mind that every tile starts with the white side up.
fn exhibit(day: usize, src: *TileMapAxial, dst: *TileMapAxial) !void {
    try fillUpWithWhiteTiles(src);
    var it_src = src.iterator();
    var i: usize = 0;
    while (it_src.next()) |e| {
        var c = e.key;
        const is_black = e.value;
        const tile_color = if (is_black) "black" else "white";

        var blacks: usize = 0; // neighbor tiles with the black side up
        const nn = c.neighbors();
        for (nn) |n| {
            const c0 = AxialCoord{ .q = c.q + n.q, .r = c.r + n.r };
            const is_neighbor_black = src.get(c0) orelse false;
            const color = if (is_neighbor_black) "black" else "white";
            if (is_neighbor_black) blacks += 1;
        }

        if (is_black and (blacks == 0 or blacks > 2)) {
            try dst.put(c, false);
        } else if (!is_black and blacks == 2) {
            try dst.put(c, true);
        } else {
            try dst.put(c, is_black);
        }
        i += 1;
    }
}

fn answer2(allocator: *mem.Allocator) !usize {
    var src = TileMapAxial.init(allocator);
    defer src.deinit();
    var dst = TileMapAxial.init(allocator);
    defer dst.deinit();

    try setTileMapAxial(&src);

    var day: usize = 1;
    var black_tiles: usize = 0;
    while (day <= 100) : (day += 1) {
        if (day % 2 != 0) {
            try exhibit(day, &src, &dst);
            black_tiles = countBlackTilesAxial(&dst);
            // log.debug("Black tiles after {} days: {}", .{ day, countBlackTilesAxial(&dst) });
        } else {
            try exhibit(day, &dst, &src);
            black_tiles = countBlackTilesAxial(&src);
            // log.debug("Black tiles after {} days: {}", .{ day, countBlackTilesAxial(&src) });
        }
    }

    return black_tiles;
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
    // testing.expectEqual(@intCast(usize, 2208), a);
    testing.expectEqual(@intCast(usize, 3531), a);
}
