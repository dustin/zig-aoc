const std = @import("std");

/// Compute the Manhattan distance between two points in arbitrary dimensional space.
pub fn mdist(a: anytype, b: @TypeOf(a)) u32 {
    return @reduce(.Add, @abs(a - b));
}

test mdist {
    const a = @Vector(2, i32){ 1, 2 };
    const b = @Vector(2, i32){ 3, 4 };
    try std.testing.expectEqual(mdist(a, b), 4);

    const x = @Vector(3, i32){ 1, 2, 3 };
    const y = @Vector(3, i32){ 4, 5, 6 };
    try std.testing.expectEqual(mdist(x, y), 9);
}

/// Returns just the orthogonal neighbors (neighbors that differ in exactly one dimension)
pub fn around(p: anytype) [2 * @typeInfo(@TypeOf(p)).vector.len](@TypeOf(p)) {
    const P = @TypeOf(p);
    const dimensions = @typeInfo(P).vector.len;

    var result: [2 * @typeInfo(P).vector.len]P = @splat(p);
    var index: usize = 0;

    inline for (0..dimensions) |d| {
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
