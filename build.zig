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

    const exe = b.addExecutable(.{
        .name = "stm32f407-blink.elf",
        .root_module = root_module,
    });

    exe.entry = .{ .symbol_name = "reset_handler" };
    exe.setLinkerScript(b.path("stm32f407.ld"));

    b.installArtifact(exe);

    const bin = b.addObjCopy(exe.getEmittedBin(), .{
        .format = .bin,
    });
    const install_bin = b.addInstallFile(bin.getOutput(), "bin/stm32f407-blink.bin");
    b.getInstallStep().dependOn(&install_bin.step);
}
