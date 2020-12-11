const std = @import("std");
const log = std.log;
const utils = @import("utils.zig");

const module_names = [_][]const u8{
    "01.zig", "02.zig", "03.zig", "04.zig", "05.zig",
    "06.zig", "07.zig", "08.zig", "09.zig", "10.zig",
    "11.zig",
};

pub fn main() !void {
    log.info("Advent of Code 2020", .{});
    var timer = try std.time.Timer.start();
    const t0 = timer.lap();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // This for loop needs to be unrolled because @import requires a comptime
    // parameter, hence module_name must be known at compile time. Without the
    // `inline` keyword `module_name` would only known at runtime, and @import
    // would fail with error: unable to evaluate constant expression
    // https://ziglang.org/documentation/0.7.0/#toc-inline-for
    // https://stackoverflow.com/a/65171200/3036129
    inline for (module_names) |module_name, day| {
        const module = @import(module_name);
        log.info("Day {}", .{day});
        try module.main();
    }

    const t1 = timer.lap();
    const elapsed_ms = @intToFloat(f64, t1 - t0) / std.time.ns_per_ms;
    log.info("All problems took {d:.2} ms in total", .{elapsed_ms});
    // const elapsed_s = @intToFloat(f64, t1 - t0) / std.time.ns_per_s;
    // log.info("All problems took {d:.2} s in total", .{elapsed_s});
}
