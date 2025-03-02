const std = @import("std");
const aoc = @import("aoc");

pub const ReturnMode = union(enum) {
    Continue: void,
    Halted: void,
    Input: i32,
    Output: void, // return mode when pause-on-output is enabled
};

pub const AddrMode = enum {
    Position,
    Immediate,
};

fn resolveOp(op: i32) AddrMode {
    return switch (@mod(op, 10)) {
        0 => .Position,
        1 => .Immediate,
        else => std.debug.panic("invalid addr mode: {d}\n", .{op}),
    };
}

pub const Computer = struct {
    alloc: std.mem.Allocator,
    rom: []const i32,
    mem: std.AutoHashMap(i32, i32),
    output: std.ArrayList(i32),
    pauseOnOutput: bool = false,

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
        this.output.deinit();
    }

    pub fn duplicate(this: *@This()) !*Computer {
        const mem = try this.mem.cloneWithAllocator(this.alloc);
        const output = try this.output.clone();
        const rom = try this.alloc.alloc(i32, this.rom.len);
        std.mem.copyForwards(i32, rom, this.rom);
        var comp = try this.alloc.create(Computer);
        comp.alloc = this.alloc;
        comp.rom = rom;
        comp.mem = mem;
        comp.output = output;
        comp.pc = this.pc;
        comp.pauseOnOutput = this.pauseOnOutput;
        return comp;
    }

    fn arg(this: @This(), argNum: u4, mode: AddrMode, addr: i32) i32 {
        const val = this.at(addr + argNum + 1);
        return switch (mode) {
            .Position => this.at(val),
            .Immediate => val,
        };
    }

    pub fn runOne(this: *@This()) !ReturnMode {
        const rawOp = this.at(this.pc);
        const op = @mod(rawOp, 100);
        const modes: [3]AddrMode = .{
            resolveOp(@divTrunc(rawOp, 100)),
            resolveOp(@divTrunc(rawOp, 1000)),
            resolveOp(@divTrunc(rawOp, 10000)),
        };

        switch (op) {
            1, 2 => {
                const a = this.arg(0, modes[0], this.pc);
                const b = this.arg(1, modes[1], this.pc);
                const c = this.at(this.pc + 3);
                const rv = if (op == 1) a + b else a * b;
                try this.set(c, rv);
                this.pc += 4;
                return .Continue;
            },
            3 => {
                const addr = this.at(this.pc + 1);
                this.pc += 2;
                return .{ .Input = addr };
            },
            4 => {
                const val = this.arg(0, modes[0], this.pc);
                try this.output.append(val);
                this.pc += 2;
                if (this.pauseOnOutput) {
                    return .Output;
                }
                return .Continue;
            },
            5 => {
                const a = this.arg(0, modes[0], this.pc);
                const b = this.arg(1, modes[1], this.pc);
                if (a != 0) {
                    this.pc = b;
                } else {
                    this.pc += 3;
                }
                return .Continue;
            },
            6 => {
                const a = this.arg(0, modes[0], this.pc);
                const b = this.arg(1, modes[1], this.pc);
                if (a == 0) {
                    this.pc = b;
                } else {
                    this.pc += 3;
                }
                return .Continue;
            },
            7 => {
                const a = this.arg(0, modes[0], this.pc);
                const b = this.arg(1, modes[1], this.pc);
                const c = this.at(this.pc + 3);
                try this.set(c, if (a < b) 1 else 0);
                this.pc += 4;
                return .Continue;
            },
            8 => {
                const a = this.arg(0, modes[0], this.pc);
                const b = this.arg(1, modes[1], this.pc);
                const c = this.at(this.pc + 3);
                try this.set(c, if (a == b) 1 else 0);
                this.pc += 4;
                return .Continue;
            },
            99 => return .Halted,
            else => std.debug.panic("unhandled opcode: {d}\n", .{op}),
        }
        return .Halted;
    }

    /// Reset the computer to its initial state.
    pub fn reset(this: *@This()) void {
        this.pc = 0;
        this.mem.deinit();
        this.mem = std.AutoHashMap(i32, i32).init(this.alloc);
        this.output.clearRetainingCapacity();
    }

    pub fn run(this: *@This()) !ReturnMode {
        while (true) {
            const rv = try this.runOne();
            if (rv != .Continue) {
                return rv;
            }
        }
    }
};

pub fn newComputer(alloc: std.mem.Allocator, mem: []const i32) !Computer {
    const rom = try alloc.alloc(i32, mem.len);
    std.mem.copyForwards(i32, rom, mem);
    return .{
        .alloc = alloc,
        .mem = std.AutoHashMap(i32, i32).init(alloc),
        .rom = rom,
        .output = std.ArrayList(i32).init(alloc),
    };
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
    var ran = try c.runOne();
    try std.testing.expectEqual(.Continue, ran);
    try std.testing.expectEqual(10, c.at(0));
    try c.set(0, 2);
    c.pc = 0;
    ran = try c.runOne();
    try std.testing.expectEqual(.Continue, ran);
    try std.testing.expectEqual(21, c.at(0));
}

test "immediate op" {
    var c = try newComputer(std.testing.allocator, &[_]i32{ 101, 5, 6, 0, 99, 3, 7 });
    defer c.deinit();
    _ = try c.runOne();
    try std.testing.expectEqual(12, c.at(0));

    var c2 = try newComputer(std.testing.allocator, &[_]i32{ 1001, 5, 6, 0, 99, 3, 7 });
    defer c2.deinit();
    _ = try c2.runOne();
    try std.testing.expectEqual(9, c2.at(0));
}

test "all ops" {
    var c = try newComputer(std.testing.allocator, &[_]i32{ 1, 5, 6, 0, 99, 3, 7 });
    defer c.deinit();
    const ran = try c.run();
    try std.testing.expectEqual(.Halted, ran);
    try std.testing.expectEqual(10, c.at(0));
}
