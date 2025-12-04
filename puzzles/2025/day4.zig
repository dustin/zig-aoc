const std = @import("std");
const aoc = @import("aoc");

fn part1(g: aoc.grid.Grid) u32 {
    var totes: u32 = 0;
    var it = g.iterate();
    while (it.next()) |pv| {
        if (pv.value != '@') {
            continue;
        }
        // We gots paper
        var count: u8 = 0;
        for (aoc.indy.aroundD(pv.point)) |n| {
            if ((g.lookup(n) orelse '.') == '@') {
                count += 1;
            }
        }
        if (count < 4) {
            totes += 1;
        }
    }
    return totes;
}

test "part1ex" {
    var g = try aoc.grid.openFileGrid(std.testing.allocator, "input/2025/day4.ex");
    defer g.deinit();
    try std.testing.expectEqual(13, part1(g.grid));
}

test "part1" {
    var g = try aoc.grid.openFileGrid(std.testing.allocator, "input/2025/day4");
    defer g.deinit();
    try std.testing.expectEqual(1508, part1(g.grid));
}

fn part2(alloc: std.mem.Allocator, g: aoc.grid.Grid) u32 {
    var totes: u32 = 0;
    var again = true;
    var moved = std.AutoHashMap(aoc.twod.Point, void).init(alloc);
    defer moved.deinit();

    while (again) {
        again = false;
        var it = g.iterate();
        while (it.next()) |pv| {
            if (moved.get(pv.point)) |_| continue;
            if (pv.value != '@') {
                continue;
            }
            // We gots paper
            var count: u8 = 0;
            for (aoc.indy.aroundD(pv.point)) |n| {
                if (moved.get(n)) |_| {} else if ((g.lookup(n) orelse '.') == '@') {
                    count += 1;
                }
            }
            if (count < 4) {
                totes += 1;
                again = true;
                moved.put(pv.point, {}) catch {};
            }
        }
    }
    return totes;
}

test "part2ex" {
    var g = try aoc.grid.openFileGrid(std.testing.allocator, "input/2025/day4.ex");
    defer g.deinit();
    try std.testing.expectEqual(43, part2(std.testing.allocator, g.grid));
}

test "part2" {
    var g = try aoc.grid.openFileGrid(std.testing.allocator, "input/2025/day4");
    defer g.deinit();
    try std.testing.expectEqual(8538, part2(std.testing.allocator, g.grid));
}
