const std = @import("std");
const aoc = @import("aoc");

// Map of thing to what thing it orbits.
const Graph = std.StringHashMap([]const u8);

fn getInput(alloc: std.mem.Allocator) !Graph {
    const T = struct {
        alloc: std.mem.Allocator,
        g: Graph,
        fn parseLine(self: *@This(), line: []const u8) aoc.input.ParseError!bool {
            var it = std.mem.splitSequence(u8, line, ")");
            const a = it.next() orelse return false;
            const b = it.next() orelse return false;
            try self.g.put(try self.alloc.dupe(u8, b), try self.alloc.dupe(u8, a));
            return true;
        }
    };

    var t = T{ .alloc = alloc, .g = Graph.init(alloc) };

    try aoc.input.parseLines("input/2019/day6", &t, T.parseLine);

    return t.g;
}

fn countOf(g: Graph, k: []const u8) usize {
    if (g.get(k)) |v| {
        return 1 + countOf(g, v);
    }
    return 0;
}

fn orbitCount(g: Graph) usize {
    var rv: usize = 0;
    var it = g.iterator();
    while (it.next()) |e| {
        rv += countOf(g, e.key_ptr.*);
    }
    return rv;
}

test "part1" {
    var arena = try std.testing.allocator.create(std.heap.ArenaAllocator);
    defer std.testing.allocator.destroy(arena);
    arena.* = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const g = try getInput(arena.allocator());
    try std.testing.expectEqual(270768, orbitCount(g));
}

fn addRec(alloc: std.mem.Allocator, g: Graph, rv: *std.StringHashMap(std.StringHashMap(void)), k: []const u8) !void {
    if (g.get(k)) |v| {
        if (try rv.getOrPut(k)) |r| {
            if (!r.found_existing) {
                r.value_ptr.* = std.StringHashMap(void).init(alloc);
            }
            try r.value_ptr.*.put(v, {});
        }
        try addRec(alloc, g, rv, v);
    }
}

fn computeReachability(alloc: std.mem.Allocator, g: Graph) !std.StringHashMap(std.StringHashMap(void)) {
    var rv = std.StringHashMap(std.StringHashMap(void)).init(alloc);
    try addRec(alloc, g, &rv, "COM");
    return rv;
}
