const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, World!\n", .{});
}

test "a thing" {
    std.debug.print("2024/18 - Hello, World!\n", .{});
}
