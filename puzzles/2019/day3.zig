const std = @import("std");
const aoc = @import("aoc");

const Path = std.AutoHashMap(aoc.twod.Point, u32);

fn readDirections(f: std.fs.File.Reader, res: *Path) !void {
    var more: bool = true;
    var pos: aoc.twod.Point = .{ 0, 0 };
    var steps: u32 = 0;
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
            steps += 1;
            pos = aoc.twod.fwd(pos, dir);
            _ = try res.getOrPutValue(pos, steps);
        }
    }
}

const Error = std.mem.Allocator.Error;

fn processFile(comptime T: type, alloc: std.mem.Allocator, path: []const u8, f: fn (std.mem.Allocator, *Path, *Path) Error!T) !T {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const reader = file.reader();

    var arena = try alloc.create(std.heap.ArenaAllocator);
    defer alloc.destroy(arena);
    arena.* = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    const aalloc = arena.allocator();

    var wire1 = std.AutoHashMap(aoc.twod.Point, u32).init(aalloc);
    try readDirections(reader, &wire1);
    var wire2 = std.AutoHashMap(aoc.twod.Point, u32).init(aalloc);
    try readDirections(reader, &wire2);

    return f(aalloc, &wire1, &wire2);
}

test "part1" {
    const T = struct {
        fn process(alloc: std.mem.Allocator, w1: *Path, w2: *Path) Error!u32 {
            var i = try aoc.set.intersectSet(aoc.twod.Point, u32, alloc, w1, w2);
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

test "part2" {
    const T = struct {
        fn combine(a: u32, b: u32) ?u32 {
            return a + b;
        }
        fn process(alloc: std.mem.Allocator, w1: *Path, w2: *Path) Error!u32 {
            var i = try aoc.set.intersect(aoc.twod.Point, u32, u32, alloc, w1, w2, @This().combine);
            var it = i.iterator();
            var ans: u32 = std.math.maxInt(u32);
            while (it.next()) |e| {
                ans = @min(ans, e.value_ptr.*);
            }
            return ans;
        }
    };

    const totes = try processFile(u32, std.testing.allocator, "input/2019/day3", T.process);
    try std.testing.expectEqual(10554, totes);
}
