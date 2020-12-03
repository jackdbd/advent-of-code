const std = @import("std");
const log = std.log;
const day1 = @import("01.zig");
const day2 = @import("02.zig");
const day3 = @import("03.zig");

pub fn main() !void {
    log.info("Advent of Code 2020", .{});
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    log.info("Day 1", .{});
    try day1.main();
    
    log.info("Day 2", .{});
    try day2.main();

    log.info("Day 3", .{});
    try day3.main();

    const t1 = timer.lap();
    const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    log.info("All problems took {d:.2} seconds in total", .{elapsed_s});
}
