const std = @import("std");
const aoc = @import("aoc");

fn select(row: []const u8, want: i32, totes: u64) u64 {
    if (want == 0) return totes;
    var r = row;
    var maxv = r[0] - 48;
    var maxr = r;
    while (r.len >= want) : (r = r[1..]) {
        const dp = r[0] - 48;
        if (dp > maxv) {
            maxv = dp;
            maxr = r;
        }
    }
    return select(maxr[1..], want - 1, (totes * 10) + maxv);
}

fn part1(g: aoc.grid.Grid) u64 {
    var totes: u64 = 0;
    var it = g.rows();
    while (it.next()) |r| {
        totes += select(r, 2, 0);
    }
    return totes;
}

test "part1ex" {
    var g = try aoc.grid.openFileGrid(std.testing.allocator, "input/2025/day3.ex");
    defer g.deinit();
    try std.testing.expectEqual(357, part1(g.grid));
}

test "part1" {
    var g = try aoc.grid.openFileGrid(std.testing.allocator, "input/2025/day3");
    defer g.deinit();
    try std.testing.expectEqual(17100, part1(g.grid));
}

fn part2(g: aoc.grid.Grid) u64 {
    var totes: u64 = 0;
    var it = g.rows();
    while (it.next()) |r| {
        totes += select(r, 12, 0);
    }
    return totes;
}

test "part2ex" {
    var g = try aoc.grid.openFileGrid(std.testing.allocator, "input/2025/day3.ex");
    defer g.deinit();
    try std.testing.expectEqual(3121910778619, part2(g.grid));
}

test "part2" {
    var g = try aoc.grid.openFileGrid(std.testing.allocator, "input/2025/day3");
    defer g.deinit();
    try std.testing.expectEqual(170418192256861, part2(g.grid));
}
