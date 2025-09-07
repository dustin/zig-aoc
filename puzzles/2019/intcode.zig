const std = @import("std");
const aoc = @import("aoc");

pub const ReturnMode = union(enum) {
    Continue: void,
    Halted: void,
    Input: i64,
    Output: i64, // return mode when pause-on-output is enabled
};

pub const AddrMode = enum {
    Position,
    Immediate,
    Relative,
};

fn resolveOp(op: i64) AddrMode {
    return switch (@mod(op, 10)) {
        0 => .Position,
        1 => .Immediate,
        2 => .Relative,
        else => std.debug.panic("invalid addr mode: {d}\n", .{op}),
    };
}

pub const Computer = struct {
    alloc: std.mem.Allocator,
    rom: []const i64,
    mem: std.AutoHashMap(i64, i64),
    output: std.ArrayList(i64),
    pauseOnOutput: bool = false,
    relBase: i64 = 0,

    pc: i64 = 0,

    pub fn at(this: @This(), addr: i64) i64 {
        // First check if the address is in the modified memory
        if (this.mem.get(addr)) |val| {
            return val;
        }

        // Then check if it's within the original program bounds
        if (addr >= 0 and addr < this.rom.len) {
            return this.rom[@intCast(addr)];
        }

        // Otherwise, return 0 (memory beyond program defaults to 0)
        return 0;
    }

    pub fn set(this: *@This(), addr: i64, val: i64) !void {
        try this.mem.put(addr, val);
    }

    pub fn deinit(this: *@This()) void {
        this.mem.deinit();
        this.alloc.free(this.rom);
        this.output.deinit(this.alloc);
    }

    pub fn duplicate(this: *@This()) !*Computer {
        const mem = try this.mem.cloneWithAllocator(this.alloc);
        const output = try this.output.clone(this.alloc);
        const rom = try this.alloc.alloc(i64, this.rom.len);
        std.mem.copyForwards(i64, rom, this.rom);
        var comp = try this.alloc.create(Computer);
        comp.alloc = this.alloc;
        comp.rom = rom;
        comp.mem = mem;
        comp.output = output;
        comp.pc = this.pc;
        comp.pauseOnOutput = this.pauseOnOutput;
        comp.relBase = this.relBase;
        return comp;
    }

    fn arg(this: @This(), argNum: u4, mode: AddrMode, addr: i64) i64 {
        const val = this.at(addr + argNum + 1);
        return switch (mode) {
            .Position => this.at(val),
            .Immediate => val,
            .Relative => this.at(this.relBase + val),
        };
    }

    fn writeArg(this: @This(), argNum: u4, mode: AddrMode, addr: i64) i64 {
        const val = this.at(addr + argNum + 1);
        return switch (mode) {
            .Position => val,
            .Immediate => std.debug.panic("Cannot use immediate mode for output parameters", .{}),
            .Relative => this.relBase + val,
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
                const outAddr = this.writeArg(2, modes[2], this.pc);
                const rv = if (op == 1) a + b else a * b;
                try this.set(outAddr, rv);
                this.pc += 4;
                return .Continue;
            },
            3 => {
                const outAddr = this.writeArg(0, modes[0], this.pc);
                this.pc += 2;
                return .{ .Input = outAddr };
            },
            4 => {
                const val = this.arg(0, modes[0], this.pc);
                this.pc += 2;
                if (this.pauseOnOutput) {
                    return .{ .Output = val };
                }
                try this.output.append(this.alloc, val);
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
                const outAddr = this.writeArg(2, modes[2], this.pc);
                try this.set(outAddr, if (a < b) 1 else 0);
                this.pc += 4;
                return .Continue;
            },
            8 => {
                const a = this.arg(0, modes[0], this.pc);
                const b = this.arg(1, modes[1], this.pc);
                const outAddr = this.writeArg(2, modes[2], this.pc);
                try this.set(outAddr, if (a == b) 1 else 0);
                this.pc += 4;
                return .Continue;
            },
            9 => {
                const a = this.arg(0, modes[0], this.pc);
                this.relBase += a;
                this.pc += 2;
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
        this.mem = std.AutoHashMap(i64, i64).init(this.alloc);
        this.output.clearRetainingCapacity();
        this.relBase = 0;
    }

    pub fn clearOutput(this: *@This()) void {
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

pub fn newComputer(alloc: std.mem.Allocator, mem: []const i64) !Computer {
    const rom = try alloc.alloc(i64, mem.len);
    std.mem.copyForwards(i64, rom, mem);
    return .{
        .alloc = alloc,
        .mem = std.AutoHashMap(i64, i64).init(alloc),
        .rom = rom,
        .output = try std.ArrayList(i64).initCapacity(alloc, mem.len),
    };
}

pub fn readFile(alloc: std.mem.Allocator, path: []const u8) !Computer {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var buf: [4096]u8 = undefined;
    var reader = file.reader(buf[0..]);

    var nums = try std.ArrayList(i64).initCapacity(alloc, 100);
    defer nums.deinit(alloc);

    var ri = &reader.interface;
    while (ri.takeDelimiterExclusive(',')) |token| {
        var t = token;
        if (t[t.len - 1] == '\n') {
            t = t[0 .. t.len - 1];
        }
        const num = try aoc.input.parseInt(i64, t);
        try nums.append(alloc, num);
    } else |err| switch (err) {
        error.EndOfStream => {},
        error.StreamTooLong,
        error.ReadFailed,
        => |e| {
            std.debug.print("Error reading file: {} after {d} ints from {s}\n", .{ e, nums.items.len, path });
            return e;
            // return e;
            // do nothing
        },
    }
    return newComputer(alloc, nums.items);
}

test "computer memory" {
    var c = try newComputer(std.testing.allocator, &[_]i64{ 1, 2, 3 });
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
    var c = try newComputer(std.testing.allocator, &[_]i64{ 1, 5, 6, 0, 99, 3, 7 });
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
    var c = try newComputer(std.testing.allocator, &[_]i64{ 101, 5, 6, 0, 99, 3, 7 });
    defer c.deinit();
    _ = try c.runOne();
    try std.testing.expectEqual(12, c.at(0));

    var c2 = try newComputer(std.testing.allocator, &[_]i64{ 1001, 5, 6, 0, 99, 3, 7 });
    defer c2.deinit();
    _ = try c2.runOne();
    try std.testing.expectEqual(9, c2.at(0));
}

test "all ops" {
    var c = try newComputer(std.testing.allocator, &[_]i64{ 1, 5, 6, 0, 99, 3, 7 });
    defer c.deinit();
    const ran = try c.run();
    try std.testing.expectEqual(.Halted, ran);
    try std.testing.expectEqual(10, c.at(0));
}
