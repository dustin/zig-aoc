const std = @import("std");
const aoc = @import("aoc");
const intcode = @import("intcode.zig");

test "part1" {
    var computer = try intcode.readFile(std.testing.allocator, "input/2019/day7");
    defer computer.deinit();

    var sequence = [5]u8{ 0, 1, 2, 3, 4 };

    var buf: [5]u8 = undefined;
    var it = aoc.permute.Permutations(u8).init(sequence[0..], &buf);
    var i: u8 = 0;
    var mostOut: i32 = 0;
    while (it.next()) |phases| : (i += 1) {
        var out: i32 = 0;

        for (phases) |phase| {
            computer.reset();
            var res = try computer.run();
            switch (res) {
                .Input => try computer.set(res.Input, @as(i32, phase)),
                else => return error.ExpectedInput,
            }
            res = try computer.run();
            switch (res) {
                .Input => try computer.set(res.Input, out),
                else => return error.ExpectedInput,
            }
            res = try computer.run();
            switch (res) {
                .Halted => {},
                else => return error.ExpectedOutput,
            }
            out = computer.output.items[computer.output.items.len - 1];
        }
        mostOut = @max(mostOut, out);
    }

    try std.testing.expectEqual(43812, mostOut);
}
