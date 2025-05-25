pub fn aptInstall(allocator: mem.Allocator, package: []const u8) !void {
    var p = std.process.Child.init(&.{ "bash", "apt_install.sh", package }, allocator);
    p.cwd_dir = std.fs.cwd();
    const term = try p.spawnAndWait();
    _ = term;
}

pub fn direxists(abs_path: []const u8) !void {
    std.log.scoped(.direxists).info("{s}", .{abs_path});
    std.fs.makeDirAbsolute(abs_path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
}

pub fn link(target: []const u8, link_name: []const u8) !void {
    std.log.scoped(.link).info("{s}", .{link_name});
    if (!std.fs.path.isAbsolute(target)) return error.InvalidLinkArgument;

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

pub fn download(allocator: mem.Allocator, url: []const u8, destination_file: []const u8) !void {
    std.log.scoped(.download).info("{s}", .{url});

    if (!std.fs.path.isAbsolute(destination_file)) return error.InvalidDownloadArgument;

    const exists: bool = exists: {
        std.fs.accessAbsolute(destination_file, .{}) catch |err| switch (err) {
            error.FileNotFound => break :exists false,
            else => return err,
        };

        break :exists true;
    };
    if (exists) {
        std.log.scoped(.download).info("+ already exists {s}", .{destination_file});
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

        std.log.scoped(.download).info("+ saved to {s}", .{destination_file});
    }
}

const std = @import("std");
const mem = std.mem;
