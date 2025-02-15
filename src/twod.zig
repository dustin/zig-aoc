const std = @import("std");

const Point = struct {
    x: i32,
    y: i32,

    /// Manhattan distance between this point and that point.
    pub fn dist(this: @This(), that: Point) u32 {
        return @abs(this.x - that.x) + @abs(this.y - that.y);
    }

    /// Add this point to that point.
    pub fn add(this: @This(), p: Point) Point {
        return Point{ .x = this.x + p.x, .y = this.y + p.y };
    }

    /// Multiply this point by a scalar (i.e. x*a, y*a).
    pub fn mult(this: @This(), a: i32) Point {
        return Point{ .x = this.x * a, .y = this.y * a };
    }

    /// The offset point in a given direction with the north reference.
    fn dirOff(_: @This(), north: i32, dir: Dir) Point {
        return switch (dir) {
            .n => .{ .x = 0, .y = north },
            .e => .{ .x = 1, .y = 0 },
            .s => .{ .x = 0, .y = -north },
            .w => .{ .x = -1, .y = 0 },
        };
    }

    pub fn fwdBy(this: @This(), dir: Dir, a: i32) Point {
        return this.add(this.dirOff(1, dir).mult(a));
    }

    pub fn fwd(this: @This(), dir: Dir) Point {
        return this.fwdBy(dir, 1);
    }

    /// Forward with north and south reversed.
    pub fn invFwdBy(this: @This(), dir: Dir, a: i32) Point {
        return this.add(this.dirOff(-1, dir).mult(a));
    }

    pub fn invFwd(this: @This(), dir: Dir) Point {
        return this.invFwdBy(dir, 1);
    }
};

/// Find the points around a given point in clockwise order starting from the top.
fn around(p: Point) [4]Point {
    return .{
        .{ .x = p.x, .y = p.y - 1 },
        .{ .x = p.x + 1, .y = p.y },
        .{ .x = p.x, .y = p.y + 1 },
        .{ .x = p.x - 1, .y = p.y },
    };
}

test around {
    const p = Point{ .x = 0, .y = 0 };
    const expected = .{
        Point{ .x = 0, .y = -1 },
        Point{ .x = 1, .y = 0 },
        Point{ .x = 0, .y = 1 },
        Point{ .x = -1, .y = 0 },
    };
    try std.testing.expectEqualDeep(expected, around(p));
}

/// Points surrounding the given point, including diagonals.
fn aroundD(p: Point) [8]Point {
    return .{
        .{ .x = p.x - 1, .y = p.y - 1 },
        .{ .x = p.x, .y = p.y - 1 },
        .{ .x = p.x + 1, .y = p.y - 1 },
        .{ .x = p.x + 1, .y = p.y },
        .{ .x = p.x + 1, .y = p.y + 1 },
        .{ .x = p.x, .y = p.y + 1 },
        .{ .x = p.x - 1, .y = p.y + 1 },
        .{ .x = p.x - 1, .y = p.y },
    };
}

test aroundD {
    const p = Point{ .x = 0, .y = 0 };
    const expected = .{
        Point{ .x = -1, .y = -1 },
        Point{ .x = 0, .y = -1 },
        Point{ .x = 1, .y = -1 },
        Point{ .x = 1, .y = 0 },
        Point{ .x = 1, .y = 1 },
        Point{ .x = 0, .y = 1 },
        Point{ .x = -1, .y = 1 },
        Point{ .x = -1, .y = 0 },
    };
    try std.testing.expectEqualDeep(expected, aroundD(p));
}

/// Directions in clockwise order starting from the top.
const Dir = enum {
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
            const out = p.fwdBy(d, distance);
            const back = out.fwdBy(d.right().right(), distance);
            return p.x == back.x and p.y == back.y;
        }

        fn invMovement(d: Dir, p: Point, distance: u4) bool {
            const out = p.invFwdBy(d, distance);
            const back = out.invFwdBy(d.right().right(), distance);
            return p.x == back.x and p.y == back.y;
        }

        fn fwdByfwdEquiv(d: Dir, p: Point, distance: u4) bool {
            const out = p.fwdBy(d, distance);
            var snd = p;
            for (0..distance) |_| {
                snd = snd.fwd(d);
            }
            return out.dist(snd) == 0;
        }

        fn invFwdByfwdEquiv(d: Dir, p: Point, distance: u4) bool {
            const out = p.invFwdBy(d, distance);
            var snd = p;
            for (0..distance) |_| {
                snd = snd.invFwd(d);
            }
            return out.dist(snd) == 0;
        }
    };

    try zigthesis.falsifyWith(T.movement, "movement can be undone", .{ .max_iterations = 100, .onError = zigthesis.failOnError });
    try zigthesis.falsifyWith(T.invMovement, "inverted movement can be undone", .{ .max_iterations = 100, .onError = zigthesis.failOnError });
    try zigthesis.falsifyWith(T.fwdByfwdEquiv, "n fwd == fwdBy n", .{ .max_iterations = 100, .onError = zigthesis.failOnError });
    try zigthesis.falsifyWith(T.invFwdByfwdEquiv, "n invFwd == invFwdBy n", .{ .max_iterations = 100, .onError = zigthesis.failOnError });
}
