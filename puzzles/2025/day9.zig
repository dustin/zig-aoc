const std = @import("std");
const aoc = @import("aoc");

const Point = @Vector(2, i64);

const Input = std.AutoHashMap(Point, void);

fn parseInput(alloc: std.mem.Allocator, filename: []const u8) !Input {
    const T = struct {
        alloc: std.mem.Allocator,
        points: std.AutoHashMap(Point, void),

        fn parseLine(this: *@This(), line: []const u8) aoc.input.ParseError!bool {
            var it = std.mem.tokenizeSequence(u8, line, ",");
            const x = try aoc.input.parseInt(i32, it.next().?);
            const y = try aoc.input.parseInt(i32, it.next().?);
            try this.points.put(.{ x, y }, {});
            return true;
        }
    };
    var t: T = .{ .alloc = alloc, .points = std.AutoHashMap(Point, void).init(alloc) };
    try aoc.input.parseLines(filename, &t, T.parseLine);
    return t.points;
}

const Pair = [2]Point;

fn furthest(alloc: std.mem.Allocator, ins: Input) !u64 {
    var ps = try std.ArrayList(Point).initCapacity(alloc, ins.count());
    defer ps.deinit(alloc);
    var it = ins.iterator();
    while (it.next()) |el| {
        try ps.append(alloc, el.key_ptr.*);
    }
    var maxarea: u64 = 0;
    for (ps.items, 0..) |a, ai| {
        for (ps.items[ai + 1 ..]) |b| {
            const ar = area(a, b);
            if (ar > maxarea) {
                maxarea = ar;
            }
        }
    }
    return maxarea;
}

fn area(a: Point, b: Point) u64 {
    const one: @Vector(2, u64) = @splat(1);
    return @reduce(.Mul, @abs(a - b) + one);
}

test "area" {
    // Ultimately, the largest rectangle you can make in this example has area 50.
    // One way to do this is between 2,5 and 11,1:
    try std.testing.expectEqual(50, area(.{ 2, 5 }, .{ 11, 1 }));
}

fn part1(alloc: std.mem.Allocator, filename: []const u8) !u64 {
    var ins = try parseInput(alloc, filename);
    defer ins.deinit();

    return try furthest(alloc, ins);
}

test "part1ex" {
    const alloc = std.testing.allocator;
    try std.testing.expectEqual(50, try part1(alloc, "input/2025/day9.ex"));
}

test "part1" {
    const alloc = std.testing.allocator;
    try std.testing.expectEqual(4763509452, try part1(alloc, "input/2025/day9"));
}
