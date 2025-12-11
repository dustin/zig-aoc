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
) OutOfMemory!void {
    var queue = try std.ArrayList(T).initCapacity(alloc, 1024);
    defer queue.deinit(alloc);
    try queue.append(alloc, start);
    var fallback = std.heap.stackFallback(1024, alloc);
    const stalloc = fallback.get();

    while (queue.pop()) |current| {
        if (res.get(current)) |_| continue;
        try res.put(current, {});

        var neighbor_list = try std.ArrayList(T).initCapacity(stalloc, 8);
        defer neighbor_list.deinit(stalloc);
        try nf(context, current, &neighbor_list);

        for (neighbor_list.items) |neighbor| {
            try queue.append(alloc, neighbor);
        }
    }
}

test flood {
    const P = @Vector(2, i32);
    const Points = struct {
        pub fn neighbs(ctx: i32, point: P, neighbors: *std.ArrayList(P)) OutOfMemory!void {
            if (point[0] < 10 and point[0] >= 0) {
                if (point[0] + 1 == ctx) {
                    try neighbors.append(std.testing.allocator, .{ point[0] + 2, point[1] });
                } else {
                    try neighbors.append(std.testing.allocator, .{ point[0] + 1, point[1] });
                }
                if (point[0] - 1 != ctx) {
                    try neighbors.append(std.testing.allocator, .{ point[0] - 1, point[1] });
                }
            }
        }
    };

    const allocator = std.testing.allocator;
    var res = std.AutoHashMap(P, void).init(allocator);
    defer res.deinit();
    try flood(P, allocator, @as(i32, 5), P{ 0, 0 }, Points.neighbs, &res);
    try std.testing.expectEqual(11, res.count());
}

/// Do a BFS, calling into a function with each found neighbor.
pub fn bfs(
    comptime T: type,
    comptime R: type,
    alloc: std.mem.Allocator,
    context: anytype,
    start: T,
    comptime rf: fn (@TypeOf(context), @TypeOf(start)) R,
    comptime nf: fn (@TypeOf(context), @TypeOf(start), *std.ArrayList(T)) OutOfMemory!void,
    comptime found: fn (@TypeOf(context), @TypeOf(start)) OutOfMemory!bool, // if true, stop searching
) OutOfMemory!void {
    var queue = try std.ArrayList(T).initCapacity(alloc, 1024);
    defer queue.deinit(alloc);
    var seen = std.AutoHashMap(R, void).init(alloc);
    defer seen.deinit();
    try queue.append(alloc, start);
    try seen.put(rf(context, start), {});
    if (try found(context, start)) return;
    var fallback = std.heap.stackFallback(1024, alloc);
    const stalloc = fallback.get();
    while (queue.items.len > 0) {
        const current = queue.orderedRemove(0);
        var neighbor_list = try std.ArrayList(T).initCapacity(stalloc, 8);
        defer neighbor_list.deinit(stalloc);
        try nf(context, current, &neighbor_list);

        for (neighbor_list.items) |neighbor| {
            if (seen.get(rf(context, neighbor))) |_| continue;
            if (try found(context, neighbor)) return;
            try seen.put(rf(context, neighbor), {});
            try queue.append(alloc, neighbor);
        }
    }
}

test bfs {
    const P = @Vector(2, i32);

    const T = struct {
        latest: ?P = null,
        target: i32 = 0,

        pub fn neighbs(_: *@This(), point: P, neighbors: *std.ArrayList(P)) OutOfMemory!void {
            if (point[0] < 10 and point[0] >= 0) {
                try neighbors.append(std.testing.allocator, .{ point[0] + 1, point[1] + 1 });
            }
        }

        pub fn rf(_: *@This(), p: P) i32 {
            return p[0];
        }

        pub fn found(ctx: *@This(), point: P) OutOfMemory!bool {
            ctx.latest = point;
            return point[0] == ctx.target;
        }
    };

    const allocator = std.testing.allocator;
    var tee = T{ .target = 5 };
    try bfs(P, i32, allocator, &tee, P{ 0, 0 }, T.rf, T.neighbs, T.found);
    try std.testing.expectEqual(P{ 5, 5 }, tee.latest.?);
}

