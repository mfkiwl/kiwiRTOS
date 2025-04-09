//! This is the build script for the operating system.

const std = @import("std");
const Target = std.Target;
const Feature = @import("std").Target.Cpu.Feature;

const fs = std.fs;
const builtin = @import("builtin");

// write a build.zig file that changes the bootloader for the operating system depending on the architecture specified via the command line argument target_arch

pub fn build(b: *std.Build) anyerror!void {
    // Parse optimization level from command line or default to Debug
    const optimize = b.standardOptimizeOption(.{});

    // Define the supported target architectures
    const TargetArch = enum { riscv32, riscv64, arm, x86_64 };

    // Parse the target architecture from command line or use a default
    const target_arch_str = b.option([]const u8, "target_arch", "The target architecture to build for (riscv32, riscv64, or arm, x86_64)") orelse @panic("Target CPU architecture must be specified");
    const target_arch = std.meta.stringToEnum(TargetArch, target_arch_str) orelse {
        std.debug.print("Error: Invalid target architecture '{s}'. Supported architectures are: riscv32, riscv64, arm, x86_64\n", .{target_arch_str});
        return error.InvalidTargetArch;
    };

    const target_name = b.fmt("kiwiRTOS-{s}", .{target_arch_str});
    const kernel_name = b.fmt("{s}.bin", .{target_name});
    const kernel_path = b.fmt("zig-out/bin/{s}", .{kernel_name});
    const image_name = b.fmt("{s}.img", .{target_name});
    const image_path = b.fmt("zig-out/bin/{s}", .{image_name});

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
        .x86_64 => {
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
        .x86_64 => b.resolveTargetQuery((.{
            .cpu_arch = Target.Cpu.Arch.x86_64,
            .os_tag = Target.Os.Tag.freestanding,
            .abi = Target.Abi.none,
            .cpu_model = .{ .explicit = &std.Target.x86.cpu.x86_64 },
            .cpu_features_sub = disabled_features,
            .cpu_features_add = enabled_features,
        })),
    };

    // Kernel executable
    const kernel = b.addExecutable(.{
        .root_source_file = b.path("src/kiwiRTOS.zig"),
        .optimize = optimize,
        .target = target,
        .name = kernel_name,
        .code_model = switch (target_arch) {
            .riscv64, .riscv32 => .medium,
            .x86_64 => .default,
            else => .kernel,
        },
    });

    // Get the architecture-specific directory
    const arch_dir = switch (target_arch) {
        .riscv32 => "src/arch/riscv/32",
        .riscv64 => "src/arch/riscv/64",
        .arm => "src/arch/arm",
        .x86_64 => "src/arch/x86_64",
    };

    // Set the linker script based on the target architecture
    const linker_script = b.fmt("{s}/linker.ld", .{arch_dir});
    kernel.setLinkerScript(b.path(linker_script));

    // Find all assembly files in the architecture directory
    var asm_files = std.ArrayList([]const u8).init(b.allocator);
    defer asm_files.deinit();

    var dir = try std.fs.cwd().openDir(arch_dir, .{ .iterate = true });
    defer dir.close();

    // Set the boot-code depending on the target architecture
    var it = dir.iterate();
    while (try it.next()) |entry| {
        const ext = std.fs.path.extension(entry.name);
        if (std.mem.eql(u8, ext, ".S") or std.mem.eql(u8, ext, ".s") or std.mem.eql(u8, ext, ".asm")) {
            const full_path = try std.fs.path.join(b.allocator, &.{ arch_dir, entry.name });
            try asm_files.append(full_path);
        }
    }

    // Add each assembly file individually with the proper format
    for (asm_files.items) |asm_file| {
        if (target_arch == .x86_64) {
            // For x86_64, use NASM assembler with a specific command
            const stem = std.fs.path.stem(asm_file);
            const asm_obj_name = b.fmt("{s}.o", .{stem});
            const output_dir = "zig-out/bin";
            const asm_obj_path = b.fmt("{s}/{s}", .{ output_dir, asm_obj_name });

            // Create the output directory if it doesn't exist
            const dir_cmd = b.addSystemCommand(&.{ "mkdir", "-p", output_dir });

            // Run NASM to compile the assembly file
            const asm_cmd = b.addSystemCommand(&.{
                "nasm",
                "-felf64",
                "-g",
                "-o",
                asm_obj_path,
                asm_file,
            });
            asm_cmd.step.dependOn(&dir_cmd.step);

            // Add the object file to the kernel using a relative path
            kernel.addObjectFile(.{ .cwd_relative = asm_obj_path });
            kernel.step.dependOn(&asm_cmd.step);
        } else {
            kernel.addAssemblyFile(b.path(asm_file));
        }
    }

    b.installArtifact(kernel);

    // Set up QEMU command based on architecture
    const qemu = switch (target_arch) {
        .riscv64 => "qemu-system-riscv64",
        .riscv32 => "qemu-system-riscv32",
        .arm => "qemu-system-aarch64",
        .x86_64 => "qemu-system-x86_64",
    };

    const display = if (builtin.os.tag == .macos) "cocoa" else "sdl";

    // Add log file path configuration
    const log_file = b.option([]const u8, "log_file", "Path to QEMU log file") orelse "qemu.log";

    const qemu_args = [_][]const u8{
        qemu,
        "-drive",
        b.fmt("format=raw,file={s}", .{kernel_path}),
        "-display",
        display,
        "-serial",
        "mon:stdio",
        "-D",
        log_file,
        "-d",
        "in_asm,int,mmu,pcall,unimp,guest_errors",
    };

    // Standard run command
    const run_cmd = b.addSystemCommand(&qemu_args);

    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Start the kernel with QEMU");
    run_step.dependOn(&run_cmd.step);

    // Debug command
    const debug_port = "1234";
    const qemu_debug_args = qemu_args ++ [_][]const u8{
        "-gdb",
        b.fmt("tcp::{s}", .{debug_port}),
        "-S",
    };

    const debug_cmd = b.addSystemCommand(&qemu_debug_args);
    debug_cmd.step.dependOn(b.getInstallStep());
    const debug_step = b.step("debug", "Start the kernel with QEMU in debug mode");
    debug_step.dependOn(&debug_cmd.step);

    // Image creation command
    const image_step = b.step("image", "Create the image file");
    image_step.dependOn(b.getInstallStep());
    const image_cmd = b.addSystemCommand(&.{
        "sudo", "-E",    "./scripts/image.sh", kernel_path, image_path, target_arch_str,
        "sudo", "chown", "$(USER):$(USER)",    image_path,
    });
    image_step.dependOn(&image_cmd.step);

    // Documentation step
    const install_docs = b.addInstallDirectory(.{
        .source_dir = kernel.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    const docs_step = b.step("docs", "Copy documentation artifacts to prefix path");
    docs_step.dependOn(&install_docs.step);
}
