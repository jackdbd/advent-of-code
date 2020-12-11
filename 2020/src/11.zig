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
    seat: u8,
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
            try list.append(Neighbor{ .col = c, .row = r, .seat = cells.*[r][c] });
        }
    }
    return list;
}

fn willBeOccupied(n_occupied: usize, seat: u8) bool {
    // log.debug("willBeOccupied seat: {}, n_occupied: {}", .{ seat, n_occupied });
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

fn step(allocator: *mem.Allocator, cells: *[][]const u8) !Grid {
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
                // log.debug("row: {}, col: {}, neighbor: {}", .{ row, col, n });
                if (isOccupied(n.seat)) {
                    n_occupied += 1;
                }
            }
            // log.debug("seat {} at row {} col {} has {} neighbors ({} occupied)", .{ seat, row, col, neighbors.items.len, n_occupied });
            // log.debug("row {} y {} willBeOccupied {}", .{ row, y, b });
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

    // var occupied: usize = 0;
    // var r: usize = 0;
    // while (r < nrows) : (r += 1) {
    //     log.debug("Row {}", .{r});
    //     var occupied_row: usize = 0;
    //     var clm: usize = 0;
    //     while (clm < ncols) : (clm += 1) {
    //         // log.debug("{}", .{cells.*[r][clm]});
    //         if (isOccupied(cells.*[r][clm])) {
    //             // occupied += 1;
    //             occupied_row += 1;
    //         }
    //     }
    //     log.debug("occupied_row: {}", .{occupied_row});
    // }

    // log.debug("occupied: {}", .{occupied});
    return Grid{ .cells = cells, .occupied = occupied };
}

fn answer1(allocator: *mem.Allocator) !usize {
    var result: usize = 0;
    var lines = try utils.splitByte(allocator, input, '\n');

    var grid = try step(allocator, &lines);
    var occupied_pre: usize = 0;
    while (grid.occupied != occupied_pre) {
        occupied_pre = grid.occupied;
        grid = try step(allocator, grid.cells);
        // log.debug("occupied before: {}, occupied now: {}", .{ occupied_pre, grid.occupied });
    }
    return grid.occupied;
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

// test "Day 11, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     // testing.expectEqual(@intCast(i32, 8), a);
//     testing.expectEqual(@intCast(i32, 1235), a);
// }
