//! This file provides RISC-V specific definitions.

const std = @import("std");

// Import the appropriate architecture-specific module
const arch_impl = switch (std.builtin.cpu.arch) {
    .riscv64 => @import("./64/arch.zig"),
    .riscv32 => @import("./32/arch.zig"),
    else => @compileError("Unsupported architecture"),
};
