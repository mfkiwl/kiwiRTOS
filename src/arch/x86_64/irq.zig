//! This file provides x86_64-specific IRQ handling.

const arch = @import("arch.zig");
const irq = @import("../../kernel/irq.zig");

/// PIC (Programmable Interrupt Controller) ports
const PIC1_COMMAND = 0x20;
const PIC1_DATA = 0x21;
const PIC2_COMMAND = 0xA0;
const PIC2_DATA = 0xA1;

/// PIC commands
const PIC_EOI = 0x20; // End of Interrupt

/// Initialize the PIC
pub fn initPic() void {
    // ICW1: Initialize PIC
    arch.outb(PIC1_COMMAND, 0x11);
    arch.outb(PIC2_COMMAND, 0x11);

    // ICW2: Set interrupt vector offsets
    arch.outb(PIC1_DATA, 0x20); // IRQ 0-7: 32-39
    arch.outb(PIC2_DATA, 0x28); // IRQ 8-15: 40-47

    // ICW3: Tell PICs about each other
    arch.outb(PIC1_DATA, 0x04); // PIC1: PIC2 at IRQ2
    arch.outb(PIC2_DATA, 0x02); // PIC2: Cascade identity

    // ICW4: Set mode
    arch.outb(PIC1_DATA, 0x01); // 8086 mode
    arch.outb(PIC2_DATA, 0x01); // 8086 mode

    // Mask all interrupts initially
    arch.outb(PIC1_DATA, 0xFF);
    arch.outb(PIC2_DATA, 0xFF);
}

/// Enable a specific IRQ
fn enableIrq(irq_num: u32) void {
    const port = if (irq_num < 8) PIC1_DATA else PIC2_DATA;
    const value = arch.inb(port) & ~@as(u8, @truncate(1 << @as(u3, @truncate(irq_num % 8))));
    arch.outb(port, value);
}

/// Disable a specific IRQ
fn disableIrq(irq_num: u32) void {
    const port = if (irq_num < 8) PIC1_DATA else PIC2_DATA;
    const value = arch.inb(port) | @as(u8, @truncate(1 << @as(u3, @truncate(irq_num % 8))));
    arch.outb(port, value);
}

/// Acknowledge an IRQ (send EOI)
fn acknowledgeIrq(irq_num: u32) void {
    if (irq_num >= 8) {
        arch.outb(PIC2_COMMAND, PIC_EOI);
    }
    arch.outb(PIC1_COMMAND, PIC_EOI);
}

/// Check if an IRQ is pending
fn isIrqPending(irq_num: u32) bool {
    const port = if (irq_num < 8) PIC1_COMMAND else PIC2_COMMAND;
    const mask = @as(u8, @truncate(1 << @as(u3, @truncate(irq_num % 8))));
    return (arch.inb(port) & mask) != 0;
}

/// x86_64 IRQ controller
pub const x86_64IrqController = irq.IrqController{
    .enableFn = enableIrq,
    .disableFn = disableIrq,
    .acknowledgeFn = acknowledgeIrq,
    .isPendingFn = isIrqPending,
}; 