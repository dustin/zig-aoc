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

    // Replace the hard-coded list with dynamic discovery from the filesystem.
    const Puzzle = struct {
        year: []const u8,
        day: []const u8,
        path: []const u8,
    };

    var puzzle_files = std.ArrayList(Puzzle).init(b.allocator);
    defer puzzle_files.deinit();

    // Open the puzzles directory and iterate its entries.
    var puzzles_dir = std.fs.cwd().openDir("puzzles", .{ .iterate = true }) catch |err| {
        std.debug.print("Failed to open puzzles directory: {}\n", .{err});
        return;
    };
    defer puzzles_dir.close();

    var year_iter = puzzles_dir.iterate();
    while (try year_iter.next()) |year_entry| {
        if (year_entry.kind != .directory) continue;
        const year = year_entry.name;

        // Open each year subdirectory.
        const year_path = try std.fmt.allocPrint(b.allocator, "puzzles/{s}", .{year});
        var year_dir = std.fs.cwd().openDir(year_path, .{ .iterate = true }) catch |err| {
            std.debug.print("Failed to open {s} directory: {}\n", .{ year, err });
            continue;
        };
        defer year_dir.close();

        var file_iter = year_dir.iterate();
        while (try file_iter.next()) |file_entry| {
            if (file_entry.kind != .file) continue;
            const name = file_entry.name;
            // Look for files starting with "day" and ending with ".zig"
            if (std.mem.startsWith(u8, name, "day") and std.mem.endsWith(u8, name, ".zig")) {
                // Extract the day string from "day<number>.zig"
                const day = name[3 .. name.len - 4];
                const path = try std.fmt.allocPrint(b.allocator, "puzzles/{s}/{s}", .{ year, name });
                try puzzle_files.append(Puzzle{
                    .year = try b.allocator.dupe(u8, year),
                    .day = try b.allocator.dupe(u8, day),
                    .path = path,
                });
            }
        }
    }

    // Create executables and tests from the discovered puzzle_files list.
    for (puzzle_files.items) |pf| {

        // If there's a main, let's build an executable.
        const puzzle_file = try std.fs.cwd().openFile(pf.path, .{});
        defer puzzle_file.close();
        const content = try puzzle_file.readToEndAlloc(b.allocator, 64 * 1024 * 1024);
        defer b.allocator.free(content);

        if (std.mem.indexOf(u8, content, "pub fn main") != null) {
            var namebuf: [64]u8 = undefined;
            var nbs = std.io.fixedBufferStream(&namebuf);
            try std.fmt.format(nbs.writer(), "{s}-{s}", .{ pf.year, pf.day });
            const exe = b.addExecutable(.{
                .name = nbs.getWritten(),
                .root_source_file = b.path(pf.path),
                .target = target,
                .optimize = optimize,
            });
            exe.root_module.addImport("aoc", aoc);
            b.installArtifact(exe);
        }

        const exe_unit_tests = b.addTest(.{
            .root_source_file = b.path(pf.path),
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
