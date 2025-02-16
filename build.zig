const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const aoc = b.addModule("aoc", .{
        .root_source_file = b.path("src/root.zig"),
    });

    const lib = b.addStaticLibrary(.{
        .name = "zig-aoc",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    const zigthesis = b.dependency("zigthesis", .{
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");

    const Puzzle = comptime struct { year: []const u8, day: []const u8 };

    const puzzles = [_]Puzzle{
        .{ .year = "2024", .day = "1" },
        .{ .year = "2024", .day = "18" },
    };

    for (puzzles) |yd| {
        var namebuf: [64]u8 = undefined;
        var nbs = std.io.fixedBufferStream(&namebuf);
        try std.fmt.format(nbs.writer(), "{s}-{s}", .{ yd.year, yd.day });
        var pathbuf: [64]u8 = undefined;
        var pbs = std.io.fixedBufferStream(&pathbuf);
        try std.fmt.format(pbs.writer(), "puzzles/{s}/day{s}.zig", .{ yd.year, yd.day });
        const exe = b.addExecutable(.{
            .name = nbs.getWritten(),
            .root_source_file = b.path(pbs.getWritten()),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("aoc", aoc);
        b.installArtifact(exe);

        const exe_unit_tests = b.addTest(.{
            .root_source_file = b.path(pbs.getWritten()),
            .target = target,
            .optimize = optimize,
        });
        exe_unit_tests.root_module.addImport("aoc", aoc);
        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
        test_step.dependOn(&run_exe_unit_tests.step);
    }

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    lib_unit_tests.root_module.addImport("zigthesis", zigthesis.module("zigthesis"));

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    test_step.dependOn(&run_lib_unit_tests.step);
}
