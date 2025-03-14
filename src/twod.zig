const std = @import("std");
const indy = @import("indy.zig");

/// A 2D point is just a two element vector.
pub const Point = @Vector(2, i32);

/// The offset point in a given direction with the north reference.
fn dirOff(north: i32, dir: Dir) Point {
    return switch (dir) {
        .n => .{ 0, north },
        .e => .{ 1, 0 },
        .s => .{ 0, -north },
        .w => .{ -1, 0 },
    };
}

/// Move a point forward in the given direction by the given amount.
pub inline fn fwdBy(p: Point, dir: Dir, a: i32) Point {
    return p + (dirOff(1, dir) * @as(Point, @splat(a)));
}

/// Move a point forward in the given direction by one unit.
pub inline fn fwd(p: Point, dir: Dir) Point {
    return fwdBy(p, dir, 1);
}

/// Forward with north and south reversed.
pub inline fn invFwdBy(p: Point, dir: Dir, a: i32) Point {
    return p + (dirOff(-1, dir) * @as(Point, @splat(a)));
}

/// Forward by one unit with north and south reversed.
pub inline fn invFwd(p: Point, dir: Dir) Point {
    return invFwdBy(p, dir, 1);
}

/// Directions in clockwise order starting from the top.
pub const Dir = enum {
    n,
    e,
    s,
    w,

    pub fn right(d: Dir) Dir {
        switch (d) {
            .n => return .e,
            .e => return .s,
            .s => return .w,
            .w => return .n,
        }
    }

    pub fn left(d: Dir) Dir {
        switch (d) {
            .n => return .w,
            .e => return .n,
            .s => return .e,
            .w => return .s,
        }
    }
};

pub const origin: Point = @splat(0);

test "directions" {
    const zigthesis = @import("zigthesis");

    const T = struct {
        fn turnSymmetry(d: Dir, turns: u4) bool {
            var current = d;
            for (0..turns) |_| {
                current = current.right();
            }
            for (0..turns) |_| {
                current = current.left();
            }
            return current == d;
        }
    };

    try zigthesis.falsifyWith(T.turnSymmetry, "turns can be undone", .{ .max_iterations = 100, .onError = zigthesis.failOnError });
}

test "movement" {
    const zigthesis = @import("zigthesis");

    const T = struct {
        fn movement(d: Dir, p: Point, distance: u4) bool {
            const out = fwdBy(p, d, distance);
            const back = fwdBy(out, d.right().right(), distance);
            return @reduce(.And, p == back);
        }

        fn invMovement(d: Dir, p: Point, distance: u4) bool {
            const out = invFwdBy(p, d, distance);
            const back = invFwdBy(out, d.right().right(), distance);
            return @reduce(.And, p == back);
        }

        fn fwdByfwdEquiv(d: Dir, p: Point, distance: u4) bool {
            const out = fwdBy(p, d, distance);
            var snd = p;
            for (0..distance) |_| {
                snd = fwd(snd, d);
            }
            return indy.mdist(out, snd) == 0;
        }

        fn invFwdByfwdEquiv(d: Dir, p: Point, distance: u4) bool {
            const out = invFwdBy(p, d, distance);
            var snd = p;
            for (0..distance) |_| {
                snd = invFwd(snd, d);
            }
            return indy.mdist(out, snd) == 0;
        }
    };

    try zigthesis.falsifyWith(T.movement, "movement can be undone", .{ .max_iterations = 100, .onError = zigthesis.failOnError });
    try zigthesis.falsifyWith(T.invMovement, "inverted movement can be undone", .{ .max_iterations = 100, .onError = zigthesis.failOnError });
    try zigthesis.falsifyWith(T.fwdByfwdEquiv, "n fwd == fwdBy n", .{ .max_iterations = 100, .onError = zigthesis.failOnError });
    try zigthesis.falsifyWith(T.invFwdByfwdEquiv, "n invFwd == invFwdBy n", .{ .max_iterations = 100, .onError = zigthesis.failOnError });
}

pub fn drawMap(comptime T: type, w: anytype, def: u8, f: fn (T) u8, map: anytype) !void {
    var bounds = indy.newBounds();
    var iter = map.iterator();
    while (iter.next()) |entry| {
        bounds.addPoint(entry.key_ptr.*);
    }

    var y: i32 = bounds.mins[1];
    while (y <= bounds.maxs[1]) : (y += 1) {
        var x: i32 = bounds.mins[0];
        while (x <= bounds.maxs[0]) : (x += 1) {
            const p = Point{.{ x, y }};
            const c = if (map.get(p)) |v| f(v) else def;
            try w.writeByte(c);
        }
        try w.writeByte('\n');
    }
}
