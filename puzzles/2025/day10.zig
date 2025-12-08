const std = @import("std");
const aoc = @import("aoc");

const Button = struct {
    val: u16,

    pub fn format(this: @This(), w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.writeAll("(");
        var first = true;
        for (0..16) |i| {
            if ((this.val >> @as(u4, @intCast(i)) & 1 == 1)) {
                if (!first) try w.writeAll(",");
                try w.print("{d}", .{i});
                first = false;
            }
        }
        try w.writeAll(")");
    }

    fn affect(this: @This(), state: u16) u16 {
        return state ^ this.val;
    }
};

fn formatLights(l: u16, w: *std.Io.Writer) std.Io.Writer.Error!void {
    try w.writeAll("[.");
    if (l == 0) {
        try w.writeAll("]");
        return;
    }
    var msb = std.math.log2_int(u16, l);
    while (true) {
        try w.writeAll(if ((l >> msb) & 1 == 1) "#" else ".");
        if (msb == 0) break;
        msb -= 1;
    }
    try w.writeAll("] ");
}

const Light = struct {
    l: u16,

    pub fn format(this: @This(), w: *std.Io.Writer) std.Io.Writer.Error!void {
        try formatLights(this.l, w);
    }
};

const Machine = struct {
    lights: u16,
    buttons: []const Button,
    jolts: []const u16,

    fn press(this: *@This(), button: Button) void {
        this.lights = button.affect(this.lights);
    }

    fn deinit(this: *@This(), alloc: std.mem.Allocator) void {
        alloc.free(this.buttons);
        alloc.free(this.jolts);
        alloc.destroy(this);
    }

    pub fn format(this: @This(), w: *std.Io.Writer) std.Io.Writer.Error!void {
        try formatLights(this.lights, w);

        for (this.buttons) |b| {
            try w.print("{f} ", .{b});
        }
        try w.print("{any}", .{this.jolts});
    }
};

const Input = []*Machine;

fn freeInput(alloc: std.mem.Allocator, ins: Input) void {
    for (ins) |m| {
        defer m.deinit(alloc);
    }
    alloc.free(ins);
}

fn parseInput(alloc: std.mem.Allocator, filename: []const u8) !Input {
    const T = struct {
        alloc: std.mem.Allocator,
        machines: std.ArrayList(*Machine),

        fn commaChunk(T: type, al: std.mem.Allocator, chunk: []const u8, res: *std.ArrayList(T)) !void {
            var it = std.mem.splitSequence(u8, chunk[1 .. chunk.len - 1], ",");
            while (it.next()) |d| {
                try res.append(al, try aoc.input.parseInt(T, d));
            }
        }

        fn parseLine(this: *@This(), line: []const u8) aoc.input.ParseError!bool {
            var it = std.mem.tokenizeSequence(u8, line, " ");
            var buttons = try std.ArrayList(Button).initCapacity(this.alloc, 16);
            var jolts = try std.ArrayList(u16).initCapacity(this.alloc, 16);
            var lights: u16 = 0;

            while (it.next()) |chunk| {
                switch (chunk[0]) {
                    '[' => {
                        for (1..chunk.len - 1) |i| {
                            switch (chunk[i]) {
                                '.' => {},
                                '#' => {
                                    var bs = [1]u4{@intCast(i - 1)};
                                    lights = toButton(bs[0..]).affect(lights);
                                },
                                else => unreachable,
                            }
                        }
                    },
                    '(' => {
                        var bs = try std.ArrayList(u4).initCapacity(this.alloc, 16);
                        defer bs.deinit(this.alloc);
                        try commaChunk(u4, this.alloc, chunk, &bs);
                        try buttons.append(this.alloc, toButton(bs.items));
                    },
                    '{' => {
                        try commaChunk(u16, this.alloc, chunk, &jolts);
                    },
                    else => unreachable,
                }
            }
            var m = try this.alloc.create(Machine);
            m.lights = lights;
            m.buttons = try buttons.toOwnedSlice(this.alloc);
            m.jolts = try jolts.toOwnedSlice(this.alloc);
            try this.machines.append(this.alloc, m);
            return true;
        }
    };
    var t: T = .{ .alloc = alloc, .machines = try std.ArrayList(*Machine).initCapacity(alloc, 200) };
    try aoc.input.parseLines(filename, &t, T.parseLine);
    return try t.machines.toOwnedSlice(alloc);
}

fn toButton(is: []const u4) Button {
    var x: u16 = 0;
    for (is) |i| {
        x |= (@as(u16, 1) << i);
    }
    return .{ .val = x };
}

test "masking" {
    const arr0 = [_]u4{3};
    const arr1 = [_]u4{ 1, 3 };
    const arr2 = [_]u4{2};
    const arr3 = [_]u4{ 2, 3 };
    const arr4 = [_]u4{ 0, 2 };
    const arr5 = [_]u4{ 0, 1 };

    const butts = [_]Button{
        toButton(arr0[0..]),
        toButton(arr1[0..]),
        toButton(arr2[0..]),
        toButton(arr3[0..]),
        toButton(arr4[0..]),
        toButton(arr5[0..]),
    };
    var m: Machine = .{ .lights = 0, .buttons = butts[0..], .jolts = undefined };

    m.press(m.buttons[4]);
    m.press(m.buttons[5]);
    try std.testing.expectEqual(6, m.lights);
}

