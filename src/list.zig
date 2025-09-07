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
