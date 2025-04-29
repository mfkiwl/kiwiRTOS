//! This file provides the Interrupt Descriptor Table (IDT) implementation.

const std = @import("std");
const arch = @import("arch.zig");

// IDT entry types
pub const IDT_TASK_GATE = 0x5;
pub const IDT_INTERRUPT_GATE_16 = 0x6;
pub const IDT_TRAP_GATE_16 = 0x7;
pub const IDT_INTERRUPT_GATE_32 = 0xE;
pub const IDT_TRAP_GATE_32 = 0xF;

extern const isr_stub_table: []void;

// Descriptor privilege level (DPL)
pub const DPL = enum(u2) {
    /// DPL for kernel code and data
    KERNEL = 0,
    /// DPL for user code and data
    USER = 3,
};

// Number of entries in the IDT
pub const IDT_ENTRIES = 256;

// GDT segment selector for kernel code
pub const GDT_KERNEL_CODE_SEGMENT = 0x08;

// IDT Entry structure (64-bit)
pub const IdtEntry = packed struct {
    /// The lower bits of the ISR's address
    isr_low: u16,
    /// The GDT segment selector that the CPU will load into CS before calling the ISR
    kernel_cs: u16,
    /// The IST in the TSS that the CPU will load into RSP; set to zero for now
    ist: Ist,
    /// Attributes
    attributes: IdtAttributes,
    /// Middle 16 bits of handler function address
    offset_mid: u16,
    /// Upper 32 bits of handler function address
    offset_high: u32,
    /// Reserved, should be 0
    reserved: u32 = 0,
};

// Interrupt Stack Table (IST)
pub const Ist = packed struct {
    /// The interrupt stack table offset
    offset: u3,
    /// Reserved, should be 0
    reserved: u35 = 0,
};

pub const IdtAttributes = packed struct {
    /// Gate type (e.g., interrupt gate, trap gate)
    gate_type: u4,
    /// Reserved, should be 0
    reserved: u1 = 0,
    /// Descriptor Privilege Level
    dpl: u2,
    /// Present bit
    present: u1,
};

// IDT Register (IDTR)
pub const IdtRegister = packed struct {
    /// Size of IDT - 1
    limit: u16,
    /// Base address of IDT
    base: u64,
};

/// Interrupt Descriptor Table (IDT)
pub const Idt = struct {
    /// IDT entries; aligned to 16 bytes
    entries: [IDT_ENTRIES]IdtEntry align(0x10),
    /// Vectors that are used by the IDT
    vectors: [IDT_ENTRIES]bool,
    /// IDT register (IDTR)
    idtr: IdtRegister,

    /// Initialize the IDT
    pub fn init() Idt {
        var idt: Idt = Idt{
            .entries = undefined,
            .vectors = undefined,
            .idtr = undefined,
        };

        // Set the IDT entries
        idt.setEntries();

        // Load the IDT
        idt.loadIdt();

        return idt;
    }

    /// Clear the IDT
    pub fn clear(self: *Idt) void {
        for (0..IDT_ENTRIES) |i| {
            self.entries[i] = IdtEntry{
                .isr_low = 0,
                .kernel_cs = 0,
                .ist = 0,
                .attributes = 0,
                .offset_mid = 0,
                .offset_high = 0,
                .reserved = 0,
            };
            self.vectors[i] = false;
        }
    }

    /// Set the IDT entries
    pub fn setEntries(self: *Idt) void {
        for (0..IDT_ENTRIES) |vector| {
            self.setDescriptor(vector, @intFromPtr(isr_stub_table[vector]), 0x8E);
            self.vectors[vector] = true;
        }
    }

    /// Load the IDT
    pub inline fn loadIdt(self: *Idt) void {
        // Create IDT register
        self.idtr = IdtRegister{
            .limit = @sizeOf(@TypeOf(self.entries)) - 1,
            .base = @intFromPtr(&self.entries),
        };

        // Load IDT with LIDT instruction
        asm volatile ("lidt (%[idt_reg])"
            :
            : [idt_reg] "r" (&self.idtr),
        );
        // Enable interrupts
        arch.sti();
    }

    // Set an IDT descriptor entry
    pub fn setDescriptor(self: *Idt, vector: u8, isr: u64, flags: u8) void {
        self.entries[vector].isr_low = @truncate(isr & 0xFFFF);
        self.entries[vector].kernel_cs = GDT_KERNEL_CODE_SEGMENT;
        self.entries[vector].ist = 0;
        self.entries[vector].attributes = flags;
        self.entries[vector].offset_mid = @truncate((isr >> 16) & 0xFFFF);
        self.entries[vector].offset_high = @truncate((isr >> 32) & 0xFFFFFFFF);
    }
};

/// Exception handler
pub export fn exception_handler() callconv(.C) noreturn {
    while (true) {
        arch.cli();
        arch.hlt();
    }
}
