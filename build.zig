const std = @import("std");

pub fn build(b: *std.Build) void {
    // Dependencies
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const raylib_dep = b.dependency("raylib_zig", .{ .target = target, .optimize = optimize });

    // Modules and executables
    const raylib = raylib_dep.module("raylib");
    const mod = b.addModule("lrc", .{
        .target = target,
        .root_source_file = b.path("src/root.zig"),
        .imports = &.{
            .{ .name = "raylib", .module = raylib },
        },
    });
    const exe = b.addExecutable(.{
        .name = "lrc",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/main.zig"),
            .imports = &.{
                .{ .name = "lrc", .module = mod },
                .{ .name = "raylib", .module = raylib },
            },
        }),
    });

    // Link and install artifacts
    const raylib_artifact = raylib_dep.artifact("raylib");
    exe.root_module.linkLibrary(raylib_artifact);
    b.installArtifact(exe);

    // Run step
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
}
