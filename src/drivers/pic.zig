//! This file provides a PIC driver based on the IBM PC/AT 8259 Programmable Interrupt Controller (PIC).

const std = @import("std");
const arch = @import("../arch/arch.zig");

/// PIC1 (master PIC) and PIC2 (slave PIC) I/O ports
pub const PicPort = enum(u8) {
    /// PIC1 (master) command port
    PIC1_COMMAND = 0x20,
    /// PIC1 (master) data port
    PIC1_DATA = 0x21,
    /// PIC2 (slave) command port
    PIC2_COMMAND = 0xA0,
    /// PIC2 (slave) data port
    PIC2_DATA = 0xA1,
};

/// PIC implemented commands codes
pub const PicCommand = enum(u8) {
    /// End-of-interrupt command
    PIC_EOI = 0x20,
    /// Read Interrupt Request Register (IRR)
    PIC_READ_IRR = 0x0A,
    /// Read In-Service Register (ISR)
    PIC_READ_ISR = 0x0B,
};

// Initialization Command Words (ICW)

/// Initialization Command Word 1 (ICW1)
pub const ICW1 = enum(u8) {
    /// Indicates that ICW4 will be present
    ICW1_ICW4 = 0x01,
    /// Single (cascade) mode
    ICW1_SINGLE = 0x02,
    /// Call address interval 4 (8)
    ICW1_INTERVAL4 = 0x04,
    /// Level triggered (edge) mode
    ICW1_LEVEL = 0x08,
    /// Initialization required
    ICW1_INIT = 0x10,
};

/// Initialization Command Word 4 (ICW4)
pub const ICW4 = enum(u8) {
    /// 8086/88 mode
    ICW4_8086 = 0x01,
    /// Auto EOI
    ICW4_AUTO = 0x02,
    /// Buffered mode/slave
    ICW4_BUF_SLAVE = 0x08,
    /// Buffered mode/master
    ICW4_BUF_MASTER = 0x0C,
    /// Special fully nested mode
    ICW4_SFNM = 0x10,
};

// Default IRQ numbers
pub const IRQ_BASE = 0x20;
pub const IRQ0_TIMER = IRQ_BASE;
pub const IRQ1_KEYBOARD = IRQ_BASE + 1;
pub const IRQ2_CASCADE = IRQ_BASE + 2;
pub const IRQ3_COM2 = IRQ_BASE + 3;
pub const IRQ4_COM1 = IRQ_BASE + 4;
pub const IRQ5_LPT2 = IRQ_BASE + 5;
pub const IRQ6_FLOPPY = IRQ_BASE + 6;
pub const IRQ7_LPT1 = IRQ_BASE + 7;
pub const IRQ8_RTC = IRQ_BASE + 8;
pub const IRQ9_ACPI = IRQ_BASE + 9;
pub const IRQ10_AVAILABLE = IRQ_BASE + 10;
pub const IRQ11_AVAILABLE = IRQ_BASE + 11;
pub const IRQ12_PS2_MOUSE = IRQ_BASE + 12;
pub const IRQ13_FPU = IRQ_BASE + 13;
pub const IRQ14_IDE_PRIMARY = IRQ_BASE + 14;
pub const IRQ15_IDE_SECONDARY = IRQ_BASE + 15;

/// PIC
pub const Pic = struct {
    /// Offset for the master PIC
    offset_master: u8,
    /// Offset for the slave PIC
    offset_slave: u8,

    /// Initialize the PIC
    pub fn init(offset_master: u8, offset_slave: u8) Pic {
        var controller: Pic = Pic{
            .offset_master = offset_master,
            .offset_slave = offset_slave,
        };
        controller.icw1 = ICW1{
            .ic4 = 1,
            .sngl = 1,
            .adi = 1,
            .ltim = 1,
            .init = 0b001,
        };

        // Disable interrupts
        arch.cli();

        // Remap the PIC IRQs
        // Initialize both PICs by giving them new offsets (IRQ_BASE) that don't conflict with CPU exceptions
        controller.remap();

        // Enable interrupts
        arch.sti();

        return controller;
    }

    /// Remap the PIC IRQs
    pub fn remap() void {
        // ICW1: Initialize PIC
        arch.outb(.PIC1_COMMAND, ICW1.ICW1_INIT | ICW1.ICW1_ICW4);
        arch.outb(.PIC2_COMMAND, ICW1.ICW1_INIT | ICW1.ICW1_ICW4);

        // ICW2: Set PIC interrupt vector offsets
        arch.outb(.PIC1_DATA, IRQ_BASE); // Master PIC vector offset (IRQ 0-7: 0x20-0x27)
        arch.outb(.PIC2_DATA, IRQ_BASE + 8); // Slave PIC vector offset (IRQ 8-15: 0x28-0x2F)

        // ICW3: Tell PICs about each other
        arch.outb(.PIC1_DATA, 0x04); // Tell PIC1 that PIC2 is at IRQ2 (0000 0100)
        arch.outb(.PIC2_DATA, 0x02); // Tell PIC2 its cascade identity (0000 0010)

        // ICW4: Set mode

        // Set mode: 8086/88 mode
        arch.outb(.PIC1_DATA, ICW4.ICW4_8086);
        arch.outb(.PIC2_DATA, ICW4.ICW4_8086);

        // Mask all interrupts (disable all IRQs)
        arch.outb(.PIC1_DATA, 0xFF);
        arch.outb(.PIC2_DATA, 0xFF);
    }

    /// Enable (unmask) a specific IRQ line
    pub fn enableIrq(irq: u8) void {
        const port = if (irq < 8) .PIC1_DATA else .PIC2_DATA;
        // Set the IRQ mask (1 = disabled, 0 = enabled)
        const value = arch.inb(port) & ~@as(u8, 1 << @truncate(irq & 7));
        arch.outb(port, value);
    }

    /// Disable (mask) a specific IRQ line
    pub fn disableIrq(irq: u8) void {
        const port = if (irq < 8) .PIC1_DATA else .PIC2_DATA;
        // Set the IRQ mask (1 = disabled, 0 = enabled)
        const value = arch.inb(port) | (1 << @truncate(irq & 7));
        arch.outb(port, value);
    }

    /// Send end-of-interrupt signal to PIC(s)
    pub fn sendEoi(irq: u8) void {
        // If the IRQ is for the slave PIC, send EOI to both PICs
        if (irq >= 8) arch.outb(.PIC2_COMMAND, .PIC_EOI);
        // Always send EOI to master PIC
        arch.outb(.PIC1_COMMAND, .PIC_EOI);
    }

    /// Acknowledge an IRQ (send EOI)
    pub fn acknowledgeIrq(irq_num: u32) void {
        sendEoi(irq_num);
    }

    /// Check if an IRQ is pending
    fn isIrqPending(irq_num: u32) bool {
        const port = if (irq_num < 8) .PIC1_COMMAND else .PIC2_COMMAND;
        const mask = @as(u8, @truncate(1 << @as(u3, @truncate(irq_num % 8))));
        return (arch.inb(port) & mask) != 0;
    }
};
