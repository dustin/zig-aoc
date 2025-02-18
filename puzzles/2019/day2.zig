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

test "part2" {
    var computer = try intcode.readFile(std.testing.allocator, "input/2019/day2");
    defer computer.deinit();

    const T = struct {
        computer: *intcode.Computer,

        pub fn compare(this: *@This(), val: i32) std.math.Order {
            this.computer.reset();
            this.computer.set(1, @divTrunc(val, 100)) catch return .gt;
            this.computer.set(2, @mod(val, 100)) catch return .gt;
            this.computer.runTilHalt() catch return .gt;
            return std.math.order(this.computer.at(0), 19690720);
        }
    };

    var t = T{ .computer = &computer };

    const found = aoc.search.binSearch(i32, &t, T.compare, 0, 10000);
    try std.testing.expectEqual(6979, found);

    const afound = aoc.search.autoBinSearch(i32, &t, T.compare);
    try std.testing.expectEqual(6979, afound);
}
