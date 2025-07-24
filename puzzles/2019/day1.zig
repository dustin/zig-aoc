const std = @import("std");
const aoc = @import("aoc");

fn fuelReq(i: i32) i32 {
    return @divTrunc(i, 3) - 2;
}

test "part1" {
    var answer: i32 = 0;
    const T = struct {
        answer: i32 = 0,

        fn parseLine(s: *i32, line: []const u8) aoc.input.ParseError!bool {
            s.* += fuelReq(try aoc.input.parseInt(i32, line));
            return true;
        }
    };

    try aoc.input.parseLines("input/2019/day1", &answer, T.parseLine);
    try std.testing.expectEqual(3317659, answer);
}

test "part2" {
    var answer: i32 = 0;

    const T = struct {
        answer: i32 = 0,

        fn parseLine(s: *i32, line: []const u8) aoc.input.ParseError!bool {
            const base = try aoc.input.parseInt(i32, line);
            var fueld = fuelReq(base);
            while (fueld > 0) {
                s.* += fueld;
                fueld = fuelReq(fueld);
            }

            return true;
        }
    };

    try aoc.input.parseLines("input/2019/day1", &answer, T.parseLine);
    try std.testing.expectEqual(4973616, answer);
}
