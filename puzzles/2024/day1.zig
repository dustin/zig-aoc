const std = @import("std");
const aoc = @import("aoc");

const V = struct {
    a: u32 = 0,
    b: u32 = 0,
};

const P = struct {
    alloc: std.mem.Allocator,
    nums: std.MultiArrayList(V) = std.MultiArrayList(V){},

    pub fn parseLine(this: *@This(), line: []const u8) aoc.input.ParseError!bool {
        var v = V{ .a = 0, .b = 0 };
        var it = std.mem.tokenizeSequence(u8, line, " ");
        v.a = try aoc.input.parseInt(u32, it.next() orelse return false);
        v.b = try aoc.input.parseInt(u32, it.next() orelse return false);
        try this.nums.append(this.alloc, v);
        return true;
    }

    pub fn deinit(this: *@This()) void {
        this.nums.deinit(this.alloc);
    }
};

const filePath: []const u8 = "input/2024/day1";

fn newP(alloc: std.mem.Allocator, path: []const u8) !P {
    var p = P{ .alloc = alloc };
    try aoc.input.parseLines(path, &p, P.parseLine);
    return p;
}

test "part1" {
    var p = try newP(std.testing.allocator, filePath);
    defer p.deinit();

    std.sort.pdq(u32, p.nums.items(.a), {}, std.sort.asc(u32));
    std.sort.pdq(u32, p.nums.items(.b), {}, std.sort.asc(u32));

    var sum: u32 = 0;
    for (p.nums.items(.a), p.nums.items(.b)) |a, b| {
        sum += @max(a, b) - @min(a, b);
    }

    try std.testing.expectEqual(3714264, sum);
}

test "part2" {
    var p = try newP(std.testing.allocator, filePath);
    defer p.deinit();

    var counts = std.AutoHashMap(u32, u32).init(std.testing.allocator);
    defer counts.deinit();
    for (p.nums.items(.b)) |b| {
        const entry = try counts.getOrPut(b);
        if (!entry.found_existing) {
            entry.value_ptr.* = 0;
        }
        entry.value_ptr.* += 1;
    }
    var sum: u32 = 0;
    for (p.nums.items(.a)) |a| {
        if (counts.get(a)) |n| {
            sum += a * n;
        }
    }

    try std.testing.expectEqual(18805872, sum);
}
