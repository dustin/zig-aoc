const std = @import("std");
const aoc = @import("aoc");

const file_path: []const u8 = "input/2024/day4";

test "part1" {
    var fg = try aoc.grid.openFileGrid(std.testing.allocator, file_path);
    defer fg.deinit();

    const dirs = (aoc.twod.Point{ .x = 0, .y = 0 }).aroundD();
    var christmases: u16 = 0;

    var it = fg.grid.iterate();
    while (it.next()) |pv| {
        if (pv.value != 'X') {
            continue;
        }

        for (dirs) |dir| {
            const m = fg.grid.lookup(pv.point.add(dir)) orelse continue;
            const a = fg.grid.lookup(pv.point.add(dir.mult(2))) orelse continue;
            const s = fg.grid.lookup(pv.point.add(dir.mult(3))) orelse continue;
            if (m == 'M' and a == 'A' and s == 'S') {
                christmases += 1;
            }
        }
    }

    try std.testing.expectEqual(2434, christmases);
}

test "part2" {
    var fg = try aoc.grid.openFileGrid(std.testing.allocator, file_path);
    defer fg.deinit();

    var christmases: u16 = 0;

    var it = fg.grid.iterate();
    while (it.next()) |pv| {
        if (pv.value != 'A') {
            continue;
        }

        // a b
        //  p
        // c d

        const a = fg.grid.lookup(pv.point.add(.{ .x = -1, .y = -1 })) orelse continue;
        const b = fg.grid.lookup(pv.point.add(.{ .x = 1, .y = -1 })) orelse continue;
        const c = fg.grid.lookup(pv.point.add(.{ .x = -1, .y = 1 })) orelse continue;
        const d = fg.grid.lookup(pv.point.add(.{ .x = 1, .y = 1 })) orelse continue;

        if (@min(a, d) == 'M' and @max(a, d) == 'S' and @min(b, c) == 'M' and @max(b, c) == 'S') {
            christmases += 1;
        }
    }

    try std.testing.expectEqual(1835, christmases);
}

pub fn main() void {}
