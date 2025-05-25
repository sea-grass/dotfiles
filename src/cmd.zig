const std = @import("std");
const mem = std.mem;

pub const std_options: std.Options = .{
    .log_level = .debug,
};

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
    if (std.mem.eql(u8, "direxists", options.command)) {
        try direxists(options.args);
    } else if (std.mem.eql(u8, "link", options.command)) {
        var it = std.mem.splitScalar(u8, options.args, ' ');
        const target = it.next() orelse return error.MissingLinkArgument;
        const link_name = it.next() orelse return error.MissingLinkArgument;

        try link(target, link_name);
    } else if (std.mem.eql(u8, options.command, "download")) {
        var it = std.mem.splitScalar(u8, options.args, ' ');
        const url = it.next() orelse return error.MissingLinkArgument;
        const destination_file = it.next() orelse return error.MissingLinkArgument;

        try download(allocator, url, destination_file);
    } else if (std.mem.eql(u8, options.command, "apt_install")) {
        try aptInstall(allocator, options.args);
    }
}

fn aptInstall(allocator: mem.Allocator, package: []const u8) !void {
    var p = std.process.Child.init(&.{ "bash", "apt_install.sh", package }, allocator);
    p.cwd_dir = std.fs.cwd();
    const term = try p.spawnAndWait();
    _ = term;
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

fn download(allocator: mem.Allocator, url: []const u8, destination_file: []const u8) !void {
    std.log.info("download {s} -> {s}", .{ url, destination_file });

    if (!std.fs.path.isAbsolute(destination_file)) return error.InvalidDownloadArgument;

    const exists: bool = exists: {
        std.fs.accessAbsolute(destination_file, .{}) catch |err| switch (err) {
            error.FileNotFound => break :exists false,
            else => return err,
        };

        break :exists true;
    };
    if (exists) {
        std.log.debug("download destination file \"{s}\" already exists. Not overwriting.", .{destination_file});
    } else {
        //

        var arena: std.heap.ArenaAllocator = .init(allocator);
        defer arena.deinit();

        var client: std.http.Client = .{ .allocator = arena.allocator() };

        var header_buf: [4096]u8 = undefined;
        var request = try client.open(.GET, try std.Uri.parse(url), .{
            .server_header_buffer = &header_buf,
        });
        defer request.deinit();

        try request.send();
        try request.finish();
        try request.wait();

        switch (request.response.status) {
            .ok => {},
            else => return error.UnexpectedResponseStatus,
        }

        const max_body_size: usize = 10 * 1024 * 1024;
        var body_buf: [max_body_size]u8 = undefined;

        const len = try request.readAll(&body_buf);

        var file = try std.fs.createFileAbsolute(destination_file, .{});
        defer file.close();
        try file.writeAll(body_buf[0..len]);
    }
}
