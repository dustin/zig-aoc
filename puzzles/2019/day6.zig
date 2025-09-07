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

pub fn flipSMap(
    alloc: std.mem.Allocator,
    a: std.StringHashMap([]const u8),
) !std.StringHashMap(std.ArrayList([]const u8)) {
    var res = std.StringHashMap(std.ArrayList([]const u8)).init(alloc);
    var it = a.iterator();
    while (it.next()) |e| {
        const x = try res.getOrPut(e.value_ptr.*);
        if (!x.found_existing) {
            x.value_ptr.* = try std.ArrayList([]const u8).initCapacity(alloc, 1);
        }
        try x.value_ptr.*.append(alloc, e.key_ptr.*);
    }
    return res;
}

fn addRec(alloc: std.mem.Allocator, g: std.StringHashMap(std.ArrayList([]const u8)), rv: *std.StringHashMap(std.StringHashMap(u16)), k: []const u8) !void {
    if (g.get(k)) |v| {
        for (v.items) |i| {
            try addRec(alloc, g, rv, i);
        }
        const r = try rv.getOrPut(k);
        if (!r.found_existing) {
            r.value_ptr.* = std.StringHashMap(u16).init(alloc);
        }
        for (v.items) |i| {
            try r.value_ptr.*.put(i, 0);
        }
        var updates = try std.ArrayList(struct { key: []const u8, value: u16 }).initCapacity(alloc, v.items.len);
        defer updates.deinit(alloc);

        var it = r.value_ptr.*.iterator();
        while (it.next()) |e| {
            try updates.append(alloc, .{ .key = e.key_ptr.*, .value = 1 + e.value_ptr.* });
        }

        for (updates.items) |update| {
            try r.value_ptr.*.put(update.key, update.value);
        }
    }
}

fn computeReachability(alloc: std.mem.Allocator, g: Graph) !std.StringHashMap(std.StringHashMap(u16)) {
    var flipped = try flipSMap(alloc, g);
    defer flipped.deinit();
    var rv = std.StringHashMap(std.StringHashMap(u16)).init(alloc);
    try addRec(alloc, flipped, &rv, "COM");
    return rv;
}

test "part2" {
    var arena = try std.testing.allocator.create(std.heap.ArenaAllocator);
    defer std.testing.allocator.destroy(arena);
    arena.* = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const g = try getInput(arena.allocator());
    const reach = try computeReachability(arena.allocator(), g);
    // defer reach.deinit();

    std.debug.print("Reachable from COM: {d}\n", .{reach.count()});

    var oit = reach.iterator();
    while (oit.next()) |e| {
        std.debug.print("{s}\n", .{e.key_ptr.*});
        var it2 = e.value_ptr.*.iterator();
        while (it2.next()) |e2| {
            std.debug.print("  {s} -> {any}\n", .{ e2.key_ptr.*, e2.value_ptr.* });
        }
    }

    // var root: []const u8 = "";

    // var it = reach.iterator();
    // while (it.next()) |e| {
    //     var it2 = e.value_ptr.*.iterator();
    //     while (it2.next()) |e2| {
    //         try std.testing.expectEqual(e.key_ptr.*, e2.key_ptr.*);
    //     }
    // }
}
