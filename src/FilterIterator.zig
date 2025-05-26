const FilterIterator = @This();

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
match_strategy: match.Match,

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

pub fn init(allocator: mem.Allocator, abs_path: []const u8, match_strategy: match.Match) !FilterIterator {
    var dir = try std.fs.openDirAbsolute(abs_path, .{ .iterate = true });
    errdefer dir.close();

    return .{
        .arena = std.heap.ArenaAllocator.init(allocator),
        .path = abs_path,
        .root_dir = dir,
        .it = dir.iterate(),
        .state = .init,
        .match_strategy = match_strategy,
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
    return switch (it.match_strategy) {
        .all => true,
        .match_ext => |match_ext| match.matchExt(
            entry.name,
            match_ext.ext,
            match_ext.allow_exact,
        ),
    };
}

const std = @import("std");
const mem = std.mem;
const match = @import("match.zig");
