const std = @import("std");

pub const OutOfMemory = error{OutOfMemory};

/// Flood fill a region of space, starting from a point and using a function to determine the neighbors.
pub fn flood(
    comptime T: type,
    alloc: std.mem.Allocator,
    context: anytype,
    start: anytype,
    comptime nf: fn (@TypeOf(context), @TypeOf(start), *std.ArrayList(T)) OutOfMemory!void,
    res: *std.AutoHashMap(T, void),
) !void {
    var queue = std.ArrayList(T).init(alloc);
    defer queue.deinit();
    try queue.append(start);
    while (queue.pop()) |current| {
        if (res.get(current)) |_| continue;
        try res.put(current, {});

        var stalloc = std.heap.stackFallback(1024, alloc);
        var neighbor_list = std.ArrayList(T).init(stalloc.get());
        defer neighbor_list.deinit();
        try nf(context, current, &neighbor_list);

        for (neighbor_list.items) |neighbor| {
            try queue.append(neighbor);
        }
    }
}

test flood {
    const Points = struct {
        pub fn neighbs(ctx: i32, point: [2]i32, neighbors: *std.ArrayList([2]i32)) OutOfMemory!void {
            if (point[0] < 10 and point[0] >= 0) {
                if (point[0] + 1 == ctx) {
                    try neighbors.append(.{ point[0] + 2, point[1] });
                } else {
                    try neighbors.append(.{ point[0] + 1, point[1] });
                }
                if (point[0] - 1 != ctx) {
                    try neighbors.append(.{ point[0] - 1, point[1] });
                }
            }
        }
    };

    const allocator = std.testing.allocator;
    var res = std.AutoHashMap([2]i32, void).init(allocator);
    defer res.deinit();
    try flood([2]i32, allocator, @as(i32, 5), [2]i32{ 0, 0 }, Points.neighbs, &res);
    try std.testing.expectEqual(11, res.count());
}

/// Do a BFS, calling into a function with each found neighbor.
pub fn bfs(
    comptime T: type,
    alloc: std.mem.Allocator,
    context: anytype,
    start: T,
    comptime nf: fn (@TypeOf(context), @TypeOf(start), *std.ArrayList(T)) OutOfMemory!void,
    comptime found: fn (@TypeOf(context), @TypeOf(start)) OutOfMemory!bool, // if true, stop searching
) OutOfMemory!void {
    var queue = std.ArrayList(T).init(alloc);
    defer queue.deinit();
    try queue.append(start);
    if (try found(context, start)) return;
    while (queue.pop()) |current| {
        var stalloc = std.heap.stackFallback(1024, alloc);
        var neighbor_list = std.ArrayList(T).init(stalloc.get());
        defer neighbor_list.deinit();
        try nf(context, current, &neighbor_list);

        for (neighbor_list.items) |neighbor| {
            if (try found(context, neighbor)) return;
            try queue.append(neighbor);
        }
    }
}

test bfs {
    const T = struct {
        latest: ?[2]i32 = null,
        target: i32 = 0,

        pub fn neighbs(_: *@This(), point: [2]i32, neighbors: *std.ArrayList([2]i32)) OutOfMemory!void {
            if (point[0] < 10 and point[0] >= 0) {
                try neighbors.append(.{ point[0] + 1, point[1] + 1 });
            }
        }

        pub fn found(ctx: *@This(), point: [2]i32) OutOfMemory!bool {
            ctx.latest = point;
            return point[0] == ctx.target;
        }
    };

    const allocator = std.testing.allocator;
    var tee = T{ .target = 5 };
    try bfs([2]i32, allocator, &tee, [2]i32{ 0, 0 }, T.neighbs, T.found);
    try std.testing.expectEqual([2]i32{ 5, 5 }, tee.latest.?);
}