pub fn Node(comptime T: type) type {
    return struct {
        cost: i32,
        heuristic: i32,
        val: T,

        fn comp(_: void, a: @This(), b: @This()) std.math.Order {
            return std.math.order(a.cost + a.heuristic, b.cost + b.heuristic);
        }
    };
}

pub fn AStarResult(comptime T: type, comptime R: type) type {
    return struct {
        cost: i32,
        val: ?T,
        alloc: std.mem.Allocator,
        scores: std.AutoHashMap(R, struct { i32, R }),

        fn init(alloc: std.mem.Allocator) @This() {
            return .{
                .cost = 0,
                .val = null,
                .alloc = alloc,
                .scores = std.AutoHashMap(R, struct { i32, R }).init(alloc),
            };
        }

        pub fn deinit(self: *@This()) void {
            self.scores.deinit();
        }

        pub fn resolve(self: *@This(), alloc: std.mem.Allocator, start: R, end: R) OutOfMemory!?struct { i32, []R } {
            const mend = self.scores.get(end);
            if (mend == null) return null;
            const finalScore = mend.?.@"0";

            var res = try std.ArrayList(R).initCapacity(alloc, 10);
            try res.append(alloc, end);
            var current = end;
            while (true) {
                if (std.meta.eql(current, start)) {
                    break;
                }
                const next = self.scores.get(current);
                if (next) |n| {
                    try res.insert(self.alloc, 0, n.@"1");
                    current = n.@"1";
                } else {
                    break;
                }
            }

            return .{ finalScore, try res.toOwnedSlice(alloc) };
        }
    };
}

/// Do a A* search, calling into a function with each found neighbor.
pub fn astar(
    comptime T: type,
    comptime R: type,
    alloc: std.mem.Allocator,
    context: anytype,
    start: T,
    comptime rf: fn (@TypeOf(context), @TypeOf(start)) R,
    comptime nf: fn (@TypeOf(context), @TypeOf(start), *std.ArrayList(Node(T))) OutOfMemory!void,
    comptime found: fn (@TypeOf(context), @TypeOf(start)) OutOfMemory!bool, // if true, stop searching
) OutOfMemory!AStarResult(T, R) {
    var queue = std.PriorityQueue(Node(T), void, Node(T).comp).init(alloc, {});
    defer queue.deinit();
    var res = AStarResult(T, R).init(alloc);
    errdefer res.deinit();
    try queue.add(.{ .cost = 0, .heuristic = 0, .val = start });

    var fallback = std.heap.stackFallback(1024, alloc);
    const stalloc = fallback.get();
    while (queue.removeOrNull()) |node| {
        if (try found(context, node.val)) {
            res.cost = node.cost;
            res.val = node.val;
            return res;
        }

        var neighbor_list = try std.ArrayList(Node(T)).initCapacity(stalloc, 8);
        defer neighbor_list.deinit(stalloc);
        try nf(context, node.val, &neighbor_list);

        for (neighbor_list.items) |n| {
            const r = rf(context, n.val);
            if (res.scores.get(r)) |existing| {
                if (existing.@"0" <= node.cost + n.cost) {
                    continue;
                }
            }
            try res.scores.put(r, .{ node.cost + n.cost, rf(context, node.val) });
            try queue.add(.{ .cost = node.cost + n.cost, .heuristic = n.heuristic, .val = n.val });
        }
    }
    return res;
}

