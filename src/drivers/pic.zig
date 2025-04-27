//! This file provides a PIC driver based on the IBM PC/AT 8259 Programmable Interrupt Controller (PIC).

const std = @import("std");
const arch = @import("../arch/arch.zig");

/// PIC1 and PIC2 ports
pub const PicPort = enum(u8) {
    /// PIC1 command port
    PIC1_COMMAND = 0x20,
    /// PIC1 data port
    PIC1_DATA = 0x21,
    /// PIC2 command port
    PIC2_COMMAND = 0xA0,
    /// PIC2 data port
    PIC2_DATA = 0xA1,
};

/// PIC implemented commands
pub const PicCommand = enum(u8) {
    /// End of interrupt command
    PIC_EOI = 0x20,
    /// Read Interrupt Request Register
    PIC_READ_IRR = 0x0A,
    /// Read In-Service Register
    PIC_READ_ISR = 0x0B,
};
