//! This file provides architecture-specific definitions for the kiwiRTOS kernel.

const builtin = @import("builtin");

// Import the appropriate architecture-specific module
const arch_impl = switch (builtin.cpu.arch) {
    .x86_64 => @import("x86_64/arch.zig"),
    .aarch64 => @import("arm/arch.zig"),
    .riscv64, .riscv32 => @import("riscv/arch.zig"),
    else => @compileError("Unsupported architecture"),
};

// Re-export architecture-specific functions
pub const outb = arch_impl.outb;
pub const inb = arch_impl.inb;

// Re-export architecture-specific constants
pub const VGA_TEXT_BUFFER = arch_impl.VGA_TEXT_BUFFER;
pub const UART_BUFFER = arch_impl.UART_BUFFER;
pub const PS2_DATA_PORT = arch_impl.PS2_DATA_PORT;
pub const PS2_STATUS_PORT = arch_impl.PS2_STATUS_PORT;
pub const PS2_COMMAND_PORT = arch_impl.PS2_COMMAND_PORT;
