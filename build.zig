const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m4 },
        .os_tag = .freestanding,
        .abi = .eabi,
    });

    const optimize: std.builtin.OptimizeMode = .ReleaseSmall;

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "zig_blink",
        .root_module = root_module,
        .linkage = .static,
    });

    b.installArtifact(lib);
    _ = b.addInstallHeaderFile(b.path("include/zig_blink.h"), "zig_blink.h");
}
