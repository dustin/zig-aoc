pub const search = @import("search.zig");
pub const twod = @import("twod.zig");
pub const input = @import("input.zig");

comptime {
    if (@import("builtin").is_test) {
        _ = search;
        _ = twod;
        _ = input;
    }
}
