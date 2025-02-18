const std = @import("std");
const aoc = @import("aoc");

pub const Computer = struct {
    alloc: std.mem.Allocator,
    rom: []const i32,
    mem: std.AutoHashMap(i32, i32),

    pc: i32 = 0,

    pub fn at(this: @This(), addr: i32) i32 {
        return this.mem.get(addr) orelse this.rom[@intCast(addr)];
    }

    pub fn set(this: *@This(), addr: i32, val: i32) !void {
        try this.mem.put(addr, val);
    }

    pub fn deinit(this: *@This()) void {
        this.mem.deinit();
        this.alloc.free(this.rom);
    }

    pub fn runOne(this: *@This()) !void {
        const op = this.at(this.pc);
        switch (op) {
            1, 2 => {
                const a = this.at(this.at(this.pc + 1));
                const b = this.at(this.at(this.pc + 2));
                const c = this.at(this.pc + 3);
                const rv = if (op == 1) a + b else a * b;
                try this.set(c, rv);
                this.pc += 4;
            },
            99 => {},
            else => std.debug.panic("unhandled opcode: {d}\n", .{op}),
        }
    }

    /// Reset the computer to its initial state.
    pub fn reset(this: *@This()) void {
        this.pc = 0;
        this.mem.deinit();
        this.mem = std.AutoHashMap(i32, i32).init(this.alloc);
    }

    pub fn runTilHalt(this: *@This()) !void {
        while (this.at(this.pc) != 99) {
            try this.runOne();
        }
    }
};

pub fn newComputer(alloc: std.mem.Allocator, mem: []const i32) !Computer {
    const rom = try alloc.alloc(i32, mem.len);
    std.mem.copyForwards(i32, rom, mem);
    return .{ .alloc = alloc, .mem = std.AutoHashMap(i32, i32).init(alloc), .rom = rom };
}

pub fn readFile(alloc: std.mem.Allocator, path: []const u8) !Computer {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var reader = file.reader();

    var nums = std.ArrayList(i32).init(alloc);
    defer nums.deinit();

    while (true) {
        var lineBuf: [256]u8 = undefined;
        var token = (try reader.readUntilDelimiterOrEof(&lineBuf, ',')) orelse break;
        if (token[token.len - 1] == '\n') {
            token = token[0 .. token.len - 1];
        }
        const num = try aoc.input.parseInt(i32, token);
        try nums.append(num);
    }

    return newComputer(alloc, nums.items);
}

test "computer memory" {
    var c = try newComputer(std.testing.allocator, &[_]i32{ 1, 2, 3 });
    defer c.deinit();
    try std.testing.expectEqual(1, c.at(0));
    try std.testing.expectEqual(2, c.at(1));
    try std.testing.expectEqual(3, c.at(2));
    try c.set(0, 42);
    try c.set(1, 43);
    try c.set(2, 44);
    try std.testing.expectEqual(42, c.at(0));
    try std.testing.expectEqual(43, c.at(1));
    try std.testing.expectEqual(44, c.at(2));
}

test "single op" {
    var c = try newComputer(std.testing.allocator, &[_]i32{ 1, 5, 6, 0, 99, 3, 7 });
    defer c.deinit();
    try c.runOne();
    try std.testing.expectEqual(10, c.at(0));
    try c.set(0, 2);
    c.pc = 0;
    try c.runOne();
    try std.testing.expectEqual(21, c.at(0));
}

test "all ops" {
    var c = try newComputer(std.testing.allocator, &[_]i32{ 1, 5, 6, 0, 99, 3, 7 });
    defer c.deinit();
    try c.runTilHalt();
    try std.testing.expectEqual(10, c.at(0));
}
