const std = @import("std");
const twod = @import("twod.zig");

pub const GridIterator = struct {
    grid: Grid,
    point: twod.Point,
    value: u8,

    pub fn next(this: *GridIterator) bool {
        if (this.point.x == this.grid.bounds.maxX and this.point.y == this.grid.bounds.maxY) {
            return false;
        }
        if (this.point.x == this.grid.bounds.maxX) {
            this.point.x = 0;
            this.point.y += 1;
        } else {
            this.point.x += 1;
        }
        this.value = this.grid.lookup(this.point).?;
        return true;
    }
};

pub const Grid = struct {
    bounds: twod.Bounds,
    bytes: []const u8,

    pub fn lookup(this: Grid, p: twod.Point) ?u8 {
        if (!this.bounds.contains(p)) {
            return null;
        }
        const index = p.y * (this.bounds.maxX + 2) + p.x;
        return this.bytes[@intCast(index)];
    }

    pub fn iterate(this: @This()) GridIterator {
        return .{ .grid = this, .point = .{ .x = -1, .y = 0 }, .value = this.bytes[0] };
    }
};

/// Parse a grid from a string.
pub fn parseGrid(input: []const u8) ?Grid {
    const nl = std.mem.indexOf(u8, input, "\n") orelse return null;

    const g = Grid{ .bounds = twod.Bounds{
        .minX = 0,
        .minY = 0,
        .maxX = @as(i32, @intCast(nl)) - 1,
        .maxY = @intCast(input.len / (nl + 1) - 1),
    }, .bytes = input };

    // sanity check the grid newlines line up
    for (@intCast(g.bounds.minY)..@intCast(g.bounds.maxY)) |y| {
        const off: usize = @intCast(y * @as(usize, @intCast(g.bounds.maxX + 2)) + @as(usize, @intCast(g.bounds.maxX)) + 1);
        if (input[off] != '\n') {
            return null;
        }
    }

    return g;
}

test parseGrid {
    const input = "ABC\nDEF\nGHI\n";
    const grid = parseGrid(input).?;
    const expected = Grid{
        .bounds = twod.Bounds{
            .minX = 0,
            .minY = 0,
            .maxX = 2,
            .maxY = 2,
        },
        .bytes = input,
    };
    try std.testing.expectEqual(expected, grid);
    try std.testing.expectEqual('F', grid.lookup(.{ .x = 2, .y = 1 }).?);
    try std.testing.expectEqual(null, grid.lookup(.{ .x = 3, .y = 1 }));

    var it = grid.iterate();
    while (it.next()) {
        std.debug.print("({d},{d}): {c}\n", .{ it.point.x, it.point.y, it.value });
    }
}
