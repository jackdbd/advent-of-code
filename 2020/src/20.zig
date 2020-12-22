const std = @import("std");
// const input = @embedFile("inputs/20_sample.txt");
const input = @embedFile("inputs/20.txt");
const fmt = std.fmt;
const heap = std.heap;
const log = std.log;
const mem = std.mem;

const Edge = enum(u8) {
    top,
    right,
    bottom,
    left,
};

const Tile = struct {
    id: usize,
    top: [10]bool,
    right: [10]bool,
    bottom: [10]bool,
    left: [10]bool,
    top_used: bool,
    right_used: bool,
    bottom_used: bool,
    left_used: bool,
    neighbors: std.ArrayList(*Tile),

    const Self = @This();

    // see modify an array here: https://ziglang.org/documentation/master/#Arrays
    fn top(string: []const u8, i_start: usize) [10]bool {
        var arr = init: {
            var arr_init: [10]bool = undefined;
            for (arr_init) |*b, i| {
                b.* = string[i_start + i] == '#';
            }
            break :init arr_init;
        };
        return arr;
    }

    fn right(string: []const u8, i_start: usize) [10]bool {
        var arr = init: {
            var arr_init: [10]bool = undefined;
            for (arr_init) |*b, i| {
                b.* = string[i_start + (11 * i) + 9] == '#';
            }
            break :init arr_init;
        };
        return arr;
    }

    fn bottom(string: []const u8, i_start: usize) [10]bool {
        var arr = init: {
            var arr_init: [10]bool = undefined;
            for (arr_init) |*b, i| {
                b.* = string[i_start + 99 + i] == '#';
            }
            break :init arr_init;
        };
        return arr;
    }

    fn left(string: []const u8, i_start: usize) [10]bool {
        var arr = init: {
            var arr_init: [10]bool = undefined;
            for (arr_init) |*b, i| {
                b.* = string[i_start + (11 * i)] == '#';
            }
            break :init arr_init;
        };
        return arr;
    }

    fn fromString(string: []const u8, allocator: *mem.Allocator) !Self {
        const i_space = mem.indexOf(u8, string, " ").?;
        const i_colon = mem.indexOf(u8, string, ":").?;
        const i_start = i_colon + 2;
        return Self{
            .id = try fmt.parseInt(usize, string[i_space + 1 .. i_colon], 10),
            .top = Tile.top(string, i_start),
            .right = Tile.right(string, i_start),
            .bottom = Tile.bottom(string, i_start),
            .left = Tile.left(string, i_start),
            .top_used = false,
            .right_used = false,
            .bottom_used = false,
            .left_used = false,
            .neighbors = std.ArrayList(*Tile).init(allocator),
        };
    }

    /// Find out whether one edge of this tile matches another edge of another tile.
    /// When the 2 tiles match up, update the neighbors and their used edges.
    fn matches(self: *Tile, other: *Tile, this_edge: Edge, other_edge: Edge) !bool {
        var a_edge: [10]bool = undefined;
        var b_edge: [10]bool = undefined;
        var a_used: *bool = undefined;
        var b_used: *bool = undefined;

        if (this_edge == Edge.top) {
            a_edge = self.top;
            a_used = &self.top_used;
        } else if (this_edge == Edge.right) {
            a_edge = self.right;
            a_used = &self.right_used;
        } else if (this_edge == Edge.bottom) {
            a_edge = self.bottom;
            a_used = &self.bottom_used;
        } else if (this_edge == Edge.left) {
            a_edge = self.left;
            a_used = &self.left_used;
        } else unreachable;

        if (other_edge == Edge.top) {
            b_edge = other.top;
            b_used = &other.top_used;
        } else if (other_edge == Edge.right) {
            b_edge = other.right;
            b_used = &other.right_used;
        } else if (other_edge == Edge.bottom) {
            b_edge = other.bottom;
            b_used = &other.bottom_used;
        } else if (other_edge == Edge.left) {
            b_edge = other.left;
            b_used = &other.left_used;
        } else unreachable;

        var match = true;
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            if (a_edge[i] != b_edge[i]) {
                match = false;
                break;
            }
        }

        // tiles can be flipped
        if (!match) {
            match = true;
            var i_flipped: usize = 0;
            while (i_flipped < 10) : (i_flipped += 1) {
                if (a_edge[i_flipped] != b_edge[9 - i_flipped]) {
                    match = false;
                    break;
                }
            }
        }

        if (!match) {
            return false;
        } else {
            try self.neighbors.append(other); // memory leak?
            // errdefer self.neighbors.deinit();
            try other.neighbors.append(self); // memory leak?
            // errdefer other.neighbors.deinit();
            a_used.* = true;
            b_used.* = true;
            return true;
        }
    }
};

