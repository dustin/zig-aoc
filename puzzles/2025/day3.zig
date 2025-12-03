const std = @import("std");
const aoc = @import("aoc");

fn digit(g: aoc.grid.Grid, p: aoc.twod.Point) ?u8 {
    if (g.lookup(p)) |d| {
        return d - 48;
    }
    return null;
}

fn part1(g: aoc.grid.Grid) u32 {
    var totes: u32 = 0;
    for (0..1 + @as(usize, @intCast(g.bounds.maxs[1]))) |row| {
        const rowi: i32 = @intCast(row);
        const d = digit(g, .{ 0, rowi });
        var maxp: aoc.twod.Point = .{ 0, rowi };
        var maxv = d.?;
        for (0..@as(usize, @intCast(g.bounds.maxs[0]))) |col| {
            const p = .{ @as(i32, @intCast(col)), rowi };
            if (digit(g, p)) |dp| {
                if (dp > maxv) {
                    maxp = p;
                    maxv = dp;
                }
                // Nothing gonna be bigger than this.
                if (maxv == 9) {
                    break;
                }
            }
        }
        var max2p = maxp;
        var max2v: u32 = 0;
        for (@intCast(maxp[0] + 1)..1 + @as(usize, @intCast(g.bounds.maxs[0]))) |col| {
            const p = .{ @as(i32, @intCast(col)), rowi };
            if (digit(g, p)) |dp| {
                if (dp > max2v) {
                    max2p = p;
                    max2v = dp;
                }
                // Nothing gonna be bigger than this.
                if (max2v == 9) {
                    break;
                }
            }
        }
        totes += (maxv * 10) + max2v;
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
