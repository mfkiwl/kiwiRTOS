//! This file provides a UART driver based on the OpenSBI NS16550 UART driver.

const std = @import("std");
const builtin = @import("builtin");

/// Writer type for std library integration
const Writer = std.io.Writer;

/// UART buffer address
pub const UART_BUFFER = switch (builtin.cpu.arch) {
    .x86 => 0x3F8,
    .aarch64 => 0x10000000, // QEMU AArch64 virtual platform
    .riscv64, .riscv32 => 0x10000000, // QEMU RISC-V virtual platform
    else => @compileError("Unsupported architecture"),
};

/// UART register offsets
pub const UartRegisters = struct {
    /// In: Recieve Buffer Register
    pub const RBR = 0x00;
    /// Out: Divisor Latch Low
    pub const DLL = 0x00;
    /// I/O: Interrupt Enable Register
    pub const IER = 0x01;
    /// Out: Divisor Latch High
    pub const DLM = 0x01;
    /// Out: FIFO Control Register
    pub const FCR = 0x02;
    /// Out: Line Control Register
    pub const LCR = 0x03;
    /// In:  Line Status Register
    pub const LSR = 0x05;
    /// I/O:  Mode Register
    pub const MDR1 = 0x08;
};

/// UART Line Status Register flags
pub const UartLSRFlags = struct {
    /// Receiver data ready
    pub const DR = 0x01;
    /// Transmit-hold-register empty
    pub const THRE = 0x20;
};

/// UART driver
pub const UartDriver = struct {
    /// Pointer to UART buffer (memory-mapped)
    buffer: [*]volatile u8,
    /// Current baud rate
    baud_rate: u32,
    /// Current data bits
    data_bits: u8,
    /// Current stop bits
    stop_bits: u8,
    /// Current parity
    parity: u8,
    /// Writer for std.io.Writer interface
    writer: Writer,

    /// Initialize a new UART driver
    pub fn init(buffer_addr: usize, baud_rate: u32) UartDriver {
        var driver: UartDriver = undefined;
        driver = UartDriver{
            .buffer = @ptrFromInt(buffer_addr),
            .baud_rate = baud_rate,
            .data_bits = 8,
            .stop_bits = 1,
            .parity = 0,
        };

        const lcr = (1 << 0) | (1 << 1);
        driver.buffer[UartRegisters.LCR] = lcr;
        driver.buffer[UartRegisters.FCR] = (1 << 0);
        driver.buffer[UartRegisters.IER] = (1 << 0);
        driver.buffer[UartRegisters.LCR] = lcr | (1 << 7);

        const divisor: u16 = 592;
        const divisor_least: u8 = divisor & 0xff;
        const divisor_most: u8 = divisor >> 8;
        driver.buffer[UartRegisters.DLL] = divisor_least;
        driver.buffer[UartRegisters.DLM] = divisor_most;
        driver.buffer[UartRegisters.LCR] = lcr;
    }

    pub fn putChar(self: *UartDriver, ch: u8) void {
        // Wait for transmission bit to be empty before enqueuing more characters
        // to be outputted.
        while ((self.buffer[UartRegisters.LSR] & UartLSRFlags.THRE) == 0) {}

        self.buffer[UartRegisters.RBR] = ch;
    }

    pub fn putStr(self: *UartDriver, str: []const u8) !usize {
        for (str) |ch| {
            self.putChar(ch);
        }
        return str.len;
    }

    /// Writer function for std.io.Writer interface
    pub fn writerFn(self: *UartDriver, bytes: []const u8) error{}!usize {
        return self.putStr(bytes);
    }

    pub fn println(self: *UartDriver, comptime fmt: []const u8, args: anytype) void {
        self.writer.print(fmt ++ "\n", args) catch {};
    }
};
