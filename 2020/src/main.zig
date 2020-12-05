const std = @import("std");
const log = std.log;
const utils = @import("utils.zig");
const day1 = @import("01.zig");
const day2 = @import("02.zig");
const day3 = @import("03.zig");
const day4 = @import("04.zig");
const day5 = @import("05.zig");

const module_names = comptime [_][]const u8{
    "01.zig", "02.zig", "03.zig", "04.zig", "05.zig",
};

pub fn main() !void {
    log.info("Advent of Code 2020", .{});
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const last_day = 5;
    const days = try utils.range(u8, &arena.allocator, 1, last_day + 1, 1);
    for (days.items) |day| {
        const module_name = std.fmt.allocPrint(&arena.allocator, "{:0>2}.zig", .{day}) catch unreachable;
        // log.debug("module_name: {}", .{module_name});
        // This would be a runtime import. Is it possible in zig?
        // https://ziglang.org/documentation/0.7.0/#import
        // const module = @import(module_name); // error: unable to evaluate constant expression
        log.info("Day {}", .{day});
        // try module.main();
    }

    for (module_names) |module_name, day| {
        // const module = @import(module_name); // error: unable to evaluate constant expression
        log.info("Day {}", .{day + 1});
        // try module.main();
    }

    log.info("Day 1", .{});
    try day1.main();

    log.info("Day 2", .{});
    try day2.main();

    log.info("Day 3", .{});
    try day3.main();

    log.info("Day 4", .{});
    try day4.main();

    log.info("Day 5", .{});
    try day5.main();

    const t1 = timer.lap();
    const elapsed_ms = @intToFloat(f64, t1 - t0) / std.time.ns_per_ms;
    log.info("All problems took {d:.2} ms in total", .{elapsed_ms});
    // const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    // log.info("All problems took {d:.2} s in total", .{elapsed_s});
}