fn answer1(allocator: *mem.Allocator) !usize {
    var tiles = std.ArrayList(Tile).init(allocator);
    var strings = mem.split(input, "\n\n");
    while (strings.next()) |string| {
        var tile = try Tile.fromString(string, allocator);
        try tiles.append(tile);
    }

    // Iterate over the slice by reference by specifying that the capture value is a pointer.
    // https://ziglang.org/documentation/master/#for
    for (tiles.items) |*tile_a| {
        for (tiles.items) |*tile_b| {
            if (tile_a.id == tile_b.id) continue;

            if (!tile_a.top_used and !tile_b.top_used and try tile_a.matches(tile_b, Edge.top, Edge.top)) {
                // keep these comments because zig fmt wants to put all of these else ifs on a single line
            } else if (!tile_a.top_used and !tile_b.right_used and try tile_a.matches(tile_b, Edge.top, Edge.right)) {
                //
            } else if (!tile_a.top_used and !tile_b.bottom_used and try tile_a.matches(tile_b, Edge.top, Edge.bottom)) {
                //
            } else if (!tile_a.top_used and !tile_b.left_used and try tile_a.matches(tile_b, Edge.top, Edge.left)) {
                //
            } else if (!tile_a.right_used and !tile_b.top_used and try tile_a.matches(tile_b, Edge.right, Edge.top)) {
                //
            } else if (!tile_a.right_used and !tile_b.right_used and try tile_a.matches(tile_b, Edge.right, Edge.right)) {
                //
            } else if (!tile_a.right_used and !tile_b.bottom_used and try tile_a.matches(tile_b, Edge.right, Edge.bottom)) {
                //
            } else if (!tile_a.right_used and !tile_b.left_used and try tile_a.matches(tile_b, Edge.right, Edge.left)) {
                //
            } else if (!tile_a.bottom_used and !tile_b.top_used and try tile_a.matches(tile_b, Edge.bottom, Edge.top)) {
                //
            } else if (!tile_a.bottom_used and !tile_b.right_used and try tile_a.matches(tile_b, Edge.bottom, Edge.right)) {
                //
            } else if (!tile_a.bottom_used and !tile_b.bottom_used and try tile_a.matches(tile_b, Edge.bottom, Edge.bottom)) {
                //
            } else if (!tile_a.bottom_used and !tile_b.left_used and try tile_a.matches(tile_b, Edge.bottom, Edge.left)) {
                //
            } else if (!tile_a.left_used and !tile_b.top_used and try tile_a.matches(tile_b, Edge.left, Edge.top)) {
                //
            } else if (!tile_a.left_used and !tile_b.right_used and try tile_a.matches(tile_b, Edge.left, Edge.right)) {
                //
            } else if (!tile_a.left_used and !tile_b.bottom_used and try tile_a.matches(tile_b, Edge.left, Edge.bottom)) {
                //
            } else if (!tile_a.left_used and !tile_b.left_used and try tile_a.matches(tile_b, Edge.left, Edge.left)) {}
        }
    }

    var result: usize = 1;
    for (tiles.items) |tile| {
        if (tile.neighbors.items.len == 2) result *= tile.id;
    }
    return result;
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
    log.info("Day 20 took {d:.2} seconds", .{elapsed_s});
}

const testing = std.testing;

test "Tile.top()" {
    const s = "Tile 2311: ..##.#..#. ##..#..... #...##..#. ####.#...# ##.##.###. ##...#.### .#.#.#..## ..#....#.. ###...#.#. ..###..###";
    const top = Tile.top(s, 11);
    testing.expectEqual(false, top[0]);
    testing.expectEqual(false, top[1]);
    testing.expectEqual(true, top[2]);
    testing.expectEqual(true, top[3]);
    testing.expectEqual(false, top[4]);
    testing.expectEqual(true, top[5]);
    testing.expectEqual(false, top[6]);
    testing.expectEqual(false, top[7]);
    testing.expectEqual(true, top[8]);
    testing.expectEqual(false, top[9]);
}

test "Tile.fromString()" {
    const s = "Tile 2311: ..##.#..#. ##..#..... #...##..#. ####.#...# ##.##.###. ##...#.### .#.#.#..## ..#....#.. ###...#.#. ..###..###";
    const tile = try Tile.fromString(s, testing.allocator);
    testing.expectEqual(@intCast(usize, 2311), tile.id);
    testing.expectEqual(false, tile.top_used);
    testing.expectEqual(false, tile.right_used);
    testing.expectEqual(false, tile.bottom_used);
    testing.expectEqual(false, tile.left_used);
    testing.expectEqual(tile.top[0], tile.left[0]);
    testing.expectEqual(tile.top[9], tile.right[0]);
    testing.expectEqual(tile.bottom[0], tile.left[9]);
    testing.expectEqual(tile.bottom[9], tile.right[9]);
    testing.expectEqual(@intCast(usize, 0), tile.neighbors.items.len);
}

test "tile_a.matches(tile_b)" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const s_2311 = "Tile 2311: ..##.#..#. ##..#..... #...##..#. ####.#...# ##.##.###. ##...#.### .#.#.#..## ..#....#.. ###...#.#. ..###..###";
    var tile_a = try Tile.fromString(s_2311, &arena.allocator);
    const s_3079 = "Tile 3079: #.#.#####. .#..###### ..#....... ######.... ####.#..#. .#...#.##. #.#####.## ..#.###... ..#....... ..#.###...";
    var tile_b = try Tile.fromString(s_3079, &arena.allocator);
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.top, Edge.top));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.top, Edge.right));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.top, Edge.bottom));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.top, Edge.left));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.right, Edge.top));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.right, Edge.right));
    testing.expectEqual(true, try tile_a.matches(&tile_b, Edge.right, Edge.left));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.right, Edge.bottom));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.bottom, Edge.top));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.bottom, Edge.right));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.bottom, Edge.bottom));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.bottom, Edge.left));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.left, Edge.top));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.left, Edge.right));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.left, Edge.bottom));
    testing.expectEqual(false, try tile_a.matches(&tile_b, Edge.left, Edge.left));
}

test "Day 20, part 1" {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const a = try answer1(&arena.allocator);
    // testing.expectEqual(@intCast(usize, 20899048083289), a);
    testing.expectEqual(@intCast(usize, 68781323018729), a);
}

// test "Day 20, part 2" {
//     var arena = heap.ArenaAllocator.init(heap.page_allocator);
//     defer arena.deinit();
//     const a = try answer2(&arena.allocator);
//     // testing.expectEqual(@intCast(usize, 8), a);
//     testing.expectEqual(@intCast(usize, 1235), a);
// }
