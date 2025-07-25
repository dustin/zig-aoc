const std = @import("std");

const Error = std.mem.Allocator.Error;

/// Intersect two maps key sets ignoring values.
pub fn intersectSet(
    comptime K: type,
    comptime V: type,
    alloc: std.mem.Allocator,
    a: *std.AutoHashMap(K, V),
    b: *std.AutoHashMap(K, V),
) Error!std.AutoHashMap(K, void) {
    return intersect(K, V, void, alloc, a, b, struct {
        fn combine(_: V, _: V) ?void {}
    }.combine);
}

// Create a simple map(u32,u32) with keys from `from` to `to` where each value equals the key.
fn simpleMap(alloc: std.mem.Allocator, from: u32, to: u32) Error!std.AutoHashMap(u32, u32) {
    const T = struct {
        max: u32,
        pub fn next(t: @This(), k: u32) ?u32 {
            if (k == t.max) return null;
            return k + 1;
        }
        pub fn f(_: @This(), x: u32) ?u32 {
            return x;
        }
    };
    const t = T{ .max = to };
    return mkMap(u32, u32, alloc, from, t, T.next, T.f);
}

test intersectSet {
    const K = u32;
    const V = u32;
    const alloc = std.testing.allocator;
    var a = try simpleMap(alloc, 1, 2);
    var b = try simpleMap(alloc, 2, 3);
    defer a.deinit();
    defer b.deinit();
    var res = try intersectSet(K, V, alloc, &a, &b);
    defer res.deinit();
    try std.testing.expectEqual(res.count(), 1);
    try std.testing.expect(res.contains(2));
}

/// Intersect two maps by key set.
pub fn intersect(
    comptime K: type,
    comptime V: type,
    comptime OV: type,
    alloc: std.mem.Allocator,
    a: *std.AutoHashMap(K, V),
    b: *std.AutoHashMap(K, V),
    combine: fn (V, V) ?OV, // If null, don't include this key, else include it with the result of the function.
) Error!std.AutoHashMap(K, OV) {
    var res = std.AutoHashMap(K, OV).init(alloc);
    var it = a.iterator();
    while (it.next()) |e| {
        if (b.get(e.key_ptr.*)) |bval| {
            if (combine(e.value_ptr.*, bval)) |value| {
                try res.put(e.key_ptr.*, value);
            }
        }
    }
    return res;
}

test intersect {
    const K = u32;
    const V = u32;
    const OV = u32;
    const alloc = std.testing.allocator;
    var a = try simpleMap(alloc, 1, 3);
    var b = try simpleMap(alloc, 2, 4);
    defer a.deinit();
    defer b.deinit();
    var res = try intersect(K, V, OV, alloc, &a, &b, struct {
        fn combine(v1: V, v2: V) ?OV {
            if (v1 + v2 > 5) return null; // This prevents 3 from being included in the result.
            return v1 + v2;
        }
    }.combine);
    defer res.deinit();
    try std.testing.expectEqual(res.count(), 1);
    try std.testing.expectEqual(res.get(2), 4);
}

/// Compute the union of two maps by key set.
pub fn unionMap(
    comptime K: type,
    comptime V: type,
    comptime OV: type,
    alloc: std.mem.Allocator,
    a: *std.AutoHashMap(K, V),
    b: *std.AutoHashMap(K, V),
    combine: fn (V, ?V) ?OV, // If null, don't include this key, else include it with the result of the function.
) Error!std.AutoHashMap(K, OV) {
    var res = std.AutoHashMap(K, OV).init(alloc);
    var it = a.iterator();
    while (it.next()) |e| {
        if (b.get(e.key_ptr.*)) |bval| {
            if (combine(e.value_ptr.*, bval)) |value| {
                try res.put(e.key_ptr.*, value);
            }
        } else {
            if (combine(e.value_ptr.*, null)) |value| {
                try res.put(e.key_ptr.*, value);
            }
        }
    }
    it = b.iterator();
    while (it.next()) |e| {
        if (a.get(e.key_ptr.*)) |aval| {
            if (combine(e.value_ptr.*, aval)) |value| {
                try res.put(e.key_ptr.*, value);
            }
        } else {
            if (combine(e.value_ptr.*, null)) |value| {
                try res.put(e.key_ptr.*, value);
            }
        }
    }
    return res;
}

