const debug = std.debug;
const mem = std.mem;
const std = @import("std");
const WriteFile = std.Build.Step.WriteFile;

pub fn build(b: *std.Build) void {
    const bs = .{
        .dots = b.step("dots", "Write dotfiles to dot_out"),
        .cmd = b.step("cmd", "Build cmd"),
    };

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "link-dots",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.getInstallStep().dependOn(&exe.step);

    const run_exe = b.addRunArtifact(exe);
    bs.dots.dependOn(&run_exe.step);

    const cmd = b.addExecutable(.{
        .name = "cmd",
        .root_source_file = b.path("src/cmd.zig"),
        .target = target,
        .optimize = optimize,
    });

    const install_cmd = b.addInstallArtifact(cmd, .{});
    b.getInstallStep().dependOn(&cmd.step);
    bs.cmd.dependOn(&install_cmd.step);
    bs.cmd.dependOn(&cmd.step);
}
