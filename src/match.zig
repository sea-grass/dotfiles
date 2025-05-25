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

pub fn matchExt(file_path: []const u8, ext: []const u8, allow_exact: bool) bool {
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

const std = @import("std");
const mem = std.mem;
