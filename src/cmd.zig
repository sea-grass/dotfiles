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

    const app: App = .{ .allocator = allocator, .root = &root };
    try app.run(command, rest_args.items);
}

const App = struct {
    root: *std.fs.Dir,
    allocator: mem.Allocator,

    pub fn run(app: *const App, command: []const u8, args: []const u8) !void {
        if (Command.parse(command)) |cmd| {
            try cmd.dispatch(app.allocator, args);
        } else {
            std.log.err("Invalid command [{s}]", .{command});
            return error.InvalidCommand;
        }
    }
};

const Command = enum {
    direxists,
    link,
    download,
    apt_install,
    @"all:direxists",
    @"all:link",
    @"all:download",
    @"all:apt_install",
    install_dots_section,
    install_dots,

    pub fn parse(command_str: []const u8) ?Command {
        inline for (std.meta.fields(Command)) |field| {
            if (std.mem.eql(u8, command_str, field.name)) {
                return @field(Command, field.name);
            }
        }

        return null;
    }

    pub fn dispatch(command: Command, allocator: mem.Allocator, args: []const u8) anyerror!void {
        switch (command) {
            .direxists => try direxists(args),
            .link => {
                var it = std.mem.splitScalar(u8, args, ' ');
                const target = it.next() orelse return error.MissingLinkArgument;
                const link_name = it.next() orelse return error.MissingLinkArgument;

                try link(target, link_name);
            },
            .download => {
                var it = std.mem.splitScalar(u8, args, ' ');
                const url = it.next() orelse return error.MissingLinkArgument;
                const destination_file = it.next() orelse return error.MissingLinkArgument;

                try download(allocator, url, destination_file);
            },
            .apt_install => try aptInstall(allocator, args),
            .@"all:direxists" => try allDirExists(allocator, args),
            .@"all:link" => try allLink(allocator, args),
            .@"all:download" => try allDownload(allocator, args),
            .@"all:apt_install" => try allAptInstall(allocator, args),
            .install_dots => try installDots(allocator, args),
            .install_dots_section => {
                try Command.@"all:direxists".dispatch(allocator, args);
                try Command.@"all:link".dispatch(allocator, args);
                try Command.@"all:download".dispatch(allocator, args);
                try Command.@"all:apt_install".dispatch(allocator, args);
            },
        }
    }
};

fn installDots(allocator: mem.Allocator, dots_path: []const u8) !void {
    var dir = try std.fs.openDirAbsolute(dots_path, .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        const section_path = try dir.realpathAlloc(allocator, entry.name);
        defer allocator.free(section_path);

        try Command.install_dots_section.dispatch(allocator, section_path);
    }
}

fn isAptGetPresent() !bool {
    var buf: [4096]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);

    const res = try std.process.Child.run(.{
        .allocator = fba.allocator(),
        .argv = &.{ "type", "apt-get", "1>/dev/null", "2>&1" },
    });

    return switch (res.term) {
        .Exited => |exit_code| switch (exit_code) {
            0 => true,
            else => false,
        },
        else => error.UnexpectedCheckAptGetResult,
    };
}

fn allAptInstall(allocator: mem.Allocator, section_path: []const u8) !void {
    const ext = ".apt";

    if (!try isAptGetPresent()) {
        std.log.info("apt-get is not present on this system. Not installing dependencies for [{s}]", .{section_path});
        return;
    }

    var dir = try std.fs.openDirAbsolute(section_path, .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (!std.mem.endsWith(u8, entry.name, ext)) continue;
        if (entry.name.len == ext.len) continue;

        const content: []const u8 = try dir.readFileAlloc(allocator, entry.name, std.math.maxInt(usize));
        defer allocator.free(content);

        var line_it = std.mem.splitScalar(u8, content, '\n');
        while (line_it.next()) |line| {
            if (line.len == 0) continue;

            try aptInstall(allocator, line);
        }
    }
}

