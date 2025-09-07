const std = @import("std");
const aoc = @import("aoc");

const P = struct {
    alloc: std.mem.Allocator,
    nums: std.ArrayList([]i32),

    pub fn parseLine(this: *@This(), line: []const u8) aoc.input.ParseError!bool {
        var nums = try std.ArrayList(i32).initCapacity(this.alloc, 10);
        defer nums.deinit(this.alloc);

        var it = std.mem.tokenizeSequence(u8, line, " ");
        while (it.next()) |token| {
            const num = try aoc.input.parseInt(i32, token);
            try nums.append(this.alloc, num);
        }
        try this.nums.append(this.alloc, try nums.toOwnedSlice(this.alloc));
        return true;
    }

    pub fn deinit(this: *@This()) void {
        for (this.nums.items) |nums| {
            this.alloc.free(nums);
        }
        this.nums.deinit(this.alloc);
    }
};

const filePath: []const u8 = "input/2024/day2";

fn newP(alloc: std.mem.Allocator, path: []const u8) !P {
    var p = P{ .alloc = alloc, .nums = try std.ArrayList([]i32).initCapacity(alloc, 10) };
    try aoc.input.parseLines(path, &p, P.parseLine);
    return p;
}

fn isSafe(nums: []i32) bool {
    var buf: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(buf[0..]);
    var alloc = fba.allocator();

    var diffs = alloc.alloc(i32, nums.len - 1) catch return false;
    defer alloc.free(diffs);

    for (nums[0 .. nums.len - 1], nums[1..], 0..) |n, prev, i| {
        const diff = n - prev;
        if (@abs(diff) < 1 or @abs(diff) > 3) {
            return false;
        }
        diffs[i] = diff;
    }

    const sign0 = diffs[0] < 0;
    for (diffs) |diff| {
        if (sign0 != (diff < 0)) {
            return false;
        }
    }

    return true;
}

test "part1" {
    var p = try newP(std.testing.allocator, filePath);
    defer p.deinit();

    var count: u32 = 0;
    for (p.nums.items) |nums| {
        if (isSafe(nums)) {
            count += 1;
        }
    }

    try std.testing.expectEqual(502, count);
}

test "part2" {
    var p = try newP(std.testing.allocator, filePath);
    defer p.deinit();

    var count: u32 = 0;
    for (p.nums.items) |nums| {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(buf[0..]);
        var alloc = fba.allocator();
        const subuf = try alloc.alloc(i32, nums.len - 1);

        var si = aoc.selectIterator(i32, nums, subuf);
        while (si.next()) |sub| {
            if (isSafe(sub.values)) {
                count += 1;
                break;
            }
        }
    }

    try std.testing.expectEqual(544, count);
}
