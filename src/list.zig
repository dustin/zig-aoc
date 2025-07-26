pub const std = @import("std");

pub const Error = std.mem.Allocator.Error;

pub fn Counted(comptime T: type) type {
    return struct {
        value: T,
        count: usize,
    };
}

pub fn rle(comptime T: type, alloc: std.mem.Allocator, input: []const T) Error!std.ArrayList(Counted(T)) {
    var res = std.ArrayList(Counted(T)).init(alloc);
    var i: usize = 0;
    while (i < input.len) {
        var count: usize = 1;
        while (i + 1 < input.len and input[i] == input[i + 1]) {
            count += 1;
            i += 1;
        }
        try res.append(.{ .value = input[i], .count = count });
        i += 1;
    }
    return res;
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
