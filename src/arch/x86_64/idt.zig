//! This file provides the Interrupt Descriptor Table (IDT) implementation.

const std = @import("std");
const arch = @import("arch.zig");

// IDT entry types256
pub const IDT_TASK_GATE = 0x5;
pub const IDT_INTERRUPT_GATE_16 = 0x6;
pub const IDT_TRAP_GATE_16 = 0x7;
pub const IDT_INTERRUPT_GATE_32 = 0xE;
pub const IDT_TRAP_GATE_32 = 0xF;

// Descriptor privilege levels
pub const DPL_KERNEL = 0;
pub const DPL_USER = 3;

// Number of entries in the IDT
pub const IDT_ENTRIES = 256;

// IDT Entry structure (64-bit)
pub const IdtEntry = packed struct {
    /// The lower bits of the handler function address
    function_low: u16,
    /// The code segment selector
    segment_selector: u16,
    /// The interrupt stack table offset
    ist: u3,
    /// Reserved, should be 0
    reserved0: u5 = 0,
    /// Gate type (e.g., interrupt gate, trap gate)
    gate_type: u4,
    /// Reserved, should be 0
    reserved1: u1 = 0,
    /// Descriptor Privilege Level
    dpl: u2,
    /// Present bit
    present: u1,
    /// Middle 16 bits of handler function address
    offset_mid: u16,
    /// Upper 32 bits of handler function address
    offset_high: u32,
    /// Reserved, should be 0
    reserved2: u32 = 0,
};

// IDT Descriptor structure
pub const IdtDescriptor = packed struct {
    /// Size of IDT - 1
    size: u16,
    /// Base address of IDT
    offset: u64,
};

// Our global IDT and IDT descriptor
pub var idt: [IDT_ENTRIES]IdtEntry = undefined;
pub var idt_descriptor: IdtDescriptor = undefined;

// Set an IDT entry
pub fn setGate(n: u8, handler: u64, segsel: u16, ist: u3, gate_type: u4, dpl: u2, present: u1) void {
    idt[n].offset_low = @truncate(handler & 0xFFFF);
    idt[n].segment_selector = segsel;
    idt[n].ist = ist;
    idt[n].gate_type = gate_type;
    idt[n].dpl = dpl;
    idt[n].present = present;
    idt[n].offset_mid = @truncate((handler >> 16) & 0xFFFF);
    idt[n].offset_high = @truncate((handler >> 32) & 0xFFFFFFFF);
}

// Load the IDT
pub inline fn loadIdt() void {
    // Create IDT descriptor
    idt_descriptor = IdtDescriptor{
        .size = @sizeOf(@TypeOf(idt)) - 1,
        .offset = @intFromPtr(&idt),
    };

    // Load IDT with LIDT instruction
    asm volatile ("lidt (%[idt_desc])"
        :
        : [idt_desc] "r" (&idt_descriptor),
    );
}

// Initialize the IDT
pub fn init() void {
    // Clear IDT
    for (0..IDT_ENTRIES) |i| {
        setGate(@truncate(i), 0, 0, 0, 0, 0, 0);
    }

    // Load IDT
    loadIdt();
}