test unionMap {
    const K = u32;
    const V = u32;
    const OV = u32;
    const alloc = std.testing.allocator;
    var a = try simpleMap(alloc, 1, 3);
    var b = try simpleMap(alloc, 2, 4);
    defer a.deinit();
    defer b.deinit();
    var res = try unionMap(K, V, OV, alloc, &a, &b, struct {
        fn combine(v1: V, v2: ?V) ?OV {
            if (v1 + (v2 orelse 0) > 5) return null; // This prevents 3 from being included in the result.
            return v1 + (v2 orelse 0);
        }
    }.combine);
    defer res.deinit();
    try std.testing.expectEqual(3, res.count());
    try std.testing.expectEqual(1, res.get(1));
    try std.testing.expectEqual(4, res.get(2));
    try std.testing.expectEqual(4, res.get(4));
}

/// Construct the union of two maps key sets ignoring values.
pub fn unionSet(
    comptime K: type,
    comptime V: type,
    alloc: std.mem.Allocator,
    a: *std.AutoHashMap(K, V),
    b: *std.AutoHashMap(K, V),
) Error!std.AutoHashMap(K, void) {
    return unionMap(K, V, void, alloc, a, b, struct {
        fn combine(_: V, _: ?V) ?void {}
    }.combine);
}

test unionSet {
    const K = u32;
    const V = u32;
    const alloc = std.testing.allocator;
    var a = try simpleMap(alloc, 1, 3);
    var b = try simpleMap(alloc, 2, 4);
    defer a.deinit();
    defer b.deinit();
    var res = try unionSet(K, V, alloc, &a, &b);
    defer res.deinit();
    try std.testing.expectEqual(4, res.count());
    try std.testing.expectEqual(true, res.contains(1));
    try std.testing.expectEqual(true, res.contains(2));
    try std.testing.expectEqual(true, res.contains(3));
    try std.testing.expectEqual(true, res.contains(4));
}

/// Return all of the entries within 'a' that are not within 'b' (by key).
pub fn difference(
    comptime K: type,
    comptime V: type,
    alloc: std.mem.Allocator,
    a: *std.AutoHashMap(K, V),
    b: *std.AutoHashMap(K, V),
) Error!std.AutoHashMap(K, V) {
    var res = std.AutoHashMap(K, V).init(alloc);
    var it = a.iterator();
    while (it.next()) |e| {
        if (!b.contains(e.key_ptr.*)) {
            try res.put(e.key_ptr.*, e.value_ptr.*);
        }
    }
    return res;
}

test difference {
    const K = u32;
    const V = u32;
    const alloc = std.testing.allocator;
    const T = struct {
        max: K,
        offset: u32 = 0,
        pub fn next(t: @This(), k: K) ?K {
            if (k == t.max) return null;
            return k + 1;
        }
        pub fn f(t: @This(), x: K) ?V {
            return x + t.offset;
        }
    };
    var t = T{ .max = 3 };
    var a = try mkMap(K, V, alloc, 1, t, T.next, T.f);
    t.max = 4;
    t.offset = 10;
    var b = try mkMap(K, V, alloc, 2, t, T.next, T.f);

    defer a.deinit();
    defer b.deinit();

    var res = try difference(K, V, alloc, &a, &b);
    defer res.deinit();
    try std.testing.expectEqual(1, res.count());
    try std.testing.expectEqual(1, res.get(1));
}

pub fn mkMap(
    comptime K: type,
    comptime V: type,
    alloc: std.mem.Allocator,
    from: K,
    ctx: anytype,
    next: fn (ctx: @TypeOf(ctx), k: K) ?K,
    f: fn (ctx: @TypeOf(ctx), x: K) ?V,
) Error!std.AutoHashMap(K, V) {
    var res = std.AutoHashMap(K, V).init(alloc);
    var k = from;
    while (true) {
        if (f(ctx, k)) |e| try res.put(k, e);
        k = next(ctx, k) orelse break;
    }
    return res;
}
