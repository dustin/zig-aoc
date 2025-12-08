const std = @import("std");
const aoc = @import("aoc");

const Point = @Vector(3, i32);

const Input = []const Point;

fn parseInput(alloc: std.mem.Allocator, filename: []const u8) !Input {
    const T = struct {
        alloc: std.mem.Allocator,
        points: std.ArrayList(Point),

        fn parseLine(this: *@This(), line: []const u8) aoc.input.ParseError!bool {
            var it = std.mem.tokenizeSequence(u8, line, ",");
            const x = try aoc.input.parseInt(i32, it.next().?);
            const y = try aoc.input.parseInt(i32, it.next().?);
            const z = try aoc.input.parseInt(i32, it.next().?);
            try this.points.append(this.alloc, .{ x, y, z });
            return true;
        }
    };
    var t: T = .{ .alloc = alloc, .points = try std.ArrayList(Point).initCapacity(alloc, 10) };
    try aoc.input.parseLines(filename, &t, T.parseLine);
    return try t.points.toOwnedSlice(alloc);
}

inline fn veq(a: Point, b: Point) bool {
    return @reduce(.And, a == b);
}

fn nearestTo(p: Point, ins: Input, mapped: std.AutoHashMap(Point, Point)) Point {
    var maxdist = std.math.inf(f64);
    var np: Point = undefined;
    for (ins) |p2| {
        if (veq(p, p2)) continue;
        if (mapped.get(p2)) |rp| {
            if (veq(p, rp)) continue;
        }
        const dist = aoc.indy.edist(p, p2);
        if (dist < maxdist) {
            maxdist = dist;
            np = p2;
        }
    }
    return np;
}

const Pair = [2]Point;

fn nearest(ins: Input) Pair {
    var rv: Point = undefined;
    var maxdist: f64 = std.math.inf(f64);
    for (ins, 0..) |a, ai| {
        for (ins[ai + 1 ..]) |b| {
            const dist = aoc.indy.edist(a, b);
            if (dist < maxdist) {
                maxdist = dist;
                rv[0] = a;
                rv[1] = b;
            }
        }
    }
    return rv;
}

fn distLT(_: void, a: Pair, b: Pair) bool {
    return aoc.indy.edist(a[0], a[1]) < aoc.indy.edist(b[0], b[1]);
}

// test "part1" {
//     const alloc = std.testing.allocator;
//     const ins = try parseInput(alloc, "input/2025/day8.ex");
//     defer alloc.free(ins);

//     std.debug.print("{any}\n", .{ins});
//     std.debug.print("nearest: {any}\n", .{nearest(ins)});

//     var pairs = try alloc.alloc(Pair, ins.len);
//     defer alloc.free(pairs);
//     var mapped = std.AutoHashMap(Point, Point).init(alloc);
//     defer mapped.deinit();
//     for (ins, 0..) |p, i| {
//         pairs[i][0] = p;
//         pairs[i][1] = nearestTo(p, ins, mapped);
//         try mapped.put(p, pairs[i][1]);
//     }

//     std.sort.pdq(Pair, pairs, {}, distLT);

//     for (pairs) |p| {
//         std.debug.print("  {any} -> {any} - {}\n", .{ p[0], p[1], aoc.indy.edist(p[0], p[1]) });
//     }
// }
