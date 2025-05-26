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

const App = @import("App.zig");
const std = @import("std");
const mem = std.mem;
const log = std.log.scoped(.cmd);
