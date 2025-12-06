const std = @import("std");
const aoc = @import("aoc");

const Op = enum {
    add,
    mul,
};

const Input = struct {
    nums: [][]const u64,
    ops: []const Op,
    fn deinit(this: @This(), alloc: std.mem.Allocator) void {
        for (this.nums) |n| {
            alloc.free(n);
        }
        alloc.free(this.nums);
        alloc.free(this.ops);
    }
};

fn parseInput(alloc: std.mem.Allocator, filename: []const u8) !Input {
    const T = struct {
        alloc: std.mem.Allocator,
        nums: std.ArrayList([]const u64),
        ops: std.ArrayList(Op),

        fn parseLine(this: *@This(), line: []const u8) aoc.input.ParseError!bool {
            var it = std.mem.tokenizeSequence(u8, line, " ");
            var ns = try std.ArrayList(u64).initCapacity(this.alloc, 100);
            errdefer ns.deinit(this.alloc);
            while (it.next()) |tok| {
                switch (tok[0]) {
                    '+' => try this.ops.append(this.alloc, .add),
                    '*' => try this.ops.append(this.alloc, .mul),
                    else => try ns.append(this.alloc, try aoc.input.parseInt(u64, tok)),
                }
            }
            if (ns.items.len > 0) {
                try this.nums.append(this.alloc, try ns.toOwnedSlice(this.alloc));
            } else {
                ns.deinit(this.alloc);
            }
            return true;
        }
    };
    var t: T = .{ .alloc = alloc, .nums = try std.ArrayList([]const u64).initCapacity(alloc, 10), .ops = try std.ArrayList(Op).initCapacity(alloc, 100) };
    try aoc.input.parseLines(filename, &t, T.parseLine);
    return .{ .nums = try t.nums.toOwnedSlice(alloc), .ops = try t.ops.toOwnedSlice(alloc) };
}

fn part1(ins: Input) u64 {
    var rv: u64 = 0;
    for (ins.ops, 0..) |op, i| {
        var s: u64 = switch (op) {
            .add => 0,
            .mul => 1,
        };
        for (ins.nums) |ns| {
            const x = ns[i];
            switch (op) {
                .add => s += x,
                .mul => s *= x,
            }
        }
        rv += s;
    }
    return rv;
}

test "part1ex" {
    const ins = try parseInput(std.testing.allocator, "input/2025/day6.ex");
    defer ins.deinit(std.testing.allocator);
    try std.testing.expectEqual(4277556, part1(ins));
}

test "part1" {
    const ins = try parseInput(std.testing.allocator, "input/2025/day6");
    defer ins.deinit(std.testing.allocator);
    try std.testing.expectEqual(6957525317641, part1(ins));
}
