const std = @import("std");
const aoc = @import("aoc");

const Point = aoc.twod.Point;

const A = struct {
    pointMap: std.AutoHashMap(aoc.twod.Point, void) = undefined,
    bounds: aoc.indy.Bounds(2) = .{ .mins = @splat(0), .maxs = .{ 70, 70 } },

    pub fn nf(this: *@This(), p: Point, neighbors: *std.ArrayList(aoc.search.Node(Point))) aoc.search.OutOfMemory!void {
        for (aoc.indy.around(p)) |np| {
            if (this.bounds.contains(np) and this.pointMap.get(np) == null) {
                try neighbors.append(.{ .cost = 1, .heuristic = @intCast(aoc.indy.mdist(this.bounds.maxs, np)), .val = np });
            }
        }
    }

    pub fn rf(_: *@This(), p: Point) Point {
        return p;
    }

    pub fn found(this: *@This(), p: Point) aoc.search.OutOfMemory!bool {
        return @reduce(.And, p == this.bounds.maxs);
    }

    pub fn deinit(this: *A) void {
        this.pointMap.deinit();
    }
};

const I = struct {
    alloc: std.mem.Allocator,
    lines: std.ArrayList(Point),

    pub fn parseLine(this: *@This(), line: []const u8) aoc.input.ParseError!bool {
        var p = aoc.twod.origin;
        var it = std.mem.splitSequence(u8, line, ",");
        p[0] = try aoc.input.parseInt(i32, it.next() orelse return false);
        p[1] = try aoc.input.parseInt(i32, it.next() orelse return false);
        try this.lines.append(p);
        return true;
    }

    pub fn init(this: *@This(), alloc: std.mem.Allocator, p: []const u8) !I {
        this.alloc = alloc;
        this.lines = std.ArrayList(Point).init(alloc);
        try aoc.input.parseLines(p, this, I.parseLine);
        return this.*;
    }

    pub fn deinit(this: *I) void {
        this.lines.deinit();
    }

    pub fn run(this: *@This(), maxLines: u32) !aoc.search.AStarResult(Point, Point) {
        var a = A{ .pointMap = std.AutoHashMap(aoc.twod.Point, void).init(this.alloc) };
        defer a.deinit();
        for (this.lines.items[0..maxLines]) |p| {
            a.pointMap.put(p, void{}) catch return error.ParseError;
        }
        const start = aoc.twod.origin;

        return aoc.search.astar(Point, Point, this.alloc, &a, start, A.rf, A.nf, A.found);
    }
};

const filePath: []const u8 = "input/2024/day18";

fn newI(alloc: std.mem.Allocator, p: []const u8) !I {
    var i = I{ .alloc = alloc, .lines = undefined };
    return i.init(alloc, p);
}

test "part1" {
    var st = try newI(std.testing.allocator, filePath);
    defer st.deinit();
    var res = try st.run(1024);
    defer res.deinit();
    try std.testing.expectEqual(res.cost, 272);
}

test "part2" {
    var st = try newI(std.testing.allocator, filePath);
    defer st.deinit();

    const T = struct {
        st: *I,

        pub fn compare(this: *@This(), val: u32) std.math.Order {
            if (val > this.st.lines.items.len) {
                return .gt;
            }
            var res = this.st.run(val) catch return .lt;
            defer res.deinit();
            if (res.val == null) {
                return .gt;
            } else {
                return .lt;
            }
        }
    };

    var t = T{ .st = &st };
    const at = aoc.search.autoBinSearch(u32, &t, T.compare);
    try std.testing.expectEqual(2967, at);

    const p = st.lines.items[at - 1];
    try std.testing.expectEqual(.{ 16, 44 }, p);
}
