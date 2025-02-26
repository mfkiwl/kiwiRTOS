const std = @import("std");

// write a build.zig file that changes the bootloader for the operating system depending on the architecture specified via the command line argument target_arch

pub fn build(b: *std.Build) anyerror!void {
    const optimize = b.standardOptimizeOption(.{});

    // Define the supported target architectures
    const TargetArch = enum { riscv32, riscv64, arm };

    // Parse the target architecture from command line or use a default
    const target_arch_str = b.option([]const u8, "target_arch", "The target architecture to build for (riscv32, riscv64, or arm)") orelse @panic("Target CPU architecture must be specified");
    const target_arch = std.meta.stringToEnum(TargetArch, target_arch_str) orelse {
        std.debug.print("Error: Invalid target architecture '{s}'. Supported architectures are: riscv32, riscv64, arm\n", .{target_arch_str});
        return error.InvalidTargetArch;
    };

    // Define the target architecture that the kernel will be built for
    const target = switch (target_arch) {
        .riscv32 => b.standardTargetOptions(.{ .default_target = .{
            .cpu_arch = .riscv32,
            .os_tag = .freestanding,
            .abi = .none,
        }}),
        .riscv64 => b.standardTargetOptions(.{
            .default_target = .{
                .cpu_arch = .riscv64,
                .os_tag = .freestanding,
                .abi = .none,
            }
        }),
        .arm => b.standardTargetOptions(.{
            .default_target = .{
                .cpu_arch = .aarch64,
                .os_tag = .freestanding,
                .abi = .none,
            }
        }),
    };

    const kernel = b.addExecutable(.{
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
        .name = "kernel",
        .code_model = .medium,
    });

    // Set the appropriate linker script based on the target architecture
    const linker_script = switch (target.result.cpu.arch) {
        .riscv32 => "src/arch/riscv/32/linker.lds",
        .riscv64 => "src/arch/riscv/64/linker.lds",
        .arm => "src/arch/arm/linker.lds",
        .x86_64 => "src/arch/x86_64/linker.lds",
        else => unreachable,
    };

    kernel.setLinkerScriptPath(b.path(linker_script));

    // Set the boot-code depending on the target architecture
    const boot_code = switch (target.result.cpu.arch) {
        .riscv32 => "src/arch/riscv/32/boot.S",
        .riscv64 => "src/arch/riscv/64/boot.S",
        .arm => "src/arch/arm/boot.S",
        else => unreachable,
    };

    kernel.addCSourceFiles(.{
        .files = &.{boot_code},
        .flags = &.{
            "-x", "assembler-with-cpp",
        },
    });
    b.installArtifact(kernel);

    const qemu = switch (target.result.cpu.arch) {
        .riscv64 => "qemu-system-riscv64",
        .riscv32 => "qemu-system-riscv32",
        .arm => "qemu-system-aarch64",
        else => unreachable,
    };

    const qemu_cpu = switch (target.result.cpu.arch) {
        .riscv64 => "rv64",
        .riscv32 => "rv32",
        .arm => "cortex-a53",
        else => unreachable,
    };

    const qemu_cmd = b.addSystemCommand(&.{
        qemu,                 "-machine",
        "virt",               "-bios",
        "none",               "-kernel",
        "zig-out/bin/kernel", "-m",
        "128M",               "-cpu",
        qemu_cpu,             "-smp",
        "4",                  "-nographic",
        "-serial",            "mon:stdio",
    });

    qemu_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| qemu_cmd.addArgs(args);
    const run_step = b.step("run", "Start the kernel in qemu");
    run_step.dependOn(&qemu_cmd.step);
}
