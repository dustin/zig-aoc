const std = @import("std");
const aoc = @import("aoc");

const Path = std.AutoHashMap(aoc.twod.Point, void);

fn readDirections(f: std.fs.File.Reader, res: *Path) !void {
    var more: bool = true;
    var pos: aoc.twod.Point = .{ 0, 0 };
    while (more) {
        const b = f.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        var dir: aoc.twod.Dir = undefined;
        switch (b) {
            'L' => dir = .w,
            'R' => dir = .e,
            'U' => dir = .n,
            'D' => dir = .s,
            '\n' => return,
            else => return error.InvalidDirection,
        }
        var amt: usize = 0;
        while (true) {
            const d = f.readByte() catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };
            if (d == ',') break;
            if (d == '\n') {
                more = false;
                break;
            }
            if (d < '0' or d > '9') return error.InvalidDigit;
            amt = amt * 10 + @as(usize, d - '0');
        }

        for (0..amt) |_| {
            pos = aoc.twod.fwd(pos, dir);
            try res.put(pos, {});
        }
    }
}

const Error = std.mem.Allocator.Error;

fn intersect(comptime K: type, alloc: std.mem.Allocator, a: *std.AutoHashMap(K, void), b: *std.AutoHashMap(K, void)) Error!std.AutoHashMap(K, void) {
    var res = std.AutoHashMap(K, void).init(alloc);
    var it = a.keyIterator();
    while (it.next()) |key| {
        if (b.contains(key.*)) {
            try res.put(key.*, {});
        }
    }
    return res;
}

fn processFile(comptime T: type, alloc: std.mem.Allocator, path: []const u8, f: fn (std.mem.Allocator, *Path, *Path) Error!T) !T {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const reader = file.reader();

    var arena = try alloc.create(std.heap.ArenaAllocator);
    defer alloc.destroy(arena);
    arena.* = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    const aalloc = arena.allocator();

    var wire1 = std.AutoHashMap(aoc.twod.Point, void).init(aalloc);
    try readDirections(reader, &wire1);
    var wire2 = std.AutoHashMap(aoc.twod.Point, void).init(aalloc);
    try readDirections(reader, &wire2);

    return f(aalloc, &wire1, &wire2);
}

test "part1" {
    const T = struct {
        fn process(alloc: std.mem.Allocator, w1: *Path, w2: *Path) Error!u32 {
            var i = try intersect(aoc.twod.Point, alloc, w1, w2);
            var it = i.keyIterator();
            var ans: u32 = std.math.maxInt(u32);
            const origin: aoc.twod.Point = .{ 0, 0 };
            while (it.next()) |p| {
                ans = @min(ans, aoc.indy.mdist(origin, p.*));
            }
            return ans;
        }
    };

    const totes = try processFile(u32, std.testing.allocator, "input/2019/day3", T.process);
    try std.testing.expectEqual(280, totes);
}
