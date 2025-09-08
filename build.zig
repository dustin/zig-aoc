const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const aoc = b.addModule("aoc", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const test_step = b.step("test", "Run unit tests");

    const Puzzle = struct {
        year: []const u8,
        day: []const u8,
        path: []const u8,
    };

    var puzzle_files = try std.ArrayList(Puzzle).initCapacity(b.allocator, 100);
    defer puzzle_files.deinit(b.allocator);

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
        var year_dir = std.fs.cwd().openDir(b.fmt("puzzles/{s}", .{year}), .{ .iterate = true }) catch |err| {
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
                try puzzle_files.append(b.allocator, Puzzle{
                    .year = try b.allocator.dupe(u8, year),
                    .day = try b.allocator.dupe(u8, day),
                    .path = b.fmt("puzzles/{s}/{s}", .{ year, name }),
                });
            }
        }
    }

    // Create executables and tests from the discovered puzzle_files list.
    for (puzzle_files.items) |pf| {

        // If there's a main, let's build an executable.
        const puzzle_file = try std.fs.cwd().openFile(pf.path, .{});
        defer puzzle_file.close();
        var buf: [8192]u8 = undefined;
        var reader = puzzle_file.reader(buf[0..]);
        var ri = &reader.interface;

        var w = std.Io.Writer.Allocating.init(b.allocator);
        defer w.deinit();
        _ = try ri.streamRemaining(&w.writer);

        if (std.mem.indexOf(u8, w.written(), "pub fn main") != null) {
            const exe = b.addExecutable(.{
                .name = b.fmt("{s}-{s}", .{ pf.year, pf.day }),
                .root_module = b.createModule(.{
                    .root_source_file = b.path(pf.path),
                    .target = target,
                    .optimize = optimize,
                }),
            });
            exe.root_module.addImport("aoc", aoc);
            b.installArtifact(exe);
        }

        const exe_unit_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(pf.path),
                .target = target,
                .optimize = optimize,
            }),
        });
        exe_unit_tests.root_module.addImport("aoc", aoc);
        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
        test_step.dependOn(&run_exe_unit_tests.step);
    }

    const zigthesis = b.dependency("zigthesis", .{
        .target = target,
        .optimize = optimize,
    });

    const lib_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zigthesis", .module = zigthesis.module("zigthesis") },
            },
        }),
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    test_step.dependOn(&run_lib_unit_tests.step);
}
