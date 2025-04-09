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
pub const UART_BUFFER = 0x3F8;
