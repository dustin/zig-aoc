const std = @import("std");
const indy = @import("indy.zig");

pub const Point = struct {
    p: @Vector(2, i32),

    pub fn x(this: @This()) i32 {
        return this.p[0];
    }

    pub fn y(this: @This()) i32 {
        return this.p[1];
    }

    /// Manhattan distance between this point and that point.
    pub fn dist(this: @This(), that: Point) u32 {
        return indy.mdist(this.p, that.p);
    }

    /// Add this point to that point.
    pub fn add(this: @This(), p: Point) Point {
        return .{ .p = this.p + p.p };
    }

    /// Multiply this point by a scalar (i.e. x*a, y*a).
    pub fn mult(this: @This(), a: i32) Point {
        const av: @Vector(2, i32) = @splat(a);
        return .{ .p = this.p * av };
    }

    /// The offset point in a given direction with the north reference.
    fn dirOff(_: @This(), north: i32, dir: Dir) Point {
        return switch (dir) {
            .n => newPoint(0, north),
            .e => newPoint(1, 0),
            .s => newPoint(0, -north),
            .w => newPoint(-1, 0),
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

    pub fn around(p: @This()) [4]Point {
        var rv: [4]Point = undefined;
        for (indy.around(p.p), 0..) |np, i| {
            rv[i] = .{ .p = np };
        }
        return rv;
    }

    /// Points surrounding the given point, including diagonals.
    pub fn aroundD(p: @This()) [8]Point {
        return .{
            .{ .p = p.p + newPoint(-1, -1).p },
            .{ .p = p.p + newPoint(0, -1).p },
            .{ .p = p.p + newPoint(1, -1).p },
            .{ .p = p.p + newPoint(1, 0).p },
            .{ .p = p.p + newPoint(1, 1).p },
            .{ .p = p.p + newPoint(0, 1).p },
            .{ .p = p.p + newPoint(-1, 1).p },
            .{ .p = p.p + newPoint(-1, 0).p },
        };
    }
};

test "around a point diagonally" {
    const p = origin;

    const expected = .{
        newPoint(-1, -1),
        newPoint(0, -1),
        newPoint(1, -1),
        newPoint(1, 0),
        newPoint(1, 1),
        newPoint(0, 1),
        newPoint(-1, 1),
        newPoint(-1, 0),
    };
    try std.testing.expectEqualDeep(expected, p.aroundD());
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

pub fn newPoint(x: i32, y: i32) Point {
    return Point{ .p = @Vector(2, i32){ x, y } };
}

pub const origin = newPoint(0, 0);

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
            return @reduce(.And, p.p == back.p);
        }

        fn invMovement(d: Dir, p: Point, distance: u4) bool {
            const out = p.invFwdBy(d, distance);
            const back = out.invFwdBy(d.right().right(), distance);
            return @reduce(.And, p.p == back.p);
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

pub const Bounds = struct {
    b: indy.Bounds(2),

    pub fn minX(this: @This()) i32 {
        return this.b.mins[0];
    }

    pub fn minY(this: @This()) i32 {
        return this.b.mins[1];
    }

    pub fn maxX(this: @This()) i32 {
        return this.b.maxs[0];
    }

    pub fn maxY(this: @This()) i32 {
        return this.b.maxs[1];
    }

    pub fn addPoint(this: *@This(), p: Point) void {
        this.b.add(p.p);
    }

    pub fn contains(this: @This(), p: Point) bool {
        return this.b.contains(p.p);
    }
};

pub fn newBounds() Bounds {
    return .{ .b = indy.newBounds(2) };
}

test "bounds checking" {
    var b: Bounds = newBounds();
    b.addPoint(origin);
    b.addPoint(newPoint(1, 1));
    b.addPoint(newPoint(-1, -1));
    try std.testing.expectEqual(2, b.maxX() - b.minX());
    try std.testing.expectEqual(2, b.maxY() - b.minY());
}

pub fn drawMap(comptime T: type, w: anytype, def: u8, f: fn (T) u8, map: anytype) !void {
    var bounds = newBounds();
    var iter = map.iterator();
    while (iter.next()) |entry| {
        bounds.addPoint(entry.key_ptr.*);
    }

    var y: i32 = bounds.minY();
    while (y <= bounds.maxY()) : (y += 1) {
        var x: i32 = bounds.minX();
        while (x <= bounds.maxX()) : (x += 1) {
            const p = Point{.{ x, y }};
            const c = if (map.get(p)) |v| f(v) else def;
            try w.writeByte(c);
        }
        try w.writeByte('\n');
    }
}
