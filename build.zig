const debug = std.debug;
const mem = std.mem;
const std = @import("std");
const WriteFile = std.Build.Step.WriteFile;

fn writeDots(dot_out: *std.Build.Step.WriteFile) void {
    nvim.dots(dot_out);
}

pub fn build(b: *std.Build) void {
    const bs = .{
        .dots = b.step("dots", "Write dotfiles to dot_out"),
    };

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    _ = target;
    _ = optimize;

    const wf = b.addWriteFiles();

    writeDots(wf);

    const x = b.addInstallDirectory(
        .{
            .source_dir = wf.getDirectory(),
            .install_subdir = "dot_out",
            .install_dir = .prefix,
        },
    );

    bs.dots.dependOn(&wf.step);
    bs.dots.dependOn(&x.step);
}

const nvim = struct {
    pub fn dots(wf: *WriteFile) void {
        write(wf, @"init.lua", ".config/nvim/init.lua");
        write(wf, @"locals.lua", ".config/nvim/locals.lua");
    }

    pub const @"init.lua" =
        \\
    ;

    pub const @"locals.lua" =
        \\-- Machine-specific config goes here.
        \\-- Note that changes here will not be committed to
        \\-- version control.
    ;
};

fn write(wf: *WriteFile, bytes: []const u8, sub_path: []const u8) void {
    debug.assert(mem.startsWith(u8, sub_path, ".config/"));
    _ = wf.add(sub_path, bytes);
}
