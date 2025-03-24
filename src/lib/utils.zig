//! This file provides utility functions

/// Read an 8-bit value from a memory-mapped register
pub fn readReg(base_addr: usize, offset: usize) u8 {
    const ptr: *volatile u8 = @ptrFromInt(base_addr + offset);
    return ptr.*;
}

/// Write an 8-bit value to a memory-mapped register
pub fn writeReg(base_addr: usize, offset: usize, value: u8) void {
    const ptr: *volatile u8 = @ptrFromInt(base_addr + offset);
    ptr.* = value;
}

/// Read a byte from memory
pub fn readByte(base_addr: usize, offset: usize) u8 {
    const ptr: *volatile u8 = @ptrFromInt(base_addr + offset);
    return ptr.*;
}

/// Write a byte to memory
pub fn writeByte(base_addr: usize, offset: usize, value: u8) void {
    const ptr: *volatile u8 = @ptrFromInt(base_addr + offset);
    ptr.* = value;
}

/// Read a halfword from memory
pub fn readHalfWord(base_addr: usize, offset: usize) u16 {
    const ptr: *volatile u16 = @ptrFromInt(base_addr + offset);
    return ptr.*;
}

/// Write a halfword to memory
pub fn writeHalfWord(base_addr: usize, offset: usize, value: u16) void {
    const ptr: *volatile u16 = @ptrFromInt(base_addr + offset);
    ptr.* = value;
}

/// Read a word from memory
pub fn readWord(base_addr: usize, offset: usize) u32 {
    const ptr: *volatile u32 = @ptrFromInt(base_addr + offset);
    return ptr.*;
}

/// Write a word to memory
pub fn writeWord(base_addr: usize, offset: usize, value: u32) void {
    const ptr: *volatile u32 = @ptrFromInt(base_addr + offset);
    ptr.* = value;
}

/// Read a doubleword from memory
pub fn readDoubleWord(base_addr: usize, offset: usize) u64 {
    const ptr: *volatile u64 = @ptrFromInt(base_addr + offset);
    return ptr.*;
}

/// Writes a doubleword to memory
pub fn writeDoubleWord(base_addr: usize, offset: usize, value: u64) void {
    const ptr: *volatile u64 = @ptrFromInt(base_addr + offset);
    ptr.* = value;
}
