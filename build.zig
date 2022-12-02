const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const one_exe = b.addExecutable("aoc22", "src/one.zig");
    one_exe.setTarget(target);
    one_exe.setBuildMode(mode);
    one_exe.install();

    const run_cmd = one_exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("one", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const two_exe = b.addExecutable("aoc22", "src/two.zig");
    two_exe.setTarget(target);
    two_exe.setBuildMode(mode);
    two_exe.install();

    const run_cmd_two = two_exe.run();
    run_cmd_two.step.dependOn(b.getInstallStep());

    const run_step_two = b.step("two", "Run the app");
    run_step_two.dependOn(&run_cmd_two.step);
}
