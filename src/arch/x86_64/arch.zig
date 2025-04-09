//! This file provides x86_64-specific definitions.

/// Read a byte from an x86_64 I/O port
pub fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

/// Write a byte to an x86_64 I/O port
pub fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [value] "{al}" (value),
          [port] "N{dx}" (port),
    );
}

/// VGA text mode buffer address for x86_64
pub const VGA_TEXT_BUFFER = 0xB8000;

/// UART buffer address for x86_64
pub const UART_BUFFER = 0x3F8;

/// PS/2 controller data port (read/write)
pub const PS2_DATA_PORT = 0x60;

/// PS/2 controller status port (read)
pub const PS2_STATUS_PORT = 0x64;

/// PS/2 controller command port (write)
pub const PS2_COMMAND_PORT = 0x64;
