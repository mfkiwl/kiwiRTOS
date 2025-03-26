//! This is the build script for the operating system.

const std = @import("std");
const Target = std.Target;
const Feature = @import("std").Target.Cpu.Feature;
const kernel_name = "kiwiRTOS";
const fs = std.fs;
const builtin = @import("builtin");

// write a build.zig file that changes the bootloader for the operating system depending on the architecture specified via the command line argument target_arch

pub fn build(b: *std.Build) anyerror!void {
    const optimize = b.standardOptimizeOption(.{});
    // Define the supported target architectures
    const TargetArch = enum { riscv32, riscv64, arm, x86 };

    // Parse the target architecture from command line or use a default
    const target_arch_str = b.option([]const u8, "target_arch", "The target architecture to build for (riscv32, riscv64, or arm, x86)") orelse @panic("Target CPU architecture must be specified");
    const target_arch = std.meta.stringToEnum(TargetArch, target_arch_str) orelse {
        std.debug.print("Error: Invalid target architecture '{s}'. Supported architectures are: riscv32, riscv64, arm, x86\n", .{target_arch_str});
        return error.InvalidTargetArch;
    };

    var disabled_features = Feature.Set.empty;
    var enabled_features = Feature.Set.empty;

    switch (target_arch) {
        .riscv32, .riscv64 => {
            // enable Multiply extension
            enabled_features.addFeature(@intFromEnum(Target.riscv.Feature.m));
            // disable all CPU extensions
            disabled_features.addFeature(@intFromEnum(Target.riscv.Feature.a));
            disabled_features.addFeature(@intFromEnum(Target.riscv.Feature.c));
            disabled_features.addFeature(@intFromEnum(Target.riscv.Feature.d));
            disabled_features.addFeature(@intFromEnum(Target.riscv.Feature.e));
            disabled_features.addFeature(@intFromEnum(Target.riscv.Feature.f));
        },
        .arm => {},
        .x86 => {
            disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.mmx));
            disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse));
            disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse2));
            disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx));
            disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx2));
            enabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.soft_float));
        },
    }

    // Define the target architecture that the kernel will be built for
    const target = switch (target_arch) {
        .riscv32 => b.resolveTargetQuery((.{
            .cpu_arch = Target.Cpu.Arch.riscv32,
            .os_tag = Target.Os.Tag.freestanding,
            .abi = Target.Abi.none,
            .cpu_model = .{ .explicit = &std.Target.riscv.cpu.generic_rv32 },
            .cpu_features_sub = disabled_features,
            .cpu_features_add = enabled_features,
        })),
        .riscv64 => b.resolveTargetQuery((.{
            .cpu_arch = Target.Cpu.Arch.riscv64,
            .os_tag = Target.Os.Tag.freestanding,
            .abi = Target.Abi.none,
            .cpu_model = .{ .explicit = &std.Target.riscv.cpu.generic_rv64 },
            .cpu_features_sub = disabled_features,
            .cpu_features_add = enabled_features,
        })),
        .arm => b.resolveTargetQuery((.{
            .cpu_arch = Target.Cpu.Arch.aarch64,
            .os_tag = Target.Os.Tag.freestanding,
            .abi = Target.Abi.none,
            .cpu_model = .{ .explicit = &std.Target.aarch64.cpu.generic },
            .cpu_features_sub = disabled_features,
            .cpu_features_add = enabled_features,
        })),
        .x86 => b.resolveTargetQuery((.{
            .cpu_arch = Target.Cpu.Arch.x86,
            .os_tag = Target.Os.Tag.freestanding,
            .abi = Target.Abi.none,
            .cpu_model = .{ .explicit = &std.Target.x86.cpu.generic },
            .cpu_features_sub = disabled_features,
            .cpu_features_add = enabled_features,
        })),
    };

    const kernel = b.addExecutable(.{
        .root_source_file = b.path("src/kiwiRTOS.zig"),
        .optimize = optimize,
        .target = target,
        .name = kernel_name,
        .code_model = switch (target_arch) {
            .riscv64, .riscv32 => .medium,
            else => .kernel,
        },
    });

    // Set the appropriate linker script based on the target architecture
    const linker_script = switch (target_arch) {
        .riscv32 => "src/arch/riscv/32/linker.ld",
        .riscv64 => "src/arch/riscv/64/linker.ld",
        .arm => "src/arch/arm/linker.ld",
        .x86 => "src/arch/x86/linker.ld",
    };

    kernel.setLinkerScriptPath(b.path(linker_script));

    // Set the boot-code depending on the target architecture
    const boot_code = switch (target_arch) {
        .riscv32 => "src/arch/riscv/32/boot.S",
        .riscv64 => "src/arch/riscv/64/boot.S",
        .arm => "src/arch/arm/boot.S",
        .x86 => "src/arch/x86/boot.S",
    };

    kernel.addCSourceFiles(.{
        .files = &.{boot_code},
        .flags = &.{
            "-x", "assembler-with-cpp",
        },
    });
    b.installArtifact(kernel);

    const qemu = switch (target_arch) {
        .riscv64 => "qemu-system-riscv64",
        .riscv32 => "qemu-system-riscv32",
        .arm => "qemu-system-aarch64",
        .x86 => "qemu-system-i386",
    };

    const qemu_machine = switch (target_arch) {
        .riscv64, .riscv32, .arm => "virt",
        .x86 => "pc",
    };

    const qemu_cpu = switch (target_arch) {
        .riscv64 => "rv64",
        .riscv32 => "rv32",
        .arm => "cortex-a53",
        .x86 => "pentium",
    };

    const display = if (builtin.os.tag == .macos) "cocoa" else "sdl";
    const kernel_path = "zig-out/bin/" ++ kernel_name;

    const qemu_cmd = b.addSystemCommand(&.{
        qemu,
        "-machine",
        qemu_machine,
        "-bios",
        "none",
        "-kernel",
        kernel_path,
        "-m",
        "128M",
        "-cpu",
        qemu_cpu,
        "-smp",
        "4",
        "-device",
        "virtio-gpu-device",
        "-device",
        "virtio-keyboard-device",
        "-device",
        "virtio-mouse-device",
        "-display",
        display,
        "-serial",
        "mon:stdio",
    });

    qemu_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| qemu_cmd.addArgs(args);
    const run_step = b.step("run", "Start the kernel in qemu");
    run_step.dependOn(&qemu_cmd.step);

    const install_docs = b.addInstallDirectory(.{
        .source_dir = kernel.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    const docs_step = b.step("docs", "Copy documentation artifacts to prefix path");
    docs_step.dependOn(&install_docs.step);
}
