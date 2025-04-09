//! This file provides architecture-specific definitions for the kiwiRTOS kernel.

const builtin = @import("builtin");


/// import the appropriate architecture-specific module
pub fn import() void {
    switch (builtin.cpu.arch) {
        .x86 => @import("x86/arch.zig"),
        .aarch64 => @import("arm/arch.zig"),
        .riscv64, .riscv32 => @import("riscv/arch.zig"),
        else => @compileError("Unsupported architecture"),
    }
}
