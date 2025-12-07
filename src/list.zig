pub const std = @import("std");

pub const Error = std.mem.Allocator.Error;

/// A single RLE element.
pub fn Counted(comptime T: type) type {
    return struct {
        value: T,
        count: usize,
    };
}

/// A typed identify function.
pub inline fn identity(comptime T: type) fn (t: T) T {
    return struct {
        fn id(t: T) T {
            return t;
        }
    }.id;
}

/// Perform run length encoding on a slice of elements where equality is determined comparison to the 'r' function.
pub fn rleOn(comptime T: type, comptime R: type, alloc: std.mem.Allocator, r: fn (T) R, input: []const T) Error!std.ArrayList(Counted(T)) {
    var res = try std.ArrayList(Counted(T)).initCapacity(alloc, input.len);
    var i: usize = 0;
    while (i < input.len) {
        var count: usize = 1;
        while (i + 1 < input.len and r(input[i]) == r(input[i + 1])) : ({
            count += 1;
            i += 1;
        }) {}
        try res.append(alloc, .{ .value = input[i], .count = count });
        i += 1;
    }
    return res;
}

test rleOn {
    var rled = try rleOn(u8, u8, std.testing.allocator, std.ascii.toUpper, "ABBCCDEFfF");
    defer rled.deinit(std.testing.allocator);

    const want = [_]Counted(u8){
        .{ .value = 'A', .count = 1 },
        .{ .value = 'B', .count = 2 },
        .{ .value = 'C', .count = 2 },
        .{ .value = 'D', .count = 1 },
        .{ .value = 'E', .count = 1 },
        .{ .value = 'F', .count = 3 },
    };

    try std.testing.expectEqualDeep(&want, rled.items);
}

/// Simple run length encoding on a slice of element.
pub fn rle(comptime T: type, alloc: std.mem.Allocator, input: []const T) Error!std.ArrayList(Counted(T)) {
    return rleOn(T, T, alloc, identity(T), input);
}

test rle {
    var rled = try rle(u8, std.testing.allocator, "ABBCCDEFFF");
    defer rled.deinit(std.testing.allocator);

    const want = [_]Counted(u8){
        .{ .value = 'A', .count = 1 },
        .{ .value = 'B', .count = 2 },
        .{ .value = 'C', .count = 2 },
        .{ .value = 'D', .count = 1 },
        .{ .value = 'E', .count = 1 },
        .{ .value = 'F', .count = 3 },
    };

    try std.testing.expectEqualDeep(&want, rled.items);
}

fn expand(comptime T: type, alloc: std.mem.Allocator, input: []const Counted(T)) Error!std.ArrayList(T) {
    var expanded = try std.ArrayList(T).initCapacity(alloc, input.len);
    for (input) |item| {
        try expanded.appendNTimes(alloc, item.value, item.count);
    }
    return expanded;
}

test expand {
    const input = [_]Counted(u8){
        .{ .value = 'A', .count = 1 },
        .{ .value = 'B', .count = 2 },
        .{ .value = 'C', .count = 2 },
        .{ .value = 'D', .count = 1 },
        .{ .value = 'E', .count = 1 },
        .{ .value = 'F', .count = 3 },
    };

    const expected = "ABBCCDEFFF";
    var actual = try expand(u8, std.testing.allocator, &input);
    defer actual.deinit(std.testing.allocator);

    try std.testing.expectEqualSlices(u8, expected, actual.items);
}

test "fuzz rle" {
    const T = struct {
        pub fn compDecomp(_: i32, in: []const u8) anyerror!void {
            var rled = try rle(u8, std.testing.allocator, in);
            defer rled.deinit(std.testing.allocator);
            var decoded = try expand(u8, std.testing.allocator, rled.items);
            defer decoded.deinit(std.testing.allocator);
            try std.testing.expectEqualSlices(u8, in, decoded.items);
        }
    };

    try std.testing.fuzz(@as(i32, 0), T.compDecomp, .{});
}

/// Transpose a slice of slices.  If lenghts are different, only the smallest will be considered.
pub fn transpose(comptime T: type, alloc: std.mem.Allocator, orig: [][]const T, def: ?T) Error!([][]T) {
    if (orig.len == 0) {
        return try (alloc.alloc([]T, 0));
    }
    var newWidth: usize = orig[0].len;
    for (orig) |o| {
        if (def == null) {
            if (o.len < newWidth) newWidth = o.len;
        } else {
            if (o.len > newWidth) newWidth = o.len;
        }
    }
    var rv = try alloc.alloc([]T, newWidth);
    for (0..newWidth) |w| {
        rv[w] = try alloc.alloc(T, orig.len);
        for (0..orig.len) |h| {
            if (orig[h].len > w) {
                rv[w][h] = orig[h][w];
            } else {
                rv[w][h] = def.?;
            }
        }
    }
    return rv;
}

test "transpose regular" {
    const a: [2][3]i8 = .{ .{ 1, 2, 3 }, .{ 4, 5, 6 } };
    const want: [3][2]i8 = .{ .{ 1, 4 }, .{ 2, 5 }, .{ 3, 6 } };

    const a_slice = [_][]const i8{ &a[0], &a[1] };
    const a_slice_ptr: [][]const i8 = @ptrCast(@constCast(a_slice[0..]));

    const r = try transpose(i8, std.testing.allocator, a_slice_ptr, null);

    defer {
        for (r) |row| {
            std.testing.allocator.free(row);
        }
        std.testing.allocator.free(r);
    }

    try std.testing.expectEqual(@as(usize, 3), r.len);
    for (want, 0..) |w, i| {
        try std.testing.expectEqualSlices(i8, &w, r[i]);
    }
}

test "transpose irregular (no default)" {
    const a1: [3]i8 = .{ 1, 2, 3 };
    const a2: [4]i8 = .{ 4, 5, 6, 7 };
    const a: [2][]const i8 = .{ a1[0..], a2[0..] };
    const want: [3][2]i8 = .{ .{ 1, 4 }, .{ 2, 5 }, .{ 3, 6 } };

    const a_slice = [_][]const i8{ a[0], a[1] };
    const a_slice_ptr: [][]const i8 = @ptrCast(@constCast(a_slice[0..]));

    const r = try transpose(i8, std.testing.allocator, a_slice_ptr, null);

    defer {
        for (r) |row| {
            std.testing.allocator.free(row);
        }
        std.testing.allocator.free(r);
    }

    try std.testing.expectEqual(@as(usize, 3), r.len);
    for (want, 0..) |w, i| {
        try std.testing.expectEqualSlices(i8, &w, r[i]);
    }
}

test "transpose irregular (with default)" {
    const a1: [3]i8 = .{ 1, 2, 3 };
    const a2: [4]i8 = .{ 4, 5, 6, 7 };
    const a: [2][]const i8 = .{ a1[0..], a2[0..] };
    const want: [4][2]i8 = .{ .{ 1, 4 }, .{ 2, 5 }, .{ 3, 6 }, .{ -1, 7 } };

    const a_slice = [_][]const i8{ a[0], a[1] };
    const a_slice_ptr: [][]const i8 = @ptrCast(@constCast(a_slice[0..]));

    const r = try transpose(i8, std.testing.allocator, a_slice_ptr, -1);

    defer {
        for (r) |row| {
            std.testing.allocator.free(row);
        }
        std.testing.allocator.free(r);
    }

    try std.testing.expectEqual(@as(usize, 4), r.len);
    for (want, 0..) |w, i| {
        try std.testing.expectEqualSlices(i8, &w, r[i]);
    }
}
