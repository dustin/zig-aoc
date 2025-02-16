const std = @import("std");

pub const ParseError = error{ ParseError, OutOfMemory };

/// Parse lines from a file.
pub fn parseLines(path: []const u8, context: anytype, parseFun: fn (ctx: @TypeOf(context), line: []const u8) ParseError!bool) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var reader = file.reader();

    var keepGoing = true;
    while (keepGoing) {
        var lineBuf: [256]u8 = undefined;
        const line = (try reader.readUntilDelimiterOrEof(&lineBuf, '\n')) orelse return;
        keepGoing = try parseFun(context, line);
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
