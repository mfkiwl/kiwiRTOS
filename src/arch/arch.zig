//! This file provides architecture-specific definitions for the kiwiRTOS kernel.

const builtin = @import("builtin");

// Import the appropriate architecture-specific module
const arch_impl = switch (builtin.cpu.arch) {
    .x86_64 => @import("./x86_64/arch.zig"),
    .aarch64 => @import("./arm/arch.zig"),
    .riscv64, .riscv32 => @import("./riscv/arch.zig"),
    else => @compileError("Unsupported architecture"),
};

// Re-export architecture-specific functions
/// Read a byte from an I/O port
pub const outb = arch_impl.outb;
/// Write a byte to an I/O port
pub const inb = arch_impl.inb;
/// Disable interrupts
pub const cli = arch_impl.cli;
/// Enable interrupts
pub const sti = arch_impl.sti;

// Re-export architecture-specific constants

// Memory-mapped I/O addresses

/// Generic VGA text mode buffer address
pub const VGA_TEXT_BUFFER = arch_impl.VGA_TEXT_BUFFER;
/// Generic UART buffer address
pub const UART_BUFFER = arch_impl.UART_BUFFER;

// Port‑mapped I/O

/// Generic PS/2 controller data port (read/write)
pub const PS2_DATA_PORT = arch_impl.PS2_DATA_PORT;
/// Generic PS/2 controller status port (read)
pub const PS2_STATUS_PORT = arch_impl.PS2_STATUS_PORT;
/// Generic PS/2 controller command port (write)
pub const PS2_COMMAND_PORT = arch_impl.PS2_COMMAND_PORT;
