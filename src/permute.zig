const std = @import("std");

// Stolen from https://github.com/travisstaloch/combinatorics.zig

const fact_table_size_128 = 35;
const fact_table_size_64 = 21;

const fact_table64 =
    blk: {
        var tbl64: [fact_table_size_64]u64 = undefined;
        tbl64[0] = 1;
        var n: u64 = 1;
        while (n < fact_table_size_64) : (n += 1) {
            tbl64[n] = tbl64[n - 1] * n;
        }
        break :blk tbl64;
    };

const fact_table128 =
    blk: {
        var tbl128: [fact_table_size_128]u128 = undefined;
        tbl128[0] = 1;
        var n: u128 = 1;
        while (n < fact_table_size_128) : (n += 1) {
            tbl128[n] = tbl128[n - 1] * n;
        }
        break :blk tbl128;
    };

pub const Error = error{ ArgumentBounds, Domain, Overflow, OutOfBoundsAccess };

fn factorial(comptime T: type, n: anytype) Error!T {
    const TI = @typeInfo(T);
    return try switch (TI) {
        .int => if (TI.int.bits <= 64)
            factorialLookup(T, n, fact_table64, fact_table_size_64)
        else if (TI.int.bits <= 128)
            factorialLookup(T, n, fact_table128, fact_table_size_128)
        else
            @compileError("factorial not implemented for integer type " ++ @typeName(T)),
        else => @compileError("factorial not implemented for non-integer type " ++ @typeName(T)),
    };
}

fn factorialLookup(comptime T: type, n: anytype, table: anytype, limit: anytype) Error!T {
    if (n < 0) return error.Domain;
    if (n > limit) return error.Overflow;
    if (n >= table.len) return error.OutOfBoundsAccess;
    const TI = @typeInfo(T);
    const TUnsigned = std.meta.Int(.unsigned, @min(TI.int.bits, 64));
    const f = table[@as(TUnsigned, @intCast(n))];
    return @intCast(f);
}

pub fn nthperm(a: anytype, n: u128) Error!void {
    if (a.len == 0) return;

    var f = try factorial(u128, a.len);
    if (n > f) return error.ArgumentBounds;

    var i: usize = 0;
    var nmut = @as(u128, n);
    while (i < a.len) : (i += 1) {
        f = f / (a.len - i);
        var j = nmut / f;
        nmut -= j * f;
        j += i;
        const jidx = @as(usize, @intCast(j));
        if (jidx >= a.len) return error.OutOfBoundsAccess;
        const elt = a[jidx];
        var d = jidx;
        while (d >= i + 1) : (d -= 1)
            a[d] = a[d - 1];
        a[i] = elt;
    }
}

test "factorial" {
    inline for (.{
        .{ i8, 5, 120 },
        .{ u8, 5, 120 },
        .{ i16, 7, 5040 },
        .{ u16, 8, 40320 },
        .{ i32, 12, 479001600 },
        .{ u32, 12, 479001600 },
        .{ i64, 20, 2432902008176640000 },
        .{ u64, 20, 2432902008176640000 },
        .{ isize, 20, 2432902008176640000 },
        .{ usize, 20, 2432902008176640000 },
        .{ i128, 33, 8683317618811886495518194401280000000 },
        .{ u128, 34, 295232799039604140847618609643520000000 },
    }) |s| {
        const T = s[0];
        const max = s[1];
        const expected = s[2];
        const actual = try factorial(T, @as(usize, max));
        try std.testing.expectEqual(@as(T, expected), actual);
    }
}

/// for sets of length 35 and less
pub fn Permutations(comptime T: type) type {
    return struct {
        i: usize,
        initial_state: []const T,
        /// must be at least as long as initial state.
        /// initial_state will be copied to this buffer each time next() is called.
        buf: []T,
        const Self = @This();

        pub fn init(initial_state: []const T, buf: []T) Self {
            return .{ .i = 0, .initial_state = initial_state, .buf = buf };
        }

        pub fn next(self: *Self) ?[]const T {
            std.mem.copyForwards(T, self.buf, self.initial_state);
            nthperm(self.buf, @as(u128, @intCast(self.i))) catch return null;
            self.i += 1;
            return self.buf;
        }
    };
}

test "Permutations iterator" {
    const expecteds: []const []const u8 = &.{ "ABCA", "ABAC", "ACBA", "ACAB", "AABC", "AACB", "BACA", "BAAC", "BCAA", "BCAA", "BAAC", "BACA", "CABA", "CAAB", "CBAA", "CBAA", "CAAB", "CABA", "AABC", "AACB", "ABAC", "ABCA", "ACAB", "ACBA" };
    var buf: [4]u8 = undefined;
    var it = Permutations(u8).init("ABCA", &buf);
    var i: u8 = 0;
    while (it.next()) |actual| : (i += 1) {
        const expected = expecteds[i];
        try std.testing.expectEqualStrings(expected, actual);
    }
}
