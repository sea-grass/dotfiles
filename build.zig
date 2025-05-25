const debug = std.debug;
const mem = std.mem;
const std = @import("std");
const WriteFile = std.Build.Step.WriteFile;

pub fn build(b: *std.Build) void {
    const bs = .{
        .cmd = b.step("cmd", "Build cmd"),
        .install_dots = b.step("install_dots", "Install all sections in the dots folder."),
    };

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

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

    const install_dots = b.addRunArtifact(cmd);
    install_dots.addArg("install_dots");
    install_dots.addDirectoryArg(b.path("dots"));
    bs.install_dots.dependOn(&install_dots.step);
}
