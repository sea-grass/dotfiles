const std = @import("std");
const mem = std.mem;
const log = std.log.scoped(.cmd);

pub const std_options: std.Options = .{
    .log_level = .debug,
    .logFn = struct {
        fn logFn(
            comptime message_level: std.log.Level,
            comptime scope: @TypeOf(.enum_literal),
            comptime format: []const u8,
            args: anytype,
        ) void {
            const scoped = switch (scope) {
                .default => format,
                .section => "\n# Install dots section " ++ format,
                .link, .download, .direxists => "> " ++ @tagName(scope) ++ " " ++ format,
                else => @tagName(scope) ++ " " ++ format,
            };

            const tmpl = switch (message_level) {
                .info => scoped ++ "\n",
                else => comptime message_level.asText() ++ " " ++ scoped ++ "\n",
            };

            std.io.getStdOut().writer().print(tmpl, args) catch {};
        }
    }.logFn,
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
            log.err("Invalid command [{s}]", .{command});
            return error.InvalidCommand;
        }
    }
};

const Command = enum {
    direxists,
    link,
    download,
    apt_install,
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

    fn _link(allocator: mem.Allocator, args: []const u8) !void {
        const line = try FilterIterator.Entry.firstLine(.{ .realpath = args, .name = undefined }, allocator);
        defer allocator.free(line);

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

            // The target is relative to this link file
            var parent_dir = try std.fs.openDirAbsolute(std.fs.path.dirname(args).?, .{});
            defer parent_dir.close();

            const target_owned: []const u8 = try parent_dir.realpathAlloc(allocator, target);
            errdefer allocator.free(target_owned);

            break :input .{ target_owned, link_name_owned };
        };
        defer allocator.free(target_owned);
        defer allocator.free(link_name_owned);

        try Action.link(target_owned, link_name_owned);
    }

    fn _download(allocator: mem.Allocator, args: []const u8) !void {
        const line = try FilterIterator.Entry.firstLine(.{ .name = undefined, .realpath = args }, allocator);
        defer allocator.free(line);

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

        try Action.download(allocator, url, destination_path_owned);
    }

    fn _installDotsSection(allocator: mem.Allocator, args: []const u8) !void {
        std.log.scoped(.section).info("{s}", .{std.fs.path.basename(args)});
        var it: FilterIterator = try .all(allocator, args);

        const apt_is_available = try isAptGetPresent();
        // We print unavailability of apt only if a dots section declares apt dependencies
        var apt_message_printed = false;

        while (try it.next()) |entry| {
            const command: Command = command: {
                if (matchExt(entry.name, "dir", false)) break :command .direxists;
                if (matchExt(entry.name, "link", false)) break :command .link;
                if (matchExt(entry.name, "download", false)) break :command .download;
                if (matchExt(entry.name, "apt", false)) {
                    if (apt_is_available) {
                        break :command .apt_install;
                    } else {
                        if (!apt_message_printed) {
                            log.warn("apt-get is not present on this system. Not installing dependencies for [{s}]", .{
                                std.fs.path.basename(args),
                            });
                            apt_message_printed = true;
                        }
                        continue;
                    }
                }

                continue;
            };

            try command.dispatch(allocator, entry.realpath);
        }
    }

    fn _aptInstall(allocator: mem.Allocator, args: []const u8) !void {
        const content = try FilterIterator.Entry.content(.{ .realpath = args, .name = undefined }, allocator);
        defer allocator.free(content);

        var it = std.mem.splitScalar(u8, content, '\n');
        while (it.next()) |line| {
            if (line.len == 0) continue;

            try Action.aptInstall(allocator, line);
        }
    }

    fn _installDots(allocator: mem.Allocator, dots_path: []const u8) !void {
        var it: FilterIterator = try .all(allocator, dots_path);
        defer it.deinit();

        while (try it.next()) |entry| {
            try Command.install_dots_section.dispatch(allocator, entry.realpath);
        }
    }

    pub fn dispatch(command: Command, allocator: mem.Allocator, args: []const u8) anyerror!void {
        switch (command) {
            .direxists => try Action.direxists(args),
            .link => try _link(allocator, args),
            .download => try _download(allocator, args),
            .apt_install => try Action.aptInstall(allocator, args),
            .install_dots => try _installDots(allocator, args),
            .install_dots_section => try _installDotsSection(allocator, args),
        }
    }
};

