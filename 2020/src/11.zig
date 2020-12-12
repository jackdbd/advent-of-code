const std = @import("std");
const utils = @import("utils.zig");
// const input = @embedFile("inputs/11_sample.txt");
const input = @embedFile("inputs/11.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

// . floor
// L empty seat
// # occupied seat

const MooreNeighbor = struct {
    x: isize,
    y: isize,
};

const Neighbor = struct {
    col: usize,
    row: usize,
    cell: u8,
};

/// Moore neighborhood of a cell.
fn mooreNeighbors(allocator: *mem.Allocator, x: isize, y: isize) !std.ArrayList(MooreNeighbor) {
    // log.debug("neighbors of x: {}, y: {}", .{ x, y });
    var list = std.ArrayList(MooreNeighbor).init(allocator);
    for ([3]isize{ -1, 0, 1 }) |dx| {
        // this does not work in zig
        // var yy = if (dx == 0) [2]isize{-1, 1} else [3]isize{-1, 0, 1};
        var yy = [3]isize{ -1, 0, 1 };
        for (yy) |dy| {
            if (dx == 0 and dy == 0) continue; // a cell is not a neighbor of itself
            // log.debug("x: {}, dx: {}, y: {}, dy: {}", .{ x, dx, y, dy });
            try list.append(MooreNeighbor{ .x = x + dx, .y = y + dy });
        }
    }
    return list;
}

fn seatNeighbors(allocator: *mem.Allocator, cells: *[][]const u8, col: usize, row: usize) !std.ArrayList(Neighbor) {
    const nrows = cells.*.len;
    const ncols: usize = cells.*[0].len;

    var list = std.ArrayList(Neighbor).init(allocator);
    const moore_neighbors = try mooreNeighbors(allocator, @intCast(isize, col), @intCast(isize, row));
    for (moore_neighbors.items) |n| {
        if (n.x >= 0 and n.x < ncols and n.y >= 0 and n.y < nrows) {
            const c = @intCast(usize, n.x);
            const r = @intCast(usize, n.y);
            try list.append(Neighbor{ .col = c, .row = r, .cell = cells.*[r][c] });
        }
    }
    return list;
}

fn willBeOccupied(n_occupied: usize, seat: u8) bool {
    if (isFloor(seat)) {
        return false;
    } else if (isEmpty(seat) and (n_occupied == 0)) {
        return true;
    } else if (isOccupied(seat) and (n_occupied >= 4)) {
        return false;
    } else {
        return isOccupied(seat);
    }
}

fn isFloor(seat: u8) bool {
    return if (seat == 46) true else false; // 46 is .
}

fn isEmpty(seat: u8) bool {
    return if (seat == 76) true else false; // 76 is L
}

fn isOccupied(seat: u8) bool {
    return if (seat == 35) true else false; // 35 is #
}

const Grid = struct {
    occupied: usize,
    cells: *[][]const u8,
};

fn step1(allocator: *mem.Allocator, cells: *[][]const u8) !Grid {
    const nrows = cells.*.len;
    const ncols: usize = cells.*[0].len;
    var grid = std.ArrayList(std.ArrayList(u8)).init(allocator);

    var occupied: usize = 0;
    var row: usize = 0;
    while (row < nrows) : (row += 1) {
        var grid_line = std.ArrayList(u8).init(allocator);
        var col: usize = 0;
        while (col < ncols) : (col += 1) {
            const seat = cells.*[row][col];
            const neighbors = try seatNeighbors(allocator, cells, col, row);

            var n_occupied: usize = 0;
            for (neighbors.items) |n| {
                if (isOccupied(n.cell)) {
                    n_occupied += 1;
                }
            }
            if (isFloor(seat)) {
                try grid_line.append(46);
            } else if (willBeOccupied(n_occupied, seat)) {
                try grid_line.append(35);
                occupied += 1;
            } else {
                try grid_line.append(76);
            }
        }
        try grid.append(grid_line);
    }

    for (grid.items) |line, irow| {
        cells.*[irow] = line.items;
    }
    return Grid{ .cells = cells, .occupied = occupied };
}

fn answer1(allocator: *mem.Allocator) !usize {
    var result: usize = 0;
    var lines = try utils.splitByte(allocator, input, '\n');

    var grid = try step1(allocator, &lines);
    var occupied_pre: usize = 0;
    while (grid.occupied != occupied_pre) {
        occupied_pre = grid.occupied;
        grid = try step1(allocator, grid.cells);
    }
    return grid.occupied;
}

const Direction = struct {
    x: isize,
    y: isize,
};

const Grid2 = struct {
    occupied: usize,
    cells: *[][]const u8,
};

fn step2(allocator: *mem.Allocator, cells: *[][]const u8) !Grid2 {
    const nrows = cells.*.len;
    const ncols: usize = cells.*[0].len;
    var grid_rows = std.ArrayList(std.ArrayList(u8)).init(allocator);

    var occupied: usize = 0;
    var row: usize = 0;
    while (row < nrows) : (row += 1) {
        var grid_row = std.ArrayList(u8).init(allocator);
        var col: usize = 0;
        while (col < ncols) : (col += 1) {
            // const cell = cells[row][col];
            const cell = cells.*[row][col];
            const res = try neighbors2(allocator, cells, row, col, false);
            // log.debug("[{},{}] found_empty? {} n_occupied {} empty? {} floor? {} occupied? {}", .{row, col, res.found_empty, res.n_occupied, isEmpty(cell), isFloor(cell), isOccupied(cell)});

            if (isFloor(cell)) {
                try grid_row.append(46);
            } else if (isEmpty(cell) and res.found_empty and res.n_occupied == 0) {
                try grid_row.append(35);
                occupied += 1;
            } else if (isOccupied(cell) and res.n_occupied >= 5) {
                try grid_row.append(76);
            } else if (isEmpty(cell)) {
                try grid_row.append(76);
            } else if (isOccupied(cell) and res.n_occupied < 5) {
                try grid_row.append(35);
                occupied += 1;
            } else {
                try grid_row.append(99);
            }
        }
        try grid_rows.append(grid_row);
    }

    for (grid_rows.items) |gridrow, irow| {
        cells.*[irow] = gridrow.items;
    }
    return Grid2{ .cells = cells, .occupied = occupied };
}

const NeighborResult = struct {
    found_empty: bool,
    n_occupied: usize,
};

fn neighbors2(allocator: *mem.Allocator, cells: *[][]const u8, row: usize, col: usize, debug: bool) !NeighborResult {
    const nrows = cells.*.len;
    const ncols: usize = cells.*[0].len;

    var n_occupied: usize = 0; // cells occupied by neighbors
    var found_empty = false; // was any empty seat found in the neighborhood?

    var map = std.StringHashMap(Direction).init(allocator);
    try map.put("top-left", Direction{ .x = -1, .y = -1 });
    try map.put("top", Direction{ .x = 0, .y = -1 });
    try map.put("top-right", Direction{ .x = 1, .y = -1 });
    try map.put("left", Direction{ .x = -1, .y = 0 });
    try map.put("right", Direction{ .x = 1, .y = 0 });
    try map.put("bottom-left", Direction{ .x = -1, .y = 1 });
    try map.put("bottom", Direction{ .x = 0, .y = 1 });
    try map.put("bottom-right", Direction{ .x = 1, .y = 1 });

    var i: isize = 1;
    const i_max = std.math.max(nrows, ncols) - 1;

    // while (!found_empty and i < i_max) : (i += 1) {
    while (i < i_max) : (i += 1) {
        if (debug) {
            log.debug("[{},{}] NEIGHBORHOOD SIZE {} in {} directions", .{ row, col, i, map.count() });
        }
        var it = map.iterator();
        while (it.next()) |e| {
            const r = @intCast(isize, row) + e.value.y * i;
            const c = @intCast(isize, col) + e.value.x * i;
            if (r == row and c == col) {
                continue; // a cell is not neighbor of itself
            } else if (r < 0 or r >= nrows) {
                continue;
            } else if (c < 0 or c >= ncols) {
                continue;
            }
            const ur = @intCast(usize, r);
            const uc = @intCast(usize, c);
            std.debug.assert(ur == r);
            std.debug.assert(uc == c);
            const cell = cells.*[ur][uc];

            if (debug) {
                log.debug("[{},{}] neighbor at [{},{}] is {}", .{ row, col, r, c, cell });
            }

            if (isFloor(cell)) {
                continue;
            } else if (isOccupied(cell)) {
                n_occupied += 1;
                _ = map.remove(e.key);
            } else if (isEmpty(cell)) {
                found_empty = true;
                _ = map.remove(e.key);
            } else unreachable;
        }
    }
    if (debug) {
        log.debug("[{},{}] isEmpty? {} found_empty? {} n_occupied {}", .{ row, col, isEmpty(cells.*[row][col]), found_empty, n_occupied });
    }
    return NeighborResult{ .found_empty = found_empty, .n_occupied = n_occupied };
}

fn printGrid(grid: Grid2, n_step: usize) void {
    var i: usize = 0;
    const nrows = grid.cells.len;
    log.debug("GRID AFTER {} STEPS", .{n_step});
    while (i < nrows) : (i += 1) {
        log.debug("i {} {}", .{ i, grid.cells.*[i] });
    }
    log.debug("occupied cells: {}\n", .{grid.occupied});
}

fn answer2(allocator: *mem.Allocator) !usize {
    var lines = try utils.splitByte(allocator, input, '\n');

    // for testing /////////////////////////////////////////////////////////////
    // const row: usize = 3;
    // const col: usize = 2;
    // const res = try neighbors2(allocator, &lines, row, col, true);
    // return res.n_occupied;
    ////////////////////////////////////////////////////////////////////////////

    var n_step: usize = 1;
    var grid = try step2(allocator, &lines);
    // printGrid(grid, n_step);

    n_step += 1;
    var occupied_pre: usize = 0;
    while (grid.occupied != occupied_pre) : (n_step += 1) {
        occupied_pre = grid.occupied;
        grid = try step2(allocator, grid.cells);
        // printGrid(grid, n_step);
    }
    log.debug("Equilibrium with {} occupied cells, after {} steps", .{ grid.occupied, n_step - 2 });
    return grid.occupied;
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
    log.info("Day 11 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Day 11, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 37), a);
    testing.expectEqual(@intCast(usize, 2108), a);
}

test "Day 11, part 2" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer2(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 26), a);
    testing.expectEqual(@intCast(usize, 1897), a);
}
