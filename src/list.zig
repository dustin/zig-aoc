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
pub fn identity(comptime T: type) fn (t: T) T {
    return struct {
        fn id(t: T) T {
            return t;
        }
    }.id;
}

/// Perform run length encoding on a slice of elements where equality is determined comparison to the 'r' function.
pub fn rleOn(comptime T: type, comptime R: type, alloc: std.mem.Allocator, r: fn (T) R, input: []const T) Error!std.ArrayList(Counted(T)) {
    var res = std.ArrayList(Counted(T)).init(alloc);
    var i: usize = 0;
    while (i < input.len) {
        var count: usize = 1;
        while (i + 1 < input.len and r(input[i]) == r(input[i + 1])) : ({
            count += 1;
            i += 1;
        }) {}
        try res.append(.{ .value = input[i], .count = count });
        i += 1;
    }
    return res;
}

test rleOn {
    const rled = try rleOn(u8, u8, std.testing.allocator, std.ascii.toUpper, "ABBCCDEFfF");
    defer rled.deinit();

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
    const rled = try rle(u8, std.testing.allocator, "ABBCCDEFFF");
    defer rled.deinit();

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

test "fuzz rle" {
    const T = struct {
        pub fn compDecomp(_: i32, in: []const u8) anyerror!void {
            const rled = try rle(u8, std.testing.allocator, in);
            defer rled.deinit();
            var decoded = try std.testing.allocator.alloc(u8, rled.items.len);
            defer std.testing.allocator.free(decoded);
            var out: usize = 0;
            for (rled.items) |item| {
                for (0..item.count) |_| {
                    decoded[out] = item.value;
                    out += 1;
                }
            }
            try std.testing.expectEqualSlices(u8, in, decoded);
        }
    };

    try std.testing.fuzz(@as(i32, 0), T.compDecomp, .{});
}
