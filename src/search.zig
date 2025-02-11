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
    while (queue.popOrNull()) |current| {
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
