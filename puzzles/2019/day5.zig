const std = @import("std");
const aoc = @import("aoc");
const intcode = @import("intcode.zig");

test "part1" {
    var computer = try intcode.readFile(std.testing.allocator, "input/2019/day5");
    defer computer.deinit();

    var res = try computer.run();
    switch (res) {
        .Input => try computer.set(res.Input, 1),
        else => return error.ExpectedInput,
    }
    res = try computer.run();
    try std.testing.expectEqual(res, .Halted);

    try std.testing.expectEqual(4511442, computer.output.items[computer.output.items.len - 1]);
}

test "part2" {
    var computer = try intcode.readFile(std.testing.allocator, "input/2019/day5");
    defer computer.deinit();

    var res = try computer.run();
    switch (res) {
        .Input => try computer.set(res.Input, 5),
        else => return error.ExpectedInput,
    }
    res = try computer.run();
    try std.testing.expectEqual(res, .Halted);

    try std.testing.expectEqual(12648139, computer.output.items[computer.output.items.len - 1]);
}
