const std = @import("std");
const aoc = @import("aoc");
const intcode = @import("intcode.zig");

comptime {
    if (@import("builtin").is_test) {
        _ = @import("intcode.zig");
    }
}

test "part1" {
    var computer = try intcode.readFile(std.testing.allocator, "input/2019/day2");
    defer computer.deinit();
    try computer.set(1, 12);
    try computer.set(2, 2);
    try computer.runTilHalt();
    try std.testing.expectEqual(3931283, computer.at(0));
}