test "parser" {
    const alloc = std.testing.allocator;
    const ins = try parseInput(alloc, "input/2025/day10.ex");
    defer freeInput(alloc, ins);

    try std.testing.expectEqual(6, ins[0].lights);
    try std.testing.expectEqual(8, ins[0].buttons[0].val);

    // for (ins) |m| {
    //     std.debug.print("{f}\n", .{m});
    // }
}

fn findSequence(alloc: std.mem.Allocator, m: Machine) !u16 {
    var arena = try alloc.create(std.heap.ArenaAllocator);
    defer alloc.destroy(arena);
    arena.* = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    const aalloc = arena.allocator();

    const State = struct {
        lights: u16,
        buttons: *std.ArrayList(Button),

        pub fn format(this: @This(), w: *std.Io.Writer) std.Io.Writer.Error!void {
            try formatLights(this.lights, w);
            for (this.buttons.items) |b| {
                try w.print("{f} ", .{b});
            }
        }
    };

    const T = struct {
        latest: ?[]Button = null,
        m: Machine,
        al: std.mem.Allocator,

        pub fn neighbs(this: *@This(), st: State, neighbors: *std.ArrayList(State)) aoc.search.OutOfMemory!void {
            // std.debug.print("finding neighbors for {f}\n", .{st});
            seen: for (this.m.buttons) |b| {
                for (st.buttons.items) |ob| {
                    if (b.val == ob.val) continue :seen;
                }

                const clone = try st.buttons.clone(this.al);
                const clonep = try this.al.create(std.ArrayList(Button));
                clonep.* = clone;
                var stc = State{ .buttons = clonep, .lights = b.affect(st.lights) };
                try stc.buttons.append(this.al, b);
                try neighbors.append(this.al, stc);

                // stc.lights = 0;
                // for (stc.buttons.items) |ib| {
                //     std.debug.print("  {f} ^ {f} = {f}\n", .{ Light{ .l = stc.lights }, ib, Light{ .l = ib.affect(stc.lights) } });
                //     stc.lights = ib.affect(stc.lights);
                // }

                // std.debug.print("  Neighbor: {f} ({d})\n", .{ stc, this.rf(stc) });
            }
        }

        pub fn rf(_: *@This(), st: State) u64 {
            var h = std.hash.Wyhash.init(0);
            {
                const v: [2]u8 = .{ @as(u8, @intCast(st.lights >> 8)), @as(u8, @intCast(st.lights & 0xff)) };
                h.update(&v);
            }
            for (st.buttons.items) |b| {
                const v: [2]u8 = .{ @as(u8, @intCast(b.val >> 8)), @as(u8, @intCast(b.val & 0xff)) };
                h.update(&v);
            }
            return h.final();
        }

        pub fn found(this: *@This(), st: State) aoc.search.OutOfMemory!bool {
            this.latest = st.buttons.items;
            return st.lights == this.m.lights;
        }
    };

    var empty = try std.ArrayList(Button).initCapacity(aalloc, 0);
    const emptyState = State{ .lights = 0, .buttons = &empty };

    var t = T{ .m = m, .al = aalloc };
    try aoc.search.bfs(State, u64, aalloc, &t, emptyState, T.rf, T.neighbs, T.found);

    // std.debug.print("Found path: {f}\n", .{m});
    // for (t.latest.?) |b| {
    //     std.debug.print(" - {f}\n", .{b});
    // }

    return @as(u16, @intCast(t.latest.?.len));
}

test "find a known sequence" {
    const alloc = std.testing.allocator;
    const ins = try parseInput(alloc, "input/2025/day10.ex");
    defer freeInput(alloc, ins);
    try std.testing.expectEqual(2, try findSequence(alloc, ins[0].*));
}

test "find a known sequence 2" {
    const alloc = std.testing.allocator;
    const ins = try parseInput(alloc, "input/2025/day10.ex");
    defer freeInput(alloc, ins);
    try std.testing.expectEqual(3, try findSequence(alloc, ins[1].*));
}

test "find a known sequence 3" {
    const alloc = std.testing.allocator;
    const ins = try parseInput(alloc, "input/2025/day10.ex");
    defer freeInput(alloc, ins);
    try std.testing.expectEqual(2, try findSequence(alloc, ins[2].*));
}

fn part1(alloc: std.mem.Allocator, filename: []const u8) !u16 {
    const ins = try parseInput(alloc, filename);
    defer freeInput(alloc, ins);

    var rv: u16 = 0;
    for (ins) |m| {
        const x = try findSequence(alloc, m.*);
        rv += x;
    }
    return rv;
}

test "part1ex" {
    const alloc = std.testing.allocator;
    try std.testing.expectEqual(7, try part1(alloc, "input/2025/day10.ex"));
}

test "part1" {
    const alloc = std.testing.allocator;
    try std.testing.expectEqual(452, try part1(alloc, "input/2025/day10"));
}
