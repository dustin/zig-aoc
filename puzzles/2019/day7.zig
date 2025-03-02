const std = @import("std");
const aoc = @import("aoc");
const intcode = @import("intcode.zig");

test "part1" {
    var computer = try intcode.readFile(std.testing.allocator, "input/2019/day7");
    defer computer.deinit();

    var sequence = [5]i32{ 0, 1, 2, 3, 4 };

    var buf: [5]i32 = undefined;
    var it = aoc.permute.Permutations(i32).init(sequence[0..], &buf);
    var mostOut: i32 = 0;
    while (it.next()) |phases| {
        var out: i32 = 0;

        for (phases) |phase| {
            computer.reset();
            var res = try computer.run();
            switch (res) {
                .Input => try computer.set(res.Input, phase),
                else => return error.ExpectedInput,
            }
            res = try computer.run();
            switch (res) {
                .Input => try computer.set(res.Input, out),
                else => return error.ExpectedInput,
            }
            res = try computer.run();
            switch (res) {
                .Halted => {},
                else => return error.ExpectedOutput,
            }
            out = computer.output.items[computer.output.items.len - 1];
        }
        mostOut = @max(mostOut, out);
    }

    try std.testing.expectEqual(43812, mostOut);
}

test "part2" {
    var computer = try intcode.readFile(std.testing.allocator, "input/2019/day7");
    defer computer.deinit();

    var sequence = [5]i32{ 5, 6, 7, 8, 9 };

    var buf: [5]i32 = undefined;
    var it = aoc.permute.Permutations(i32).init(sequence[0..], &buf);
    var mostOut: i32 = 0;
    while (it.next()) |phases| {
        var out: i32 = 0;
        var bigout: i32 = 0;

        var computers: [5]*intcode.Computer = undefined;

        // Bootstrap the computers with phase input
        for (0..computers.len) |i| {
            computers[i] = try computer.duplicate();
            const res = try computers[i].run();
            switch (res) {
                .Input => try computers[i].set(res.Input, phases[i]),
                else => return error.ExpectedInput,
            }
            computers[i].pauseOnOutput = true;
        }
        defer {
            for (computers) |c| {
                c.deinit();
                std.testing.allocator.destroy(c);
            }
        }

        // now we just loop them
        var i: usize = 0;
        while (true) {
            var c = computers[@mod(i, computers.len)];
            i += 1;
            const res = try c.run();
            switch (res) {
                .Input => try c.set(res.Input, out),
                .Halted => break,
                else => return error.ExpectedInput,
            }
            switch (try c.run()) {
                .Output => {
                    out = c.output.items[c.output.items.len - 1];
                },
                .Halted => break,
                else => return error.ExpectedOutput,
            }
            bigout = @max(bigout, out);
        }
        mostOut = @max(mostOut, bigout);
    }

    try std.testing.expectEqual(59597414, mostOut);
}