const FilterIterator = struct {
    arena: std.heap.ArenaAllocator,
    path: []const u8,
    /// Once initialized, this root_dir is never reassigned.
    root_dir: std.fs.Dir,
    it: std.fs.Dir.Iterator,
    /// state enum supports automatic deinit for the iterator.
    /// The caller may assume that if the iterator returned null,
    /// it has performed its cleanup already.
    state: enum { init, done, deinit, fatal, fatal_deinit },
    /// The match strategy determines which files to pass through.
    match: Match,

    pub const Entry = struct {
        name: []const u8,
        realpath: []const u8,

        /// Caller owns the returned memory.
        pub fn content(entry: Entry, allocator: mem.Allocator) ![]const u8 {
            return try std.fs.cwd().readFileAlloc(
                allocator,
                entry.realpath,
                std.math.maxInt(usize),
            );
        }

        pub fn firstLine(entry: Entry, allocator: mem.Allocator) ![]const u8 {
            var file = try std.fs.openFileAbsolute(entry.realpath, .{});
            defer file.close();

            const line: []const u8 = try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(usize)) orelse return error.SomeError;
            errdefer allocator.free(line);

            return line;
        }
    };

    pub const Match = union(enum) {
        /// Pass through all files
        all: void,
        /// Pass through only files which match the extension
        match_ext: struct {
            /// If true, Will also pass through files with the name `.ext`
            /// If false, will only pass through files that match the regex `(.+)\.ext`
            allow_exact: bool,
            ext: []const u8,
        },
    };

    pub fn all(allocator: mem.Allocator, abs_path: []const u8) !FilterIterator {
        return try init(allocator, abs_path, .all);
    }

    pub fn ext(allocator: mem.Allocator, abs_path: []const u8, file_ext: []const u8) !FilterIterator {
        return try init(allocator, abs_path, .{
            .match_ext = .{
                .allow_exact = false,
                .ext = file_ext,
            },
        });
    }

    pub fn init(allocator: mem.Allocator, abs_path: []const u8, match: Match) !FilterIterator {
        var dir = try std.fs.openDirAbsolute(abs_path, .{ .iterate = true });
        errdefer dir.close();

        return .{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .path = abs_path,
            .root_dir = dir,
            .it = dir.iterate(),
            .state = .init,
            .match = match,
        };
    }

    pub fn deinit(it: *FilterIterator) void {
        switch (it.state) {
            .init, .done => {
                it.root_dir.close();
                it.arena.deinit();
                it.state = .deinit;
            },
            .fatal => {
                it.root_dir.close();
                it.arena.deinit();
                it.state = .fatal_deinit;
            },
            .deinit, .fatal_deinit => {},
        }
    }

    /// Retrieve the next entry, updating the internal state as necessary.
    /// Performs assertions depending on internal state to validate
    /// correct usage.
    pub fn next(it: *FilterIterator) !?Entry {
        switch (it.state) {
            .init => {},
            .done, .deinit, .fatal, .fatal_deinit => unreachable,
        }

        return it._next() catch |err| {
            it.state = .fatal;
            it.deinit();
            return err;
        } orelse {
            it.state = .done;
            it.deinit();
            return null;
        };
    }

    /// Internal function to return the next entry.
    fn _next(it: *FilterIterator) !?Entry {
        const entry = try it.it.next() orelse return null;

        if (!it.matches(entry)) return it._next();

        return .{
            .name = try it.arena.allocator().dupe(u8, entry.name),
            .realpath = try it.root_dir.realpathAlloc(it.arena.allocator(), entry.name),
        };
    }

    fn matches(it: *FilterIterator, entry: std.fs.Dir.Entry) bool {
        return switch (it.match) {
            .all => true,
            .match_ext => |match_ext| matchExt(
                entry.name,
                match_ext.ext,
                match_ext.allow_exact,
            ),
        };
    }
};

fn matchExt(file_path: []const u8, ext: []const u8, allow_exact: bool) bool {
    var ext_with_dot_buf: [std.fs.max_path_bytes]u8 = undefined;
    ext_with_dot_buf[0] = '.';
    @memcpy(ext_with_dot_buf[1 .. 1 + ext.len], ext);
    const ext_with_dot: []const u8 = ext_with_dot_buf[0 .. 1 + ext.len];

    return switch (std.math.order(file_path.len, ext_with_dot.len)) {
        .lt => false,
        .eq => allow_exact and mem.eql(u8, file_path, ext_with_dot),
        .gt => mem.endsWith(u8, file_path, ext_with_dot),
    };
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

const Action = struct {
    fn aptInstall(allocator: mem.Allocator, package: []const u8) !void {
        var p = std.process.Child.init(&.{ "bash", "apt_install.sh", package }, allocator);
        p.cwd_dir = std.fs.cwd();
        const term = try p.spawnAndWait();
        _ = term;
    }

    fn direxists(abs_path: []const u8) !void {
        std.log.scoped(.direxists).info("{s}", .{abs_path});
        std.fs.makeDirAbsolute(abs_path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
    }

    fn link(target: []const u8, link_name: []const u8) !void {
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

    fn download(allocator: mem.Allocator, url: []const u8, destination_file: []const u8) !void {
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
};
