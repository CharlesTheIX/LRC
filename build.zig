const std = @import("std");

pub fn build(b: *std.Build) void {
    // Dependencies
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const raylib_dep = b.dependency("raylib_zig", .{ .target = target, .optimize = optimize });

    // Modules
    const raylib = raylib_dep.module("raylib");
    const app_mod = b.addModule("app", .{
        .imports = &.{},
        .target = target,
        .root_source_file = b.path("src/root.zig"),
    });
    const lrc_mod = b.addModule("lrc", .{
        .target = target,
        .root_source_file = b.path("src/lrc/root.zig"),
        .imports = &.{
            .{ .name = "raylib", .module = raylib },
        },
    });
    const udp_mod = b.addModule("udp", .{
        .imports = &.{},
        .target = target,
        .root_source_file = b.path("src/udp/root.zig"),
    });
    const http_mod = b.addModule("http", .{
        .imports = &.{},
        .target = target,
        .root_source_file = b.path("src/http/root.zig"),
    });

    // Create executable
    const exe = b.addExecutable(.{
        .name = "lrc",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/main.zig"),
            .imports = &.{
                .{ .name = "app", .module = app_mod },
                .{ .name = "lrc", .module = lrc_mod },
                .{ .name = "udp", .module = udp_mod },
                .{ .name = "http", .module = http_mod },
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
