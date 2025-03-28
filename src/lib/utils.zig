//! This file provides utility functions for interacting with memory-mapped registers.

/// Read an 8-bit value from a memory-mapped register
pub fn readReg(base_addr: usize) u8 {
    const ptr: *volatile u8 = @ptrFromInt(base_addr);
    return ptr.*;
}

/// Write an 8-bit value to a memory-mapped register
pub fn writeReg(base_addr: usize, value: u8) void {
    const ptr: *volatile u8 = @ptrFromInt(base_addr);
    ptr.* = value;
}

/// Read a byte from an x86 I/O port
pub fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

/// Write a byte to an x86 I/O port
pub fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [value] "{al}" (value),
          [port] "N{dx}" (port),
    );
}

/// Read a byte from memory
pub fn readByte(base_addr: usize) u8 {
    const ptr: *volatile u8 = @ptrFromInt(base_addr);
    return ptr.*;
}

/// Write a byte to memory
pub fn writeByte(base_addr: usize, value: u8) void {
    const ptr: *volatile u8 = @ptrFromInt(base_addr);
    ptr.* = value;
}

/// Read a halfword from memory
pub fn readHalfWord(base_addr: usize) u16 {
    const ptr: *volatile u16 = @ptrFromInt(base_addr);
    return ptr.*;
}

/// Write a halfword to memory
pub fn writeHalfWord(base_addr: usize, value: u16) void {
    const ptr: *volatile u16 = @ptrFromInt(base_addr);
    ptr.* = value;
}

/// Read a word from memory
pub fn readWord(base_addr: usize) u32 {
    const ptr: *volatile u32 = @ptrFromInt(base_addr);
    return ptr.*;
}

/// Write a word to memory
pub fn writeWord(base_addr: usize, value: u32) void {
    const ptr: *volatile u32 = @ptrFromInt(base_addr);
    ptr.* = value;
}

/// Read a doubleword from memory
pub fn readDoubleWord(base_addr: usize) u64 {
    const ptr: *volatile u64 = @ptrFromInt(base_addr);
    return ptr.*;
}

/// Writes a doubleword to memory
pub fn writeDoubleWord(base_addr: usize, value: u64) void {
    const ptr: *volatile u64 = @ptrFromInt(base_addr);
    ptr.* = value;
}
