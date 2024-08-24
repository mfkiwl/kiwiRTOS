const std = @import("std");
const Target = std.Target;
const CodeModel = std.zig.CodeModel;
const CrossTarget = std.zig.CrossTarget;

pub fn build(b: *std.Build) anyerror!void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = Target.Cpu.Arch.x86,
        .os_tag = Target.Os.Tag.freestanding,
        .abi = Target.Abi.none,
    });

    const optimize = b.standardOptimizeOption(.{});

    const kernel = b.addExecutable(.{
        .root_source_file = b.path("src/kernel.zig"),
        .optimize = optimize,
        .target = target,
        .name = "kiwiOS.elf",
        .code_model = CodeModel.kernel,
    });

    kernel.setLinkerScriptPath(b.path("src/linker.ld"));
    b.installArtifact(kernel);

    const kernel_step = b.step("kernel", "Build the kernel");
    kernel_step.dependOn(&kernel.step);

    // const iso_dir = b.fmt("{s}/iso_root", .{b.cache_root});
    // const kernel_path = b.getInstallPath(kernel.dest, kernel.out_filename);
    // b.mkdir(iso_dir);
    // b.print(kernel_path);
    // b.print("Copying kernel to ISO directory...");
}
