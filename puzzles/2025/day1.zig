const std = @import("std");
const aoc = @import("aoc");

const V = i16;

const P = struct {
    alloc: std.mem.Allocator,
    nums: std.ArrayList(V) = std.ArrayList(V){},

    pub fn parseLine(this: *@This(), line: []const u8) aoc.input.ParseError!bool {
        const v = try aoc.input.parseInt(i16, line[1..]);
        try this.nums.append(this.alloc, if (line[0] == 'L') v * -1 else v);
        return true;
    }

    pub fn deinit(this: *@This()) void {
        this.nums.deinit(this.alloc);
    }
};

const filePath: []const u8 = "input/2025/day1";

fn newP(alloc: std.mem.Allocator, path: []const u8) !P {
    var p = P{ .alloc = alloc };
    try aoc.input.parseLines(path, &p, P.parseLine);
    return p;
}

fn combo(nums: []V) u16 {
    var c: u16 = 0;
    var v: i16 = 50;
    for (nums) |num| {
        v = @mod(v + num, 100);
        if (v == 0) {
            c += 1;
        }
    }
    return c;
}

fn combo2(nums: []V) u16 {
    var c: u16 = 0;
    var v: i16 = 50;
    for (nums) |num| {
        const sign = @as(i16, std.math.sign(num));
        for (0..@as(usize, @abs(num))) |_| {
            v = @mod(sign + v, 100);
            if (v == 0) {
                c += 1;
            }
        }
    }
    return c;
}

test "part1ex" {
    var p = try newP(std.testing.allocator, "input/2025/day1.ex");
    defer p.deinit();

    try std.testing.expectEqual(3, combo(p.nums.items));
}

test "part1" {
    var p = try newP(std.testing.allocator, filePath);
    defer p.deinit();

    try std.testing.expectEqual(1120, combo(p.nums.items));
}

test "part2ex" {
    var p = try newP(std.testing.allocator, "input/2025/day1.ex");
    defer p.deinit();

    try std.testing.expectEqual(6, combo2(p.nums.items));
}

test "part2" {
    var p = try newP(std.testing.allocator, filePath);
    defer p.deinit();

    try std.testing.expectEqual(6554, combo2(p.nums.items));
}
