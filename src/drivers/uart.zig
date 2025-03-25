//! This file provides a UART driver based on the OpenSBI NS16550 UART driver.

const std = @import("std");
const utils = @import("../lib/utils.zig");

/// Physical memory address of the UART
pub const UART_BASE = 0x10000000; // QEMU RISC-V virtual platform

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
    /// Base address of this UART device
    base_addr: usize,
    /// Current baud rate
    baud_rate: u32,
    /// Current data bits
    data_bits: u8,
    /// Current stop bits
    stop_bits: u8,
    /// Current parity
    parity: u8,
    writer: Writer,

    /// Initialize a new UART driver
    pub fn init(self: *UartDriver, base_addr: usize, baud_rate: u32) void {
        self.base_addr = base_addr;
        self.baud_rate = baud_rate;
        self.data_bits = 8;
        self.stop_bits = 1;
        self.parity = 0;
        self.writer = .{ .context = self };

        const lcr = (1 << 0) | (1 << 1);
        utils.writeByte(self.base_addr + UartRegisters.LCR, lcr);
        utils.writeByte(self.base_addr + UartRegisters.FCR, (1 << 0));
        utils.writeByte(self.base_addr + UartRegisters.IER, (1 << 0));
        utils.writeByte(self.base_addr + UartRegisters.LCR, lcr | (1 << 7));

        const divisor: u16 = 592;
        const divisor_least: u8 = divisor & 0xff;
        const divisor_most: u8 = divisor >> 8;
        utils.writeByte(self.base_addr + UartRegisters.DLL, divisor_least);
        utils.writeByte(self.base_addr + UartRegisters.DLM, divisor_most);
        utils.writeByte(self.base_addr + UartRegisters.LCR, lcr);
    }

    pub fn putChar(self: *UartDriver, ch: u8) void {
        // Wait for transmission bit to be empty before enqueuing more characters
        // to be outputted.
        while ((utils.readByte(self.base_addr + UartRegisters.LSR) & UartLSRFlags.THRE) == 0) {}

        utils.writeByte(self.base_addr + UartRegisters.RBR, ch);
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

/// Writer type for std library integration
const Writer = std.io.Writer(*UartDriver, error{}, UartDriver.writerFn);
