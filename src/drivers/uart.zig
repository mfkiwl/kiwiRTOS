//! This file provides a UART driver based on the OpenSBI NS16550 UART driver.

const std = @import("std");
const utils = @import("../lib/utils.zig");

/// Physical memory address of the UART
pub const UART_BASE = 0x10000000; //QEMU RISC-V virtual platform

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
    /// Current baud rate
    baud_rate: u32,
    /// Current data bits
    data_bits: u8,
    /// Current stop bits
    stop_bits: u8,
    /// Current parity
    parity: u8,

    /// Initialize a new UART driver with default settings
    pub fn init() UartDriver {
        return UartDriver{
            .baud_rate = 9600,
            .data_bits = 8,
            .stop_bits = 1,
            .parity = 0,
        };
    }
};

fn write_reg(offset: usize, value: u8) void {
    const ptr: *volatile u8 = @ptrFromInt(UART_BASE + offset);
    ptr.* = value;
}

fn read_reg(offset: usize) u8 {
    const ptr: *volatile u8 = @ptrFromInt(UART_BASE + offset);
    return ptr.*;
}

pub fn put_char(ch: u8) void {
    // Wait for transmission bit to be empty before enqueuing more characters
    // to be outputted.
    while ((read_reg(UartRegisters.LSR) & UartLSRFlags.THRE) == 0) {}

    write_reg(0, ch);
}

pub fn get_char() ?u8 {
    // Check that we actually have a character to read, if so then we read it
    // and return it.
    if (read_reg(UartRegisters.LSR) & UartLSRFlags.DR == 1) {
        return read_reg(UartRegisters.RBR);
    } else {
        return null;
    }
}

pub fn init() void {
    const lcr = (1 << 0) | (1 << 1);
    write_reg(UartRegisters.LCR, lcr);
    write_reg(UartRegisters.FCR, (1 << 0));
    write_reg(UartRegisters.IER, (1 << 0));
    write_reg(UartRegisters.LCR, lcr | (1 << 7));

    const divisor: u16 = 592;
    const divisor_least: u8 = divisor & 0xff;
    const divisor_most: u8 = divisor >> 8;
    write_reg(UartRegisters.DLL, divisor_least);
    write_reg(UartRegisters.DLM, divisor_most);

    write_reg(UartRegisters.LCR, lcr);
}
