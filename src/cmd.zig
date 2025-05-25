const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // skip exe name
    _ = args.next();

    const command = args.next() orelse return error.MissingCommand;

    var rest_args: std.ArrayList(u8) = .init(allocator);
    defer rest_args.deinit();

    while (args.next()) |arg| {
        if (rest_args.items.len > 0) try rest_args.writer().writeByte(' ');
        try rest_args.writer().print("{s}", .{arg});
    }

    var root = std.fs.cwd();

    try app(
        allocator,
        .{ .root = &root, .command = command, .args = rest_args.items },
    );
}

const AppOptions = struct {
    root: *std.fs.Dir,
    command: []const u8,
    args: []const u8,
};

pub fn app(allocator: mem.Allocator, options: AppOptions) !void {
    _ = allocator;

    if (std.mem.eql(u8, "direxists", options.command)) {
        try direxists(options.args);
    } else if (std.mem.eql(u8, "link", options.command)) {
        var it = std.mem.splitScalar(u8, options.args, ' ');
        const target = it.next() orelse return error.MissingLinkArgument;
        const link_name = it.next() orelse return error.MissingLinkArgument;

        try link(target, link_name);
    }
}

fn direxists(abs_path: []const u8) !void {
    std.log.info("direxists {s}", .{abs_path});
    std.fs.makeDirAbsolute(abs_path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
}

fn link(target: []const u8, link_name: []const u8) !void {
    if (!std.fs.path.isAbsolute(target)) return error.InvalidLinkArgument;
    std.log.info("link \"{s}\" \"{s}\"", .{ target, link_name });

    const stat = try std.fs.cwd().statFile(target);
    const flags: std.fs.Dir.SymLinkFlags = .{ .is_directory = stat.kind == .directory };
    std.fs.symLinkAbsolute(
        target,
        link_name,
        flags,
    ) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
}
