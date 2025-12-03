const std = @import("std");
const aoc = @import("aoc");

fn digit(g: aoc.grid.Grid, p: aoc.twod.Point) ?u8 {
    if (g.lookup(p)) |d| {
        return d - 48;
    }
    return null;
}

fn select(g: aoc.grid.Grid, start: aoc.twod.Point, want: i32, totes: u64) u64 {
    if (want == 0) {
        return totes;
    }
    const end = g.bounds.maxs[0] - want + 2;

    const d = digit(g, start);
    var maxp = start;
    var maxv = d.?;
    for (@as(usize, @intCast(start[0]))..@as(usize, @intCast(end))) |col| {
        const p = .{ @as(i32, @intCast(col)), start[1] };
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
    maxp[0] = maxp[0] + 1;
    return select(g, maxp, want - 1, (totes * 10) + maxv);
}

fn part1(g: aoc.grid.Grid) u32 {
    var totes: u32 = 0;
    for (0..1 + @as(usize, @intCast(g.bounds.maxs[1]))) |row| {
        totes += @intCast(select(g, .{ 0, @as(i32, @intCast(row)) }, 2, 0));
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
    for (0..1 + @as(usize, @intCast(g.bounds.maxs[1]))) |row| {
        totes += select(g, .{ 0, @as(i32, @intCast(row)) }, 12, 0);
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
