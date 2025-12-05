const std = @import("std");
const twod = @import("twod.zig");
const indy = @import("indy.zig");

pub const PointValue = struct {
    point: twod.Point,
    value: u8,
};

pub fn GridIterator(T: type) type {
    return struct {
        grid: T,
        point: twod.Point,

        pub fn next(this: *@This()) ?PointValue {
            if (@reduce(.And, this.point == this.grid.bounds.maxs)) {
                return null;
            }
            if (this.point[0] == this.grid.bounds.maxs[0]) {
                this.point[0] = 0;
                this.point[1] += 1;
            } else {
                this.point[0] += 1;
            }
            if (this.grid.lookup(this.point)) |v| {
                return .{ .point = this.point, .value = v };
            }
            return null;
        }
    };
}

pub fn RowIterator(T: type) type {
    return struct {
        grid: T,
        rnum: usize,

        pub fn next(this: *@This()) ?[]const u8 {
            defer this.rnum += 1;
            return this.grid.row(this.rnum);
        }
    };
}

pub const Grid = struct {
    bounds: indy.Bounds(2),
    bytes: []const u8,

    pub fn lookup(this: Grid, p: twod.Point) ?u8 {
        if (!this.bounds.contains(p)) {
            return null;
        }
        const index = p[1] * (this.bounds.maxs[0] + 2) + p[0];
        return this.bytes[@intCast(index)];
    }

    pub fn iterate(this: @This()) GridIterator(Grid) {
        return .{ .grid = this, .point = .{ -1, 0 } };
    }

    pub fn mutable(this: @This(), alloc: std.mem.Allocator) !MutableGrid {
        return MutableGrid{ .bounds = this.bounds, .bytes = try alloc.dupe(u8, this.bytes) };
    }

    pub fn row(this: @This(), rowNum: usize) ?[]const u8 {
        const start: usize = rowNum * @as(usize, @intCast(this.bounds.maxs[0] + 2));
        const end: usize = 1 + start + @as(usize, @intCast(this.bounds.maxs[0]));

        if (end > this.bytes.len) {
            return null;
        }

        return this.bytes[start..end];
    }

    pub fn rows(this: @This()) RowIterator(@This()) {
        return .{ .grid = this, .rnum = 0 };
    }
};

pub const MutableGrid = struct {
    bounds: indy.Bounds(2),
    bytes: []u8,

    pub fn lookup(this: @This(), p: twod.Point) ?u8 {
        if (!this.bounds.contains(p)) {
            return null;
        }
        const index = p[1] * (this.bounds.maxs[0] + 2) + p[0];
        return this.bytes[@intCast(index)];
    }

    pub fn set(this: @This(), p: twod.Point, v: u8) void {
        if (!this.bounds.contains(p)) {
            return;
        }
        const index = p[1] * (this.bounds.maxs[0] + 2) + p[0];
        this.bytes[@intCast(index)] = v;
    }

    pub fn iterate(this: @This()) GridIterator(MutableGrid) {
        return .{ .grid = this, .point = .{ -1, 0 } };
    }

    pub fn deinit(this: @This(), alloc: std.mem.Allocator) void {
        alloc.free(this.bytes);
    }
};

/// Parse a grid from a string.
pub fn parseGrid(input: []const u8) ?Grid {
    const nl = std.mem.indexOf(u8, input, "\n") orelse return null;

    const g = Grid{ .bounds = .{ .mins = @splat(0), .maxs = @Vector(2, i32){
        @as(i32, @intCast(nl)) - 1,
        @intCast(input.len / (nl + 1) - 1),
    } }, .bytes = input };

    // sanity check the grid newlines line up
    for (@intCast(g.bounds.mins[1])..@intCast(g.bounds.maxs[1])) |y| {
        const off: usize = @intCast(y * @as(usize, @intCast(g.bounds.maxs[0] + 2)) + @as(usize, @intCast(g.bounds.maxs[0])) + 1);
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
        .bounds = .{ .mins = @splat(0), .maxs = @splat(2) },

        .bytes = input,
    };
    try std.testing.expectEqual(expected, grid);
    try std.testing.expectEqual('F', grid.lookup(.{ 2, 1 }).?);
    try std.testing.expectEqual(null, grid.lookup(.{ 3, 1 }));

    const Item = struct { x: i32, y: i32, v: u8 };

    var al = std.ArrayList(Item).initCapacity(std.testing.allocator, 9) catch unreachable;
    defer al.deinit(std.testing.allocator);
    var it = grid.iterate();
    while (it.next()) |pv| {
        try std.testing.expectEqual(pv.value, grid.lookup(pv.point));
        try al.append(std.testing.allocator, Item{ .x = pv.point[0], .y = pv.point[1], .v = pv.value });
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

    if (grid.row(1)) |r| {
        try std.testing.expectEqualSlices(u8, "DEF", r);
    } else {
        return error.OOB;
    }
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
    var buf: [8192]u8 = undefined;
    var reader = file.reader(buf[0..]);
    var ri = &reader.interface;

    var w = std.Io.Writer.Allocating.init(alloc);
    defer w.deinit();
    _ = try ri.streamRemaining(&w.writer);

    return FileGrid{
        .alloc = alloc,
        .grid = parseGrid(try w.toOwnedSlice()) orelse return error.ParseError,
    };
}

test openFileGrid {
    var fg = try openFileGrid(std.testing.allocator, "input/2024/day4.ex");
    defer fg.deinit();
    try std.testing.expectEqual('X', fg.grid.lookup(.{ 4, 1 }).?);
}
