const std = @import("std");
const aoc = @import("aoc");

const V = struct {
    start: u64,
    end: u64,
};

const example = [_]V{
    // 11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
    .{ .start = 11, .end = 22 }, .{ .start = 95, .end = 115 }, .{ .start = 998, .end = 1012 }, .{ .start = 1188511880, .end = 1188511890 }, .{ .start = 222220, .end = 222224 }, .{ .start = 1698522, .end = 1698528 }, .{ .start = 446443, .end = 446449 }, .{ .start = 38593856, .end = 38593862 }, .{ .start = 565653, .end = 565659 }, .{ .start = 824824821, .end = 824824827 }, .{ .start = 2121212118, .end = 2121212124 },
};

const input = [_]V{
    // 26803-38596,161-351,37-56,9945663-10044587,350019-413817,5252508299-5252534634,38145069-38162596,1747127-1881019,609816-640411,207466-230638,18904-25781,131637-190261,438347308-438525264,5124157617-5124298820,68670991-68710448,8282798062-8282867198,2942-5251,659813-676399,57-99,5857600742-5857691960,9898925025-9899040061,745821-835116,2056-2782,686588904-686792094,5487438-5622255,325224-347154,352-630,244657-315699,459409-500499,639-918,78943-106934,3260856-3442902,3-20,887467-1022885,975-1863,5897-13354,43667065-43786338
    .{ .start = 26803, .end = 38596 },
    .{ .start = 161, .end = 351 },
    .{ .start = 37, .end = 56 },
    .{ .start = 9945663, .end = 10044587 },
    .{ .start = 350019, .end = 413817 },
    .{ .start = 5252508299, .end = 5252534634 },
    .{ .start = 38145069, .end = 38162596 },
    .{ .start = 1747127, .end = 1881019 },
    .{ .start = 609816, .end = 640411 },
    .{ .start = 207466, .end = 230638 },
    .{ .start = 18904, .end = 25781 },
    .{ .start = 131637, .end = 190261 },
    .{ .start = 438347308, .end = 438525264 },
    .{ .start = 5124157617, .end = 5124298820 },
    .{ .start = 68670991, .end = 68710448 },
    .{ .start = 8282798062, .end = 8282867198 },
    .{ .start = 2942, .end = 5251 },
    .{ .start = 659813, .end = 676399 },
    .{ .start = 57, .end = 99 },
    .{ .start = 5857600742, .end = 5857691960 },
    .{ .start = 9898925025, .end = 9899040061 },
    .{ .start = 745821, .end = 835116 },
    .{ .start = 2056, .end = 2782 },
    .{ .start = 686588904, .end = 686792094 },
    .{ .start = 5487438, .end = 5622255 },
    .{ .start = 325224, .end = 347154 },
    .{ .start = 352, .end = 630 },
    .{ .start = 244657, .end = 315699 },
    .{ .start = 459409, .end = 500499 },
    .{ .start = 639, .end = 918 },
    .{ .start = 78943, .end = 106934 },
    .{ .start = 3260856, .end = 3442902 },
    .{ .start = 3, .end = 20 },
    .{ .start = 887467, .end = 1022885 },
    .{ .start = 975, .end = 1863 },
    .{ .start = 5897, .end = 13354 },
    .{ .start = 43667065, .end = 43786338 },
};

fn dlength(xin: u64) usize {
    var rv: usize = 0;
    var x = xin;
    while (x > 0) : (x /= 10) {
        rv += 1;
    }
    return rv;
}

fn isOdd(x: usize) bool {
    return @mod(x, 2) == 1;
}

fn dblNum(x: u64) u64 {
    return (x * std.math.pow(u64, 10, @as(u64, @intCast(dlength(x))))) + x;
}

fn doubles(v: V) u64 {
    var start = v.start;
    if (isOdd(dlength(start))) {
        start = std.math.pow(u64, 10, @as(u64, @intCast(dlength(start))));
    }
    var end = v.end;
    if (isOdd(dlength(end))) {
        end = std.math.pow(u64, 10, @as(u64, @intCast(dlength(end))) - 1) - 1;
    }
    var halfNum = start / std.math.pow(u64, 10, @as(u64, @intCast(dlength(start))) / 2);

    var rv: u64 = 0;

    while (true) {
        const dbl = dblNum(halfNum);
        halfNum += 1;
        if (dbl < start) {
            continue;
        }
        if (dbl > end) {
            return rv;
        }
        rv += dbl;
    }

    return rv;
}

fn count(ns: []const V) u64 {
    var rv: u64 = 0;
    for (ns) |v| {
        rv += doubles(v);
    }
    return rv;
}

test "part1ex" {
    try std.testing.expectEqual(1227775554, count(&example));
}

test "part1" {
    try std.testing.expectEqual(22062284697, count(&input));
}
