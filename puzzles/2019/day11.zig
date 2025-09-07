const std = @import("std");
const aoc = @import("aoc");
const intcode = @import("intcode.zig");

const Color = enum(u1) {
    Black = 0,
    White = 1,
};

fn run(alloc: std.mem.Allocator, firstColor: Color) !std.AutoHashMap(aoc.twod.Point, Color) {
    var computer = try intcode.readFile(alloc, "input/2019/day11");
    defer computer.deinit();

    var m = std.AutoHashMap(aoc.twod.Point, Color).init(alloc);

    var position = aoc.twod.origin;
    var direction: aoc.twod.Dir = .n;
    try m.put(position, firstColor);

    while (true) {
        const res = try computer.run();
        switch (res) {
            .Halted => return m,
            .Input => {
                const outs = computer.output.items;
                computer.clearOutput();
                if (outs.len == 2) {
                    try m.put(position, if (outs[0] == 0) .Black else .White);
                    direction = if (outs[1] == 0) direction.left() else direction.right();
                    position = aoc.twod.invFwd(position, direction);
                } else if (outs.len == 0) {
                    // first case does nothing
                } else {
                    return error.Unreachable;
                }
                const color = m.get(position) orelse Color.Black;
                try computer.set(res.Input, @intFromEnum(color));
            },
            else => return error.ExpectedHalt,
        }
    }
}

test "part1" {
    var map = try run(std.testing.allocator, .Black);
    defer map.deinit();
    try std.testing.expectEqual(2339, map.count());
}

fn colorize(c: Color) u8 {
    return switch (c) {
        .Black => ' ',
        .White => '#',
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    const allocator = gpa.allocator();
    var m = try run(allocator, .White);
    defer m.deinit();
    var writer_buf: [128]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&writer_buf);
    try aoc.twod.drawMap(Color, &stdout.interface, ' ', colorize, m);
}
