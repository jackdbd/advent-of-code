const std = @import("std");
const fmt = std.fmt;
const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    comptime var day: usize = 1;
    // Formatting: align right and pad zeros to the left, to reach a total of 2 digits
    inline while (day <= 25) : (day += 1) {
        const exe_name = fmt.allocPrint(b.allocator, "day{:0>2}", .{ day }) catch unreachable;
        const run_step_name = fmt.allocPrint(b.allocator, "run-day{:0>2}", .{ day }) catch unreachable;
        const src = fmt.allocPrint(b.allocator, "src/{:0>2}.zig", .{ day }) catch unreachable;
        // const src = fmt.allocPrint(b.allocator, "src/{:0>2}/{:0>2}.zig", .{ day, day }) catch unreachable;
        const desc = fmt.allocPrint(b.allocator, "Run day {} of Advent of Code 2020", .{ day }) catch unreachable;

        // std.debug.print("\nexe_name: {}, run_step_name: {}, src: {}, desc: {}", .{exe_name, run_step_name, src, desc});
        const exe = b.addExecutable(exe_name, src);
        exe.setTarget(target);
        exe.setBuildMode(mode);

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step(run_step_name, desc);
        run_step.dependOn(&run_cmd.step);

        // Day tests
        const test_step_name = try fmt.allocPrint(b.allocator, "test-day{:0>2}", .{ day });
        const test_desc = try fmt.allocPrint(b.allocator, "Run day {} tests", .{ day });
        const day_tests = b.addTest(src);
        day_tests.setBuildMode(mode);
        const test_step = b.step(test_step_name, test_desc);
        test_step.dependOn(&day_tests.step);

        // utils tests
        const utils_tests = b.addTest("src/utils.zig");
        utils_tests.setBuildMode(mode);
        const test_utils_step = b.step("test-utils", "Run utils.zig tests");
        test_utils_step.dependOn(&utils_tests.step);
    }

    const exe_name = "2020";
    const run_step_name = "run";
    const src = "src/main.zig";

    const exe = b.addExecutable(exe_name, src);
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(run_step_name, "Run all Advent of Code 2020 programs");
    run_step.dependOn(&run_cmd.step);

    // TODO: command to run all tests (for now it runs no tests)
    const main_tests = b.addTest(src);
    main_tests.setBuildMode(mode);
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&main_tests.step);
}
