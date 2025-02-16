const std = @import("std");
const aoc = @import("aoc");

const Point = aoc.twod.Point;

const A = struct {
    pointMap: std.AutoHashMap(aoc.twod.Point, void) = undefined,
    bounds: aoc.twod.Bounds = aoc.twod.Bounds{ .minX = 0, .minY = 0, .maxX = 70, .maxY = 70 },

    pub fn nf(this: *@This(), p: Point, neighbors: *std.ArrayList(aoc.search.Node(Point))) aoc.search.OutOfMemory!void {
        for (p.around()) |np| {
            if (this.bounds.contains(np) and this.pointMap.get(np) == null) {
                try neighbors.append(.{ .cost = 1, .heuristic = 1, .val = np });
            }
        }
    }

    pub fn rf(_: *@This(), p: Point) Point {
        return p;
    }

    pub fn found(this: *@This(), p: Point) aoc.search.OutOfMemory!bool {
        return p.x == this.bounds.maxX and p.y == this.bounds.maxY;
    }

    pub fn deinit(this: *A) void {
        this.pointMap.deinit();
    }
};

const I = struct {
    alloc: std.mem.Allocator,
    lines: std.ArrayList(Point),

    pub fn parseLine(this: *@This(), line: []const u8) aoc.input.ParseError!bool {
        var p = Point{ .x = 0, .y = 0 };
        var it = std.mem.splitSequence(u8, line, ",");
        p.x = try aoc.input.parseInt(i32, it.next() orelse return false);
        p.y = try aoc.input.parseInt(i32, it.next() orelse return false);
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
        const start = Point{ .x = 0, .y = 0 };

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
    try std.testing.expectEqual(p.x, 16);
    try std.testing.expectEqual(p.y, 44);
}

pub fn main() !void {}
