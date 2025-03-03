const std = @import("std");
const aoc = @import("aoc");
const intcode = @import("intcode.zig");

fn run(alloc: std.mem.Allocator, param: i64) !i64 {
    var computer = try intcode.readFile(alloc, "input/2019/day9");
    defer computer.deinit();

    var res = try computer.run();
    switch (res) {
        .Input => try computer.set(res.Input, param),
        else => return error.ExpectedInput,
    }
    res = try computer.run();
    switch (res) {
        .Halted => {},
        else => return error.ExpectedHalt,
    }

    return computer.output.items[computer.output.items.len - 1];
}

test "part1" {
    try std.testing.expectEqual(3100786347, run(std.testing.allocator, 1));
}

test "part2" {
    try std.testing.expectEqual(87023, run(std.testing.allocator, 2));
}