fn allDownload(allocator: mem.Allocator, section_path: []const u8) !void {
    const ext = ".download";

    var dir = try std.fs.openDirAbsolute(section_path, .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (!std.mem.endsWith(u8, entry.name, ext)) continue;
        if (entry.name.len == ext.len) continue;

        const content: []const u8 = try dir.readFileAlloc(allocator, entry.name, std.math.maxInt(usize));
        defer allocator.free(content);

        const line = if (std.mem.indexOfScalar(u8, content, '\n')) |end|
            content[0..end]
        else
            content;

        const url, const destination_path_owned = input: {
            const div = std.mem.indexOf(u8, line, "->") orelse return error.InvalidDownloadContent;

            const url = line[0..div];
            if (url.len == 0) return error.InvalidDownloadContent;

            const destination_path = line[div + "->".len ..];
            if (!(destination_path.len > 2 and std.mem.startsWith(u8, destination_path, "~/"))) return error.InvalidDownloadContent;

            const home: []const u8 = try std.process.getEnvVarOwned(allocator, "HOME");
            defer allocator.free(home);

            const destination_path_owned = try std.fs.path.join(allocator, &.{ home, destination_path[2..] });
            errdefer allocator.free(destination_path_owned);

            break :input .{ url, destination_path_owned };
        };
        defer allocator.free(destination_path_owned);

        try download(allocator, url, destination_path_owned);
    }
}

fn allLink(allocator: mem.Allocator, section_path: []const u8) !void {
    const ext = ".link";

    var dir = try std.fs.openDirAbsolute(section_path, .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (!std.mem.endsWith(u8, entry.name, ext)) continue;
        if (entry.name.len == ext.len) continue;

        const content: []const u8 = try dir.readFileAlloc(allocator, entry.name, std.math.maxInt(usize));
        defer allocator.free(content);

        const line = if (std.mem.indexOfScalar(u8, content, '\n')) |end|
            content[0..end]
        else
            content;

        const target_owned, const link_name_owned = input: {
            const div = std.mem.indexOf(u8, line, "->") orelse return error.InvalidLinkContent;

            const target = line[0..div];
            if (target.len == 0) return error.InvalidLinkContent;

            const link_name = line[div + "->".len ..];
            if (!(link_name.len > 2 and std.mem.startsWith(u8, link_name, "~/"))) return error.InvalidLinkContent;

            const home: []const u8 = try std.process.getEnvVarOwned(allocator, "HOME");
            defer allocator.free(home);

            const link_name_owned: []const u8 = try std.fs.path.join(allocator, &.{ home, link_name[2..] });
            errdefer allocator.free(link_name_owned);

            const target_owned = try dir.realpathAlloc(allocator, target);
            errdefer allocator.free(target_owned);

            break :input .{ target_owned, link_name_owned };
        };
        defer allocator.free(target_owned);
        defer allocator.free(link_name_owned);

        try link(target_owned, link_name_owned);
    }
}

fn allDirExists(allocator: mem.Allocator, section_path: []const u8) !void {
    var dir = try std.fs.openDirAbsolute(section_path, .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.name.len > 4 and std.mem.endsWith(u8, entry.name, ".dir")) {
            var buf: [std.fs.max_path_bytes]u8 = undefined;
            const content = try dir.readFile(entry.name, &buf);
            const line = if (std.mem.indexOfScalar(u8, content, '\n')) |end|
                content[0..end]
            else
                content;

            if (line.len > 2 and std.mem.startsWith(u8, line, "~/")) {
                const home: []const u8 = try std.process.getEnvVarOwned(allocator, "HOME");
                defer allocator.free(home);

                const path: []const u8 = try std.fs.path.join(allocator, &.{ home, line[2..] });
                defer allocator.free(path);

                try direxists(path);
            } else {
                return error.InvalidDirexistsContent;
            }
        }
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
    std.log.info("link \"{s}\" \"{s}\"", .{ target, link_name });
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
