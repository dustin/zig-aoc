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
