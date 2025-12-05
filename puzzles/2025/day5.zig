const std = @import("std");
const aoc = @import("aoc");

const Range = struct {
    start: u64,
    end: u64,

    fn contains(this: @This(), x: u64) bool {
        return x >= this.start and x <= this.end;
    }

    fn overlaps(this: @This(), that: @This()) bool {
        return this.start <= that.end and that.start <= this.end;
    }

    fn merge(this: @This(), that: @This()) Range {
        const anustart = if (this.start < that.start) this.start else that.start;
        const anuend = if (this.end > that.end) this.end else that.end;
        return Range{ .start = anustart, .end = anuend };
    }

    fn size(this: @This()) u64 {
        return this.end - this.start + 1;
    }

    fn asc(_: void, lhs: @This(), rhs: @This()) bool {
        return lhs.start < rhs.start;
    }
};

const Input = struct {
    ranges: []const Range,
    nums: []const u64,

    fn deinit(this: @This(), alloc: std.mem.Allocator) void {
        alloc.free(this.ranges);
        alloc.free(this.nums);
    }
};

fn parseInput(alloc: std.mem.Allocator, filename: []const u8) !Input {
    const T = struct {
        alloc: std.mem.Allocator,
        ranges: std.ArrayList(Range),
        nums: std.ArrayList(u64),

        fn parseLine(this: *@This(), line: []const u8) aoc.input.ParseError!bool {
            if (line.len == 0) return true;
            var it = std.mem.splitSequence(u8, line, "-");
            if (it.next()) |a| {
                if (it.next()) |b| {
                    try this.ranges.append(this.alloc, Range{ .start = try aoc.input.parseInt(u64, a), .end = try aoc.input.parseInt(u64, b) });
                } else {
                    try this.nums.append(this.alloc, try aoc.input.parseInt(u64, a));
                }
            }
            return true;
        }
    };
    var t: T = .{ .alloc = alloc, .ranges = try std.ArrayList(Range).initCapacity(alloc, 100), .nums = try std.ArrayList(u64).initCapacity(alloc, 100) };
    try aoc.input.parseLines(filename, &t, T.parseLine);
    return .{ .ranges = try t.ranges.toOwnedSlice(alloc), .nums = try t.nums.toOwnedSlice(alloc) };
}

fn part1(ins: Input) u64 {
    var rv: u64 = 0;
    for (ins.nums) |n| {
        for (ins.ranges) |r| {
            if (r.contains(n)) {
                rv += 1;
                break;
            }
        }
    }
    return rv;
}

test "part1ex" {
    const ins = try parseInput(std.testing.allocator, "input/2025/day5.ex");
    defer ins.deinit(std.testing.allocator);
    try std.testing.expectEqual(3, part1(ins));
}

test "part1" {
    const ins = try parseInput(std.testing.allocator, "input/2025/day5");
    defer ins.deinit(std.testing.allocator);
    try std.testing.expectEqual(862, part1(ins));
}

fn mergeAll(alloc: std.mem.Allocator, ranges: []const Range) ![]Range {
    var rv = try std.ArrayList(Range).initCapacity(alloc, ranges.len);
    errdefer rv.deinit(alloc);
    var todo = try std.ArrayList(Range).initCapacity(alloc, ranges.len);
    errdefer rv.deinit(alloc);
    try todo.appendSlice(alloc, ranges);
    std.sort.pdq(Range, todo.items, {}, Range.asc);
    while (todo.items.len > 0) {
        var tmp = try std.ArrayList(Range).initCapacity(alloc, todo.items.len);
        defer tmp.deinit(alloc);
        var el1 = todo.items[0];
        for (todo.items[1..]) |r| {
            if (el1.overlaps(r)) {
                el1 = el1.merge(r);
            } else {
                try tmp.append(alloc, r);
            }
        }
        todo.clearAndFree(alloc);
        try todo.appendSlice(alloc, tmp.items);
        try rv.append(alloc, el1);
    }
    return try rv.toOwnedSlice(alloc);
}

fn part2(alloc: std.mem.Allocator, ins: Input) !u64 {
    const merged = try mergeAll(alloc, ins.ranges);
    defer alloc.free(merged);
    var rv: u64 = 0;
    for (merged) |r| {
        rv += r.size();
    }
    return rv;
}

test "part2ex" {
    const ins = try parseInput(std.testing.allocator, "input/2025/day5.ex");
    defer ins.deinit(std.testing.allocator);
    try std.testing.expectEqual(14, try part2(std.testing.allocator, ins));
}

test "part2" {
    const ins = try parseInput(std.testing.allocator, "input/2025/day5");
    defer ins.deinit(std.testing.allocator);
    try std.testing.expectEqual(357907198933892, try part2(std.testing.allocator, ins));
}
