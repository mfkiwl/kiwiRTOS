//! This file provides an interface to the Intel 8042 PS/2 controller.

const arch = @import("../../arch/arch.zig");
const std = @import("std");

/// PS/2 controller data port
pub const DATA_PORT = arch.PS2_DATA_PORT;

/// PS/2 controller status port
pub const STATUS_PORT = arch.PS2_STATUS_PORT;

/// PS/2 controller command port
pub const COMMAND_PORT = arch.PS2_COMMAND_PORT;

/// PS/2 controller status register
pub const StatusRegister = packed struct {
    /// Output buffer status (0 = empty, 1 = full)
    outputBuffer: u1,
    /// Input buffer status (0 = empty, 1 = full)
    inputBuffer: u1,
    /// System Flag (0 = cleared, 1 = set after self-test pass)
    systemFlag: u1,
    /// Command/data flag (0 = data for PS/2 device, 1 = for PS/2 command)
    commandData: u1,
    /// Chipset specific, possibly keyboard lock
    unknown: u1,
    /// Chip specific, possibly receive time-out or second port
    unknown2: u1,
    /// Time-out error (0 = no error, 1 = error)
    timeoutError: u1,
    /// Parity error (0 = no error, 1 = error)
    parityError: u1,
};

/// PS/2 controller commands
pub const Command = struct {
    pub const READ_CONFIG: u8 = 0x20;
    pub const WRITE_CONFIG: u8 = 0x60;
    pub const DISABLE_PORT1: u8 = 0xAD;
    pub const DISABLE_PORT2: u8 = 0xA7;
    pub const ENABLE_PORT1: u8 = 0xAE;
    pub const ENABLE_PORT2: u8 = 0xA8;
    pub const TEST_CONTROLLER: u8 = 0xAA;
    pub const TEST_PORT1: u8 = 0xAB;
    pub const TEST_PORT2: u8 = 0xA9;
};

/// PS/2 controller configuration bits
pub const Config = struct {
    pub const PORT1_INT: u8 = 0x01;
    pub const PORT2_INT: u8 = 0x02;
    pub const SYSTEM_FLAG: u8 = 0x04;
    pub const PORT1_CLK: u8 = 0x10;
    pub const PORT2_CLK: u8 = 0x20;
    pub const PORT1_TRANSLATION: u8 = 0x40;
};

/// PS/2 controller responses
pub const Response = struct {
    pub const ACK: u8 = 0xFA;
    pub const RESEND: u8 = 0xFE;
    pub const SELF_TEST_PASS: u8 = 0xAA;
    pub const PORT_TEST_PASS: u8 = 0x00;
};

/// Read a byte from an I/O port
pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

/// Write a byte to an I/O port
pub inline fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [value] "{al}" (value),
          [port] "N{dx}" (port),
    );
}

/// Read the status register
pub fn readStatus() StatusRegister {
    const value = inb(STATUS_PORT);
    return @bitCast(value);
}

/// Wait for PS/2 controller to be ready for writing
pub fn waitWrite() bool {
    var timeout: u16 = 1000;
    while (timeout > 0) : (timeout -= 1) {
        const status = readStatus();
        if (status.inputBuffer == 0) {
            return true;
        }
        // Short delay
        asm volatile ("pause");
    }
    return false;
}

/// Wait for PS/2 controller to have data available
pub fn waitRead() bool {
    var timeout: u16 = 1000;
    while (timeout > 0) : (timeout -= 1) {
        const status = readStatus();
        if (status.outputBuffer == 1) {
            return true;
        }
        // Short delay
        asm volatile ("pause");
    }
    return false;
}

/// Send a command to the PS/2 controller
pub fn sendCommand(cmd: u8) bool {
    if (!waitWrite()) return false;
    outb(COMMAND_PORT, cmd);
    return true;
}

/// Send data to the PS/2 controller
pub fn sendData(data: u8) bool {
    if (!waitWrite()) return false;
    outb(DATA_PORT, data);
    return true;
}

/// Read data from the PS/2 controller
pub fn readData() ?u8 {
    if (!waitRead()) return null;
    return inb(DATA_PORT);
}

/// Flush the output buffer
pub fn flushOutputBuffer() void {
    _ = inb(DATA_PORT);
}

/// Initialize the PS/2 controller
pub fn init() bool {
    // Disable both PS/2 ports
    if (!sendCommand(Command.DISABLE_PORT1)) return false;
    if (!sendCommand(Command.DISABLE_PORT2)) return false;

    // Flush the output buffer
    flushOutputBuffer();

    // Read the current configuration
    if (!sendCommand(Command.READ_CONFIG)) return false;
    const config = readData() orelse return false;

    // Modify configuration: enable port 1 interrupt and clock, disable port 2
    const new_config = (config & ~(Config.PORT2_INT | Config.PORT2_CLK)) |
        (Config.PORT1_INT | Config.PORT1_CLK);

    // Write the new configuration
    if (!sendCommand(Command.WRITE_CONFIG)) return false;
    if (!sendData(new_config)) return false;

    // Enable PS/2 port 1
    if (!sendCommand(Command.ENABLE_PORT1)) return false;

    return true;
}
