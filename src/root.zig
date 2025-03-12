pub const search = @import("search.zig");
pub const twod = @import("twod.zig");
pub const input = @import("input.zig");
pub const grid = @import("grid.zig");
pub const permute = @import("permute.zig");
pub const indy = @import("indy.zig");

const std = @import("std");

comptime {
    if (@import("builtin").is_test) {
        _ = search;
        _ = twod;
        _ = input;
        _ = grid;
        _ = permute;
        _ = indy;
    }
}

/// The value of the current selection.
pub fn SelectValue(comptime T: type) type {
    return struct {
        current: T,
        values: []T,
    };
}

/// A select iterator for a slice of the given type.
pub fn SelectIterator(comptime T: type) type {
    return struct {
        orig: []T,
        buf: []T,
        i: usize = 0,

        pub fn next(this: *@This()) ?SelectValue(T) {
            if (this.i >= this.orig.len) {
                return null;
            }
            const v = this.orig[this.i];
            var o: usize = 0;
            for (0..this.orig.len) |i| {
                if (i != this.i) {
                    this.buf[o] = this.orig[i];
                    o += 1;
                }
            }
            this.i += 1;
            return .{ .current = v, .values = this.buf };
        }
    };
}

/// Pluck one item at a time from a slice.
/// The buffer argument must be one element shorter than the values slice.
pub fn selectIterator(comptime T: type, vals: []T, buf: []T) SelectIterator(T) {
    if (buf.len + 1 != vals.len) {
        std.debug.panic("buf.len + 1 != vals.len", .{});
    }
    return .{ .orig = vals, .buf = buf };
}
