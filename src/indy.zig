const std = @import("std");

/// Compute the Manhattan distance between two points in arbitrary dimensional space.
pub inline fn mdist(a: anytype, b: @TypeOf(a)) std.meta.Int(.unsigned, @typeInfo(@typeInfo(@TypeOf(a)).vector.child).int.bits + 1) {
    return @reduce(.Add, @abs(a - b));
}

test mdist {
    const a = @Vector(2, i32){ 1, 2 };
    const b = @Vector(2, i32){ 3, 4 };
    try std.testing.expectEqual(mdist(a, b), 4);

    const x = @Vector(3, i64){ 1, 2, 3 };
    const y = @Vector(3, i64){ 4, 5, 6 };
    try std.testing.expectEqual(mdist(x, y), 9);
}

/// Euclidean Distance
pub inline fn edist(a: anytype, b: @TypeOf(a)) f64 {
    const diffs = a - b;
    return @sqrt(@as(f64, @floatFromInt(@reduce(.Add, diffs * diffs))));
}

test edist {
    const a = @Vector(3, i32){ 162, 817, 812 };
    const b = @Vector(3, i32){ 425, 690, 689 };
    try std.testing.expectApproxEqRel(edist(a, b), 316.9, 0.1);
}

/// Returns just the orthogonal neighbors (neighbors that differ in exactly one dimension)
pub fn around(p: anytype) [2 * @typeInfo(@TypeOf(p)).vector.len](@TypeOf(p)) {
    const P = @TypeOf(p);
    const dimensions = @typeInfo(P).vector.len;

    var result: [2 * @typeInfo(P).vector.len]P = @splat(p);
    var index: usize = 0;

    for (0..dimensions) |d| {
        result[index][d] = p[d] - 1;
        index += 1;
        result[index][d] = p[d] + 1;
        index += 1;
    }

    return result;
}

test "around a point" {
    const p = @Vector(2, i32){ 0, 0 };
    const expected: [4]@Vector(2, i32) = .{
        .{ -1, 0 },
        .{ 1, 0 },
        .{ 0, -1 },
        .{ 0, 1 },
    };
    try std.testing.expectEqualDeep(expected, around(p));

    // also works for 3D vectors.
    const p3d = @Vector(3, i32){ 0, 0, 0 };
    const expected3d: [6]@Vector(3, i32) = .{
        .{ -1, 0, 0 },
        .{ 1, 0, 0 },
        .{ 0, -1, 0 },
        .{ 0, 1, 0 },
        .{ 0, 0, -1 },
        .{ 0, 0, 1 },
    };
    try std.testing.expectEqualDeep(expected3d, around(p3d));
}

/// Return all neighbors including diagonals.
pub fn aroundD(p: anytype) [std.math.pow(usize, 3, @typeInfo(@TypeOf(p)).vector.len) - 1](@TypeOf(p)) {
    const P = @TypeOf(p);
    const dimensions = @typeInfo(P).vector.len;
    var result: [std.math.pow(usize, 3, dimensions) - 1]P = @splat(p);
    var count: usize = 0;

    var offsets: @TypeOf(p) = @splat(-1);
    const zero: @TypeOf(p) = @splat(0);

    while (count < result.len) {
        // Add this point if it's not the original
        if (!@reduce(.And, offsets == zero)) {
            result[count] += offsets;
            count += 1;
        }

        // Generate next combination (like counting in base 3)
        for (0..dimensions) |i| {
            offsets[i] += 1;
            if (offsets[i] > 1) {
                offsets[i] = -1;
            } else {
                break;
            }
        }
    }

    return result;
}

test aroundD {
    const p2 = @Vector(2, i32){ 0, 0 };
    const got = aroundD(p2);
    const expected2: [8]@Vector(2, i32) = .{
        .{ -1, -1 },
        .{ 0, -1 },
        .{ 1, -1 },
        .{ -1, 0 },
        .{ 1, 0 },
        .{ -1, 1 },
        .{ 0, 1 },
        .{ 1, 1 },
    };
    try std.testing.expectEqualDeep(expected2, got);
}

/// Bounds for arbitrary dimenional space.
pub fn Bounds(comptime N: usize) type {
    return struct {
        mins: @Vector(N, i32),
        maxs: @Vector(N, i32),

        pub fn add(this: *@This(), p: @Vector(N, i32)) void {
            this.mins = @min(this.mins, p);
            this.maxs = @max(this.maxs, p);
        }

        pub fn contains(this: @This(), p: @Vector(N, i32)) bool {
            return !(@reduce(.Or, p < this.mins) or @reduce(.Or, p > this.maxs));
        }
    };
}

pub fn newBounds(comptime N: usize) Bounds(N) {
    return Bounds(N){
        .mins = @splat(std.math.maxInt(i32)),
        .maxs = @splat(std.math.minInt(i32)),
    };
}

test "bounds checking" {
    var b = newBounds(2);
    b.add(.{ 0, 0 });
    b.add(.{ 1, 1 });
    b.add(.{ -1, -1 });
    try std.testing.expectEqual(2, b.maxs[0] - b.mins[0]);
    try std.testing.expectEqual(2, b.maxs[1] - b.mins[1]);
    try std.testing.expect(b.contains(.{ 0, 0 }));
    try std.testing.expect(!b.contains(.{ 3, 1 }));
}
