const std = @import("std");
const twod = @import("twod.zig");

pub const PointValue = struct {
    point: twod.Point,
    value: u8,
};

pub const GridIterator = struct {
    grid: Grid,
    point: twod.Point,

    pub fn next(this: *GridIterator) ?PointValue {
        if (this.point.x == this.grid.bounds.maxX and this.point.y == this.grid.bounds.maxY) {
            return null;
        }
        if (this.point.x == this.grid.bounds.maxX) {
            this.point.x = 0;
            this.point.y += 1;
        } else {
            this.point.x += 1;
        }
        if (this.grid.lookup(this.point)) |v| {
            return .{ .point = this.point, .value = v };
        }
        return null;
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
        return .{ .grid = this, .point = .{ .x = -1, .y = 0 } };
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
    const grid = parseGrid(input) orelse return error.ParseError;
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

    const Item = struct { x: i32, y: i32, v: u8 };

    var al = std.ArrayList(Item).init(std.testing.allocator);
    defer al.deinit();
    var it = grid.iterate();
    while (it.next()) |pv| {
        try std.testing.expectEqual(pv.value, grid.lookup(pv.point));
        try al.append(Item{ .x = pv.point.x, .y = pv.point.y, .v = pv.value });
    }
    const exp = [_]Item{
        .{ .x = 0, .y = 0, .v = 'A' },
        .{ .x = 1, .y = 0, .v = 'B' },
        .{ .x = 2, .y = 0, .v = 'C' },
        .{ .x = 0, .y = 1, .v = 'D' },
        .{ .x = 1, .y = 1, .v = 'E' },
        .{ .x = 2, .y = 1, .v = 'F' },
        .{ .x = 0, .y = 2, .v = 'G' },
        .{ .x = 1, .y = 2, .v = 'H' },
        .{ .x = 2, .y = 2, .v = 'I' },
    };
    try std.testing.expectEqualSlices(Item, &exp, al.items);
}

/// A grid parsed from a file.
pub const FileGrid = struct {
    alloc: std.mem.Allocator,
    grid: Grid,

    pub fn deinit(this: *FileGrid) void {
        this.alloc.free(this.grid.bytes);
    }
};

/// Open a file and parse it as a grid.
pub fn openFileGrid(alloc: std.mem.Allocator, path: []const u8) !FileGrid {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const contents = try file.readToEndAlloc(alloc, 65536);

    return FileGrid{
        .alloc = alloc,
        .grid = parseGrid(contents) orelse return error.ParseError,
    };
}

test openFileGrid {
    var fg = try openFileGrid(std.testing.allocator, "input/2024/day4.ex");
    defer fg.deinit();
    try std.testing.expectEqual('X', fg.grid.lookup(.{ .x = 4, .y = 1 }).?);
}
