/// Command represents a CLI-runnable task.
/// The most common task is `install_dots`.
///
/// A Command may also be defined as a CommandFile.
/// A CommandFile has a particular file extension
/// and parsable contents representing the command's arguments.
///
/// The `install_dots_section` command will identify all
/// command files within its directory and invoke
/// the appropriate commands.
pub const Command = enum {
    /// Ensure dir exists
    direxists,
    /// Create symlink at destination pointing to target
    link,
    /// Download url to destination
    download,
    /// Install specific apt package(s)
    apt_install,
    /// Install specific dots section
    install_dots_section,
    /// Install all dots sections
    install_dots,

    /// Return the command matching its string representation.
    pub fn parse(command_str: []const u8) ?Command {
        inline for (std.meta.fields(Command)) |field| {
            if (std.mem.eql(u8, command_str, field.name)) {
                return @field(Command, field.name);
            }
        }

        return null;
    }

    /// Parse the cli args for the given command and execute the associated
    /// action.
    ///
    /// This typically means reading the command file and parsing the arguments
    /// before passing them off to the appropriate action.
    pub fn dispatch(command: Command, allocator: mem.Allocator, args: []const u8) anyerror!void {
        switch (command) {
            .direxists => try Action.direxists(args),
            .link => try link(allocator, args),
            .download => try download(allocator, args),
            .apt_install => try aptInstall(allocator, args),
            .install_dots => try installDots(allocator, args),
            .install_dots_section => try installDotsSection(allocator, args),
        }
    }
};

fn installDots(allocator: mem.Allocator, dots_path: []const u8) !void {
    var it: FilterIterator = try .all(allocator, dots_path);
    defer it.deinit();

    while (try it.next()) |entry| {
        try Command.install_dots_section.dispatch(allocator, entry.realpath);
    }
}

fn aptInstall(allocator: mem.Allocator, args: []const u8) !void {
    const content = try FilterIterator.Entry.content(.{ .realpath = args, .name = undefined }, allocator);
    defer allocator.free(content);

    var it = std.mem.splitScalar(u8, content, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;

        try Action.aptInstall(allocator, line);
    }
}

fn installDotsSection(allocator: mem.Allocator, args: []const u8) !void {
    std.log.scoped(.section).info("{s}", .{std.fs.path.basename(args)});

    const apt_is_available = try isAptGetPresent();
    // We print unavailability of apt only if a dots section declares apt dependencies
    var apt_message_printed = false;

    {
        var dir_it: FilterIterator = try .ext(allocator, args, "dir");
        while (try dir_it.next()) |entry| {
            try Command.direxists.dispatch(allocator, entry.realpath);
        }
    }

    {
        var dir_it: FilterIterator = try .ext(allocator, args, "link");
        while (try dir_it.next()) |entry| {
            try Command.link.dispatch(allocator, entry.realpath);
        }
    }

    {
        var dir_it: FilterIterator = try .ext(allocator, args, "download");
        while (try dir_it.next()) |entry| {
            try Command.download.dispatch(allocator, entry.realpath);
        }
    }

    {
        var dir_it: FilterIterator = try .ext(allocator, args, "apt");
        while (try dir_it.next()) |entry| {
            if (apt_is_available) {
                try Command.apt_install.dispatch(allocator, entry.realpath);
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
    }
}

fn download(allocator: mem.Allocator, args: []const u8) !void {
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

fn link(allocator: mem.Allocator, args: []const u8) !void {
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

const std = @import("std");
const mem = std.mem;
const FilterIterator = @import("FilterIterator.zig");
const action = @import("action.zig");
const Action = action;
const Match = @import("Match.zig");
const log = std.log.scoped(.command);
