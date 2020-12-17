const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/17_sample.txt");
const input = @embedFile("inputs/17.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

const Coord = struct {
    x: isize,
    y: isize,
    z: isize,
    w: isize,
};

const Boundary = struct {
    min: Coord,
    max: Coord,
};

const Grid = struct {
    generation: usize,
    neighbor_size: isize, // isize instead of usize to avoid some type casts
    boundary: Boundary,
    map: std.AutoHashMap(Coord, ?bool),
};

fn neighbors(allocator: *mem.Allocator, c: Coord, four_d: bool) !std.ArrayList(Coord) {
    var list = std.ArrayList(Coord).init(allocator);
    for ([3]isize{ -1, 0, 1 }) |dx| {
        for ([3]isize{ -1, 0, 1 }) |dy| {
            for ([3]isize{ -1, 0, 1 }) |dz| {
                if (four_d) {
                    for ([3]isize{ -1, 0, 1 }) |dw| {
                        if (dx == 0 and dy == 0 and dz == 0 and dw == 0) continue; // a hypercube is not a neighbor of itself
                        try list.append(Coord{ .x = c.x + dx, .y = c.y + dy, .z = c.z + dz, .w = c.w + dw });
                    }
                } else {
                    if (dx == 0 and dy == 0 and dz == 0) continue; // a cube is not a neighbor of itself
                    try list.append(Coord{ .x = c.x + dx, .y = c.y + dy, .z = c.z + dz, .w = 0 });
                }
            }
        }
    }
    if (four_d) {
        std.debug.assert(list.items.len == 80);
    } else {
        std.debug.assert(list.items.len == 26);
    }
    return list;
}

fn printActiveCubes(grid: Grid) void {
    log.debug("active cubes at generation {}", .{grid.generation});
    var it = grid.map.iterator();
    while (it.next()) |e| {
        if ((e.value != null) and e.value.?) {
            log.debug("{}", .{e.key});
        }
    }
}

/// Parse the problem input and produce a starting grid.
fn startingGrid(allocator: *mem.Allocator) !Grid {
    var lines = try utils.splitByte(allocator, input, '\n');
    const nrows = lines.len;
    const ncols: usize = lines[0].len;

    var map = std.AutoHashMap(Coord, ?bool).init(allocator);

    var row: usize = 0;
    while (row < nrows) : (row += 1) {
        var col: usize = 0;
        while (col < ncols) : (col += 1) {
            const x = @intCast(isize, col);
            const y = @intCast(isize, row);
            const coord = Coord{ .x = x, .y = y, .z = 0, .w = 0 };
            const is_active = if (lines[row][col] == '#') true else false;
            try map.put(coord, is_active);
        }
    }

    const boundary = Boundary{
        .min = Coord{ .x = 0, .y = 0, .z = 0, .w = 0 },
        .max = Coord{ .x = @intCast(isize, nrows - 1), .y = @intCast(isize, ncols - 1), .z = 0, .w = 0 },
    };

    return Grid{
        .map = map,
        .generation = 0,
        .neighbor_size = 1,
        .boundary = boundary,
    };
}

/// Compute the new boundary (i.e. the search space for active/inactive cubes).
fn enlargedBoundary(b: Boundary, size: isize) Boundary {
    return Boundary{
        .min = Coord{
            .x = b.min.x - size,
            .y = b.min.y - size,
            .z = b.min.z - size,
            .w = b.min.w - size,
        },
        .max = Coord{
            .x = b.max.x + size,
            .y = b.max.y + size,
            .z = b.max.z + size,
            .w = b.max.w + size,
        },
    };
}

/// Produce a new grid without altering the old one.
fn step(allocator: *mem.Allocator, grid: Grid, four_d: bool) !Grid {
    // define the search space for the new, bigger grid
    const b = enlargedBoundary(grid.boundary, grid.neighbor_size);
    var map = std.AutoHashMap(Coord, ?bool).init(allocator);
    var x = b.min.x;
    while (x >= b.min.x and x <= b.max.x) : (x += 1) {
        var y = b.min.y;
        while (y >= b.min.y and y <= b.max.y) : (y += 1) {
            var z = b.min.z;
            while (z >= b.min.z and z <= b.max.z) : (z += 1) {
                if (four_d) {
                    var w = b.min.w;
                    while (w >= b.min.w and w <= b.max.w) : (w += 1) {
                        const new_coord = Coord{ .x = x, .y = y, .z = z, .w = w };
                        try map.put(new_coord, null);
                    }
                } else {
                    const new_coord = Coord{ .x = x, .y = y, .z = z, .w = 0 };
                    // log.debug("[{},{},{}]", .{ x, y, z });
                    try map.put(new_coord, null);
                }
            }
        }
    }

    var it = map.iterator();
    while (it.next()) |e| {
        const coord = e.key;
        // Every cube in the NEW grid will be either true (active) or false
        // (inactive). But a cube in the OLD grid could be null too, because it
        // represents coordinates that were outside of the search space.
        const active = grid.map.get(coord);
        var active_neighbors: usize = 0;
        const neighbor_coords = try neighbors(allocator, coord, four_d);
        for (neighbor_coords.items) |n| {
            const is_neighbor_active = grid.map.get(n);
            if (is_neighbor_active != null) {
                if (is_neighbor_active.? == true) active_neighbors += 1;
            }
        }
        // log.debug("[{},{},{}] (active={}) has {} active neighbors", .{ coord.x, coord.y, coord.z, active, active_neighbors });

        if (active != null) {
            // The double Optional unwrapping is because:
            // 1. map.get() can normally return null, but not here because I
            //    know that I called put with that key.
            // 2. the value of an entry in grid.map is ?bool
            // In this branch we know that active cannot be null, so we can
            // safely unwrap the Optional value.
            if ((active.?.? and active_neighbors == 2) or active_neighbors == 3) {
                try map.put(coord, true);
            } else {
                try map.put(coord, false);
            }
        } else {
            if (active_neighbors == 3) {
                try map.put(coord, true);
            } else {
                try map.put(coord, false);
            }
        }
    }

    return Grid{
        .neighbor_size = grid.neighbor_size,
        .generation = grid.generation + 1,
        .map = map,
        .boundary = b,
    };
}

/// Recursively produce a new grid for each boot cycle.
fn boot(allocator: *mem.Allocator, four_d: bool, grid: Grid, i: usize) !usize {
    if (i == 0) {
        var active_cubes: usize = 0;
        var it = grid.map.iterator();
        while (it.next()) |e| {
            const active = grid.map.get(e.key).?;
            if (active.?) active_cubes += 1;
        }
        return active_cubes;
    }
    const new_grid = try step(allocator, grid, four_d);
    return boot(allocator, four_d, new_grid, i - 1);
}

fn answer1(allocator: *mem.Allocator) !usize {
    const grid = try startingGrid(allocator);
    return try boot(allocator, false, grid, 6);
}

fn answer2(allocator: *mem.Allocator) !usize {
    const grid = try startingGrid(allocator);
    return try boot(allocator, true, grid, 6);
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
    log.info("Day 17 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 17, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 112), a);
    testing.expectEqual(@intCast(usize, 333), a);
}

test "Day 17, part 2" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer2(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 848), a);
    testing.expectEqual(@intCast(usize, 2676), a);
}
