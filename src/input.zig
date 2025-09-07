const std = @import("std");

pub const ParseError = error{ ParseError, OutOfMemory };

/// Parse lines from a file.
pub fn parseLines(path: []const u8, context: anytype, parseFun: fn (ctx: @TypeOf(context), line: []const u8) ParseError!bool) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var buffer: [4096]u8 = undefined;
    var reader = file.reader(buffer[0..]);

    var i: u32 = 0;
    var ri = &reader.interface;
    while (ri.takeDelimiterExclusive('\n')) |line| {
        if (!try parseFun(context, line)) {
            return {};
        }
        i += 1;
    } else |err| {
        if (err == error.EndOfStream) {
            return {};
        } else {
            std.debug.print("error {} after {d} lines\n", .{ err, i });
            return err;
        }
    }
}

/// Parse a base 10 int.
pub fn parseInt(comptime T: type, s: []const u8) ParseError!T {
    return (std.fmt.parseInt(T, s, 10) catch return error.ParseError);
}

test "line parsing" {
    var sum: i32 = 0;
    const T = struct {
        sum: i32 = 0,

        fn parseLine(s: *i32, line: []const u8) ParseError!bool {
            var it = std.mem.splitSequence(u8, line, ",");
            const a = try parseInt(i32, it.next() orelse return false);
            const b = try parseInt(i32, it.next() orelse return false);
            s.* += (a * 1000) + b;
            return true;
        }
    };

    try parseLines("input/2024/day18.ex", &sum, T.parseLine);
    try std.testing.expectEqual(69082, sum);
}
