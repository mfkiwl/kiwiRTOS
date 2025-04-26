//! This file provides the Interrupt Descriptor Table (IDT) implementation.

const std = @import("std");
const arch = @import("arch.zig");

// IDT entry types
pub const IDT_TASK_GATE = 0x5;
pub const IDT_INTERRUPT_GATE_16 = 0x6;
pub const IDT_TRAP_GATE_16 = 0x7;
pub const IDT_INTERRUPT_GATE_32 = 0xE;
pub const IDT_TRAP_GATE_32 = 0xF;

// Descriptor privilege level (DPL)
pub const DPL = enum(u2) {
    /// DPL for kernel code and data
    KERNEL = 0,
    /// DPL for user code and data
    USER = 3,
};

// Number of entries in the IDT
pub const IDT_ENTRIES = 256;

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
    /// IDT register (IDTR)
    idtr: IdtRegister,

    /// Initialize the IDT
    pub fn init() Idt {
        var idt: Idt = Idt{
            .entries = undefined,
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
    }
    // Set an IDT entry
    pub fn setEntry(self: *Idt, n: u8, handler: u64, segsel: u16, ist: u3, gate_type: u4, dpl: u2, present: u1) void {
        self.entries[n].isr_low = @truncate(handler & 0xFFFF);
        self.entries[n].kernel_cs = segsel;
        self.entries[n].ist = ist;
        self.entries[n].attributes.gate_type = gate_type;
        self.entries[n].attributes.dpl = dpl;
        self.entries[n].attributes.present = present;
        self.entries[n].offset_mid = @truncate((handler >> 16) & 0xFFFF);
        self.entries[n].offset_high = @truncate((handler >> 32) & 0xFFFFFFFF);
    }
};
