const std = @import("std");
const aoc = @import("aoc");

const V = struct {
    start: u64,
    end: u64,
};

fn parseInput(alloc: std.mem.Allocator, in: []const u8) !std.ArrayList(V) {
    var rv = try std.ArrayList(V).initCapacity(alloc, 100);
    var ranges = std.mem.splitSequence(u8, in, ",");
    while (ranges.next()) |range| {
        var it = std.mem.splitSequence(u8, range, "-");
        const a = try aoc.input.parseInt(u64, it.next() orelse return error.ParseError);
        const b = try aoc.input.parseInt(u64, it.next() orelse return error.ParseError);
        try rv.append(alloc, .{ .start = a, .end = b });
    }
    return rv;
}

const exampleStr: []const u8 = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124";

const inputStr: []const u8 = "26803-38596,161-351,37-56,9945663-10044587,350019-413817,5252508299-5252534634,38145069-38162596,1747127-1881019,609816-640411,207466-230638,18904-25781,131637-190261,438347308-438525264,5124157617-5124298820,68670991-68710448,8282798062-8282867198,2942-5251,659813-676399,57-99,5857600742-5857691960,9898925025-9899040061,745821-835116,2056-2782,686588904-686792094,5487438-5622255,325224-347154,352-630,244657-315699,459409-500499,639-918,78943-106934,3260856-3442902,3-20,887467-1022885,975-1863,5897-13354,43667065-43786338";

fn dlength(xin: u64) usize {
    var rv: usize = 0;
    var x = xin;
    while (x > 0) : (x /= 10) {
        rv += 1;
    }
    return rv;
}

const Repeater = struct {
    n: u64,
    reps: usize,

    fn increment(r: *@This()) void {
        r.n += 1;
    }

    fn value(r: *@This()) u64 {
        var rv = r.n;
        const w = @as(u64, @intCast(dlength(r.n)));
        for (1..r.reps) |_| {
            rv = rv * std.math.pow(u64, 10, w) + r.n;
        }
        return rv;
    }
};

test "repeater" {
    var r = Repeater{ .n = 123, .reps = 2 };
    r.increment();
    try std.testing.expectEqual(124124, r.value());
}

fn mkRepeater(n: u64, reps: usize) ?Repeater {
    const w = dlength(n);
    if (@mod(w, reps) != 0) {
        return null;
    }
    const sz = w / reps;
    const off = w - sz;
    return Repeater{ .n = n / std.math.pow(u64, 10, @as(u64, @intCast(off))), .reps = reps };
}

test mkRepeater {
    const r2 = mkRepeater(123456, 2).?;
    try std.testing.expectEqual(123, r2.n);
    try std.testing.expectEqual(2, r2.reps);
    const r3 = mkRepeater(123456, 3).?;
    try std.testing.expectEqual(12, r3.n);
    try std.testing.expectEqual(3, r3.reps);
}

fn fitStart(x: u64, target: usize) u64 {
    if (dlength(x) == target) {
        return x;
    }
    return std.math.pow(u64, 10, @as(u64, target - 1));
}

fn doubles(v: V) u64 {
    var target = dlength(v.start);
    if (@mod(target, 2) == 1) {
        target += 1;
    }
    const start = fitStart(v.start, target);

    var r = mkRepeater(start, 2) orelse return 0;

    var rv: u64 = 0;

    while (true) {
        const dbl = r.value();
        r.increment();
        if (dbl < start) {
            continue;
        }
        if (dbl > v.end) {
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
    var example = try parseInput(std.testing.allocator, exampleStr);
    defer example.deinit(std.testing.allocator);
    try std.testing.expectEqual(1227775554, count(example.items));
}

test "part1" {
    var input = try parseInput(std.testing.allocator, inputStr);
    defer input.deinit(std.testing.allocator);
    try std.testing.expectEqual(22062284697, count(input.items));
}

fn doubles2(seen: *std.AutoHashMap(u64, void), v: V, len: usize, reps: usize) u64 {
    if (len == 0) {
        return 0;
    }
    var r: Repeater = .{ .n = std.math.pow(u64, 10, @as(u64, len - 1)), .reps = reps };

    var rv: u64 = 0;

    while (true) {
        const dbl = r.value();
        r.increment();
        if (dbl < v.start) {
            continue;
        }
        if (dbl > v.end) {
            return rv;
        }
        if (seen.get(dbl)) |_| continue;
        seen.put(dbl, {}) catch {};
        // std.debug.print("Match: {}\n", .{dbl});
        rv += dbl;
    }

    return rv;
}

fn allGroups(alloc: std.mem.Allocator, v: V) u64 {
    var rv: u64 = 0;
    var seen = std.AutoHashMap(u64, void).init(alloc);
    defer seen.deinit();

    const magdiff = dlength(v.start) != dlength(v.end);

    for (2..dlength(v.end) + 1) |l| {
        rv += doubles2(&seen, v, dlength(v.start) / l, l);
        if (magdiff) {
            rv += doubles2(&seen, v, dlength(v.end) / l, l);
        }
    }
    return rv;
}

fn count2(alloc: std.mem.Allocator, ns: []const V) u64 {
    var rv: u64 = 0;
    for (ns) |v| {
        rv += allGroups(alloc, v);
    }
    return rv;
}

test "part2ex" {
    var example = try parseInput(std.testing.allocator, exampleStr);
    defer example.deinit(std.testing.allocator);
    try std.testing.expectEqual(4174379265, count2(std.testing.allocator, example.items));
}

test "part2" {
    var example = try parseInput(std.testing.allocator, inputStr);
    defer example.deinit(std.testing.allocator);
    try std.testing.expectEqual(46666175279, count2(std.testing.allocator, example.items));
}
