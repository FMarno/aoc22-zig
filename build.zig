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

    var build_info = BuildInfo{ .builder = b, .target = target, .mode = mode };
    add_day(&build_info, "one");
    add_day(&build_info, "two");
    add_day(&build_info, "three");
    add_day(&build_info, "four");
}

const BuildInfo = struct {
    builder: *std.build.Builder,
    target: std.zig.CrossTarget,
    mode: std.builtin.Mode,
};

fn add_day(build_info: *BuildInfo, comptime name: []const u8) void {
    const exe = build_info.builder.addExecutable(name, "src/" ++ name ++ ".zig");
    exe.setTarget(build_info.target);
    exe.setBuildMode(build_info.mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(build_info.builder.getInstallStep());

    const run_step = build_info.builder.step(name, "Run day " ++ name);
    run_step.dependOn(&run_cmd.step);
}
