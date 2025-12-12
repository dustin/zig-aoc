const std = @import("std");

pub fn map(alloc: std.mem.Allocator, comptime f: anytype, as: anytype) !void {
    var wg: std.Thread.WaitGroup = .{};

    var pool: std.Thread.Pool = undefined;
    try pool.init(std.Thread.Pool.Options{ .allocator = alloc, .n_jobs = try std.Thread.getCpuCount() });
    defer pool.deinit();
    for (as) |a| {
        pool.spawnWg(&wg, f, .{a});
    }
    pool.waitAndWork(&wg);
}
