const std = @import("std");
const aoc = @import("aoc");

const I = struct {
    lineCount: u32 = 0,
    maxLines: u32 = 0,
    bounds: aoc.twod.Bounds = aoc.twod.newBounds(),
    pointMap: std.AutoHashMap(aoc.twod.Point, void) = undefined,

    pub fn parseLine(this: *@This(), line: []const u8) aoc.input.ParseError!bool {
        if (this.lineCount == this.maxLines) {
            return false;
        }
        this.lineCount += 1;

        var p = aoc.twod.Point{ .x = 0, .y = 0 };
        var it = std.mem.splitSequence(u8, line, ",");
        p.x = try aoc.input.parseInt(i32, it.next() orelse return false);
        p.y = try aoc.input.parseInt(i32, it.next() orelse return false);
        this.pointMap.put(p, void{}) catch return error.ParseError;
        this.bounds.addPoint(p);
        return true;
    }

    pub fn rf(_: *@This(), p: aoc.twod.Point) aoc.twod.Point {
        return p;
    }

    pub fn nf(this: *@This(), p: aoc.twod.Point, neighbors: *std.ArrayList(aoc.search.Node(aoc.twod.Point))) aoc.search.OutOfMemory!void {
        for (p.around()) |np| {
            if (this.bounds.contains(np) and this.pointMap.get(np) == null) {
                try neighbors.append(.{ .cost = 1, .heuristic = 1, .val = np });
            }
        }
    }

    pub fn found(this: *@This(), p: aoc.twod.Point) aoc.search.OutOfMemory!bool {
        return p.x == this.bounds.maxX and p.y == this.bounds.maxY;
    }
};

fn run(alloc: std.mem.Allocator, maxLines: u32) !aoc.search.AStarResult(aoc.twod.Point, aoc.twod.Point) {
    var i = I{ .maxLines = maxLines, .pointMap = std.AutoHashMap(aoc.twod.Point, void).init(alloc) };
    defer i.pointMap.deinit();

    try aoc.input.parseLines("input/2024/day18", &i, I.parseLine);

    i.bounds.maxX = 70;
    i.bounds.maxY = 70;

    const start = aoc.twod.Point{ .x = i.bounds.minX, .y = i.bounds.minY };

    return aoc.search.astar(aoc.twod.Point, aoc.twod.Point, alloc, &i, start, I.rf, I.nf, I.found);
}

test "part1" {
    var res = try run(std.testing.allocator, 1024);
    defer res.deinit();
    try std.testing.expectEqual(res.cost, 272);
}

test "part2" {
    const T = struct {
        pub fn compare(_: void, val: u32) std.math.Order {
            var res = run(std.testing.allocator, val) catch return .lt;
            defer res.deinit();
            if (res.val == null) {
                return .gt;
            } else {
                return .lt;
            }
        }
    };

    const at = aoc.search.binSearch(u32, {}, T.compare, 272, 4000);
    try std.testing.expectEqual(2967, at);

    // TODO:  Look up this thing at line 2967 and report the x,y (16,44)
}

pub fn main() !void {}
