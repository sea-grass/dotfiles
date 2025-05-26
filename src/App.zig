const App = @This();

root: *std.fs.Dir,
allocator: mem.Allocator,

pub fn run(app: *const App, command_str: []const u8, args: []const u8) !void {
    if (command.Command.parse(command_str)) |cmd| {
        try cmd.dispatch(app.allocator, args);
    } else {
        log.err("Invalid command [{s}]", .{command_str});
        return error.InvalidCommand;
    }
}

const std = @import("std");
const mem = std.mem;
const command = @import("command.zig");
const log = std.log.scoped(.App);
