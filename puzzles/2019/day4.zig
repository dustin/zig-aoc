const std = @import("std");
const aoc = @import("aoc");

pub const lowest = 264360;
pub const highest = 746325;

// However, they do remember a few key facts about the password:

//     It is a six-digit number.
//     The value is within the range given in your puzzle input.
//     Two adjacent digits are the same (like 22 in 122345).
//     Going from left to right, the digits never decrease; they only ever increase or stay the same (like 111123 or 135679).

// Other than the range rule, the following are true:

//     111111 meets these criteria (double 11, never decreases).
//     223450 does not meet these criteria (decreasing pair of digits 50).
//     123789 does not meet these criteria (no double).

fn isPassword(p: u32) bool {
    if (p >= 1000000 or p < 100000) return false;

    var r = @divTrunc(p, 10);
    var prev = @mod(p, 10);
    var rpt = false;
    while (r > 0) {
        const d = @mod(r, 10);
        if (d == prev) rpt = true;
        if (d > prev) return false;

        r = @divTrunc(r, 10);
        prev = d;
    }

    return rpt;
}

test "part1 example" {
    try std.testing.expect(isPassword(111111));
    try std.testing.expect(!isPassword(223450));
    try std.testing.expect(!isPassword(123789));
}

test "part1" {
    var count: u16 = 0;
    for (lowest..highest) |p| {
        if (isPassword(@intCast(p))) count += 1;
    }
    try std.testing.expectEqual(945, count);
}

fn digitize(p: u32) [6]u8 {
    var digits: [6]u8 = @splat(0);
    var r = @divTrunc(p, 10);
    var prev = @mod(p, 10);
    var pos: usize = 6;
    while (pos > 0) : (pos -= 1) {
        digits[pos - 1] = '0' + @as(u8, @intCast(prev));
        prev = @mod(r, 10);
        r = @divTrunc(r, 10);
    }

    return digits;
}

test "digitize" {
    const digits = digitize(123456);
    try std.testing.expectEqualStrings("123456", &digits);
}

fn isPassword2(alloc: std.mem.Allocator, p: u32) !bool {
    if (!isPassword(p)) return false;

    const digits = digitize(p);

    const rled = try aoc.list.rle(u8, alloc, &digits);
    defer rled.deinit();

    for (rled.items) |item| {
        if (item.count == 2) return true;
    }
    return false;
}

test "part2" {
    var count: u16 = 0;
    for (lowest..highest) |p| {
        if (try isPassword2(std.testing.allocator, @intCast(p))) count += 1;
    }
    try std.testing.expectEqual(617, count);
}