test astar {
    const NT = @Vector(2, i32);
    const T = struct {
        target: i32 = 0,

        pub fn nf(_: *@This(), point: NT, neighbors: *std.ArrayList(Node(NT))) OutOfMemory!void {
            try neighbors.append(std.testing.allocator, .{ .cost = 1, .heuristic = 1, .val = .{ point[0] + 1, point[1] + 1 } });
            try neighbors.append(std.testing.allocator, .{ .cost = 1, .heuristic = 0, .val = .{ point[0] + 1, point[1] - 1 } });
            try neighbors.append(std.testing.allocator, .{ .cost = 1, .heuristic = 0, .val = .{ point[0] - 1, point[1] + 1 } });
            try neighbors.append(std.testing.allocator, .{ .cost = 1, .heuristic = 0, .val = .{ point[0] - 1, point[1] - 1 } });
        }
        pub fn rf(_: *@This(), p: NT) NT {
            return p;
        }

        pub fn found(ctx: *@This(), point: NT) OutOfMemory!bool {
            return point[0] == ctx.target;
        }
    };

    const allocator = std.testing.allocator;
    var tee = T{ .target = 5 };
    var res = try astar(NT, NT, allocator, &tee, NT{ 0, 0 }, T.rf, T.nf, T.found);
    defer res.deinit();

    try std.testing.expectEqual(5, res.cost);
    if (try res.resolve(allocator, NT{ 0, 0 }, NT{ 5, 5 })) |p| {
        defer allocator.free(p.@"1");
        try std.testing.expectEqual(p.@"0", 5);
        var exp = [_]NT{ .{ 0, 0 }, .{ 1, 1 }, .{ 2, 2 }, .{ 3, 3 }, .{ 4, 4 }, .{ 5, 5 } };
        try std.testing.expectEqualSlices(NT, &exp, p.@"1");
    }
}

pub fn binSearch(
    comptime T: type,
    context: anytype,
    comptime compareFn: fn (@TypeOf(context), T) std.math.Order,
    l: T,
    h: T,
) T {
    var low: T = l;
    var high: T = h;

    while (high >= low) {
        const mid = low + @divTrunc((high - low), 2);
        switch (compareFn(context, mid)) {
            .gt => high = (mid - 1),
            .lt => low = (mid + 1),
            .eq => return mid,
        }
    }
    return low;
}

test "binary search" {
    const zigthesis = @import("zigthesis");

    const T = struct {
        val: i32 = 0,

        pub fn compare(this: @This(), val: i32) std.math.Order {
            return std.math.order(val, this.val);
        }

        pub fn sortProp(in: [3]i32) bool {
            var abc = in;
            std.sort.pdq(i32, abc[0..], {}, std.sort.asc(i32));
            const i = @This(){ .val = abc[1] };
            return binSearch(i32, i, @This().compare, abc[0], abc[1]) == abc[1];
        }
    };

    try zigthesis.falsifyWith(T.sortProp, "sorts sort", .{ .max_iterations = 100, .onError = zigthesis.failOnError });
}

pub fn autoBinSearch(
    comptime T: type,
    context: anytype,
    comptime compareFn: fn (@TypeOf(context), T) std.math.Order,
) T {
    const dir = compareFn(context, 0);
    var p: T = 0;
    var l: T = 0;
    var o: T = 1;

    const typeInfo = @typeInfo(T);
    if (typeInfo == .int and typeInfo.int.signedness == .signed) {
        o = if (dir == .lt) 1 else -1;
    }

    while (true) {
        const v = compareFn(context, l);
        if (v == .eq) return l;
        if (v == dir) {
            p = l;
            l += o;
            o *= 10;
        } else {
            return binSearch(T, context, compareFn, @min(p, l), @max(p, l));
        }
    }
}

test "auto binary search" {
    const zigthesis = @import("zigthesis");

    const T = struct {
        val: i32 = 0,

        pub fn compare(this: @This(), val: i32) std.math.Order {
            return std.math.order(val, this.val);
        }

        pub fn autoSortProp(in: i32) bool {
            const i = @This(){ .val = in };
            return autoBinSearch(i32, i, @This().compare) == in;
        }
    };

    try zigthesis.falsifyWith(T.autoSortProp, "auto sorts sort", .{ .max_iterations = 100, .onError = zigthesis.failOnError });
}

// This actually blows all kinds of up on edge cases with numbers that are too large or too small.
test "fuzz auto bin" {
    const T = struct {
        val: i32 = 0,

        pub fn compare(this: @This(), val: i32) std.math.Order {
            return std.math.order(val, this.val);
        }

        pub fn autoSortProp(_: i32, in: []const u8) anyerror!void {
            if (in.len < 4) {
                return {};
            }

            const ptr: *const [4]u8 = @ptrCast(in.ptr);
            const val = std.mem.readInt(i32, ptr, .little);
            const i = @This(){ .val = val };
            try std.testing.expectEqual(val, autoBinSearch(i32, i, @This().compare));
        }
    };

    try std.testing.fuzz(@as(i32, 0), T.autoSortProp, .{});
}
