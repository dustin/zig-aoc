const std = @import("std");
const aoc = @import("aoc");

fn forkit(alloc: std.mem.Allocator, g: aoc.grid.Grid, move: bool) !u32 {
    var totes: u32 = 0;
    var again = true;
    var mg = try g.mutable(alloc);
    defer mg.deinit(alloc);

    while (again) {
        again = false;
        var it = mg.iterate();
        while (it.next()) |pv| {
            if (pv.value != '@') {
                continue;
            }
            // We gots paper
            var count: u8 = 0;
            for (aoc.indy.aroundD(pv.point)) |n| {
                if ((mg.lookup(n) orelse '.') == '@') {
                    count += 1;
                }
            }
            if (count < 4) {
                totes += 1;
                if (move) {
                    mg.set(pv.point, '.');
                    again = true;
                }
            }
        }
    }
    return totes;
}

test "part1ex" {
    var g = try aoc.grid.openFileGrid(std.testing.allocator, "input/2025/day4.ex");
    defer g.deinit();
    try std.testing.expectEqual(13, try forkit(std.testing.allocator, g.grid, false));
}

test "part1" {
    var g = try aoc.grid.openFileGrid(std.testing.allocator, "input/2025/day4");
    defer g.deinit();
    try std.testing.expectEqual(1508, try forkit(std.testing.allocator, g.grid, false));
}

test "part2ex" {
    var g = try aoc.grid.openFileGrid(std.testing.allocator, "input/2025/day4.ex");
    defer g.deinit();
    try std.testing.expectEqual(43, try forkit(std.testing.allocator, g.grid, true));
}

test "part2" {
    var g = try aoc.grid.openFileGrid(std.testing.allocator, "input/2025/day4");
    defer g.deinit();
    try std.testing.expectEqual(8538, try forkit(std.testing.allocator, g.grid, true));
}
