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

test intersectSet {
    const K = u32;
    const V = u32;
    const alloc = std.testing.allocator;
    var a = std.AutoHashMap(K, V).init(alloc);
    var b = std.AutoHashMap(K, V).init(alloc);
    defer a.deinit();
    defer b.deinit();
    try a.put(1, 1);
    try a.put(2, 2);
    try b.put(2, 2);
    try b.put(3, 3);
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
    var a = std.AutoHashMap(K, V).init(alloc);
    var b = std.AutoHashMap(K, V).init(alloc);
    defer a.deinit();
    defer b.deinit();
    try a.put(1, 1);
    try a.put(2, 2);
    try a.put(3, 3);
    try b.put(2, 2);
    try b.put(3, 3);
    try b.put(4, 4);
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
    var a = std.AutoHashMap(K, V).init(alloc);
    var b = std.AutoHashMap(K, V).init(alloc);
    defer a.deinit();
    defer b.deinit();
    try a.put(1, 1);
    try a.put(2, 2);
    try a.put(3, 3);
    try b.put(2, 2);
    try b.put(3, 3);
    try b.put(4, 4);
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
    var a = std.AutoHashMap(K, V).init(alloc);
    var b = std.AutoHashMap(K, V).init(alloc);
    defer a.deinit();
    defer b.deinit();
    try a.put(1, 1);
    try a.put(2, 2);
    try a.put(3, 3);
    try b.put(2, 2);
    try b.put(3, 3);
    try b.put(4, 4);
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
    var a = std.AutoHashMap(K, V).init(alloc);
    var b = std.AutoHashMap(K, V).init(alloc);
    defer a.deinit();
    defer b.deinit();
    try a.put(1, 1);
    try a.put(2, 2);
    try a.put(3, 3);
    try b.put(2, 22);
    try b.put(3, 23);
    try b.put(4, 24);
    var res = try difference(K, V, alloc, &a, &b);
    defer res.deinit();
    try std.testing.expectEqual(1, res.count());
    try std.testing.expectEqual(1, res.get(1));
}
