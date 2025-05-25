const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var root = std.fs.cwd();

    try app(
        allocator,
        .{ .root = &root },
    );
}

const AppOptions = struct {
    root: *std.fs.Dir,
};

pub fn app(allocator: mem.Allocator, options: AppOptions) !void {
    _ = allocator;

    var dots = try options.root.openDir("dots", .{ .iterate = true });
    defer dots.close();

    var it = dots.iterate();

    while (try it.next()) |entry| {
        std.log.info("dot: {s}", .{entry.name});
    }
}
