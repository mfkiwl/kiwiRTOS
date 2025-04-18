//! This file provides an interface to the Intel 8042 PS/2 controller.

const arch = @import("../arch/arch.zig");
const std = @import("std");

/// PS/2 controller data port
pub const PS2_DATA_PORT = arch.PS2_DATA_PORT;

/// PS/2 controller status port
pub const PS2_STATUS_PORT = arch.PS2_STATUS_PORT;

/// PS/2 controller command port
pub const PS2_COMMAND_PORT = arch.PS2_COMMAND_PORT;

/// PS/2 controller commands
pub const ControllerCommand = enum(u8) {
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

/// PS/2 controller configuration byte
pub const ConfigurationByte = packed struct {
    /// First PS/2 port interrupt (1 = enabled, 0 = disabled)
    port1Interrupt: u1,
    /// Second PS/2 port interrupt (1 = enabled, 0 = disabled)
    port2Interrupt: u1,
    /// System Flag (1 = system passed POST, 0 = your OS shouldn't be running)
    systemFlag: u1,
    /// Should be zero
    reserved1: u1,
    /// First PS/2 port clock (1 = disabled, 0 = enabled)
    port1Clock: u1,
    /// First PS/2 port translation (1 = enabled, 0 = disabled)
    port1Translation: u1,
    /// Must be zero
    reserved2: u1,
};

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

/// PS/2 Controller Status Bits
pub const StatusBits = enum(u8) {
    pub const OUTPUT: u8 = 0x01;
    pub const INPUT: u8 = 0x02;
};

/// PS/2 controller responses
pub const Response = enum(u8) {
    pub const ACK: u8 = 0xFA;
    pub const RESEND: u8 = 0xFE;
    pub const SELF_TEST_PASS: u8 = 0xAA;
    pub const PORT_TEST_PASS: u8 = 0x00;
};

/// PS/2 controller driver
pub const Ps2Driver = struct {
    /// PS/2 controller data port (port-mapped)
    data_port: u16,
    /// PS/2 controller status port (port-mapped)
    status_port: u16,
    /// PS/2 controller command port (port-mapped)
    command_port: u16,

    /// PS/2 controller configuration byte
    config: ConfigurationByte,
    /// PS/2 controller status register
    status: StatusRegister,

    /// Initialize a PS/2 controller driver
    pub fn init(data_port: u16, status_port: u16, command_port: u16) Ps2Driver {
        var driver: Ps2Driver = undefined;
        driver = Ps2Driver{
            .data_port = data_port,
            .status_port = status_port,
            .command_port = command_port,
            .config = undefined,
            .status = undefined,
        };

        // Disable devices connected to both PS/2 ports
        driver.writeCommand(ControllerCommand.DISABLE_PORT1);
        driver.writeCommand(ControllerCommand.DISABLE_PORT2);

        // Read the PS/2 configuration byte


        // // Flush the output buffer
        // driver.flushOutputBuffer();

        // // Read the PS/2 configuration byte (need current configuration to update)
        // if (!driver.sendCommand(ControllerCommand.READ_CONFIG)) return null;
        // const config = driver.readData() orelse return null;

        // // Modify configuration: enable port 1 interrupt and clock, disable port 2
        // const new_config = (config & ~(ControllerCommand.DISABLE_PORT2 | ControllerCommand.DISABLE_PORT2_CLK)) |
        //     (ControllerCommand.ENABLE_PORT1 | ControllerCommand.ENABLE_PORT1_CLK);

        // // Write the new configuration
        // if (!driver.sendCommand(ControllerCommand.WRITE_CONFIG)) return false;
        // if (!driver.sendData(new_config)) return false;

        // // Enable PS/2 port 1
        // if (!driver.sendCommand(ControllerCommand.ENABLE_PORT1)) return false;

        return driver;
    }

    /// Read the status register
    pub fn readStatus(self: *Ps2Driver) void {
        var status: StatusRegister = undefined;
        // Read the status register
        while (!(status.outputBuffer)) {
            status = @bitCast(arch.inb(self.status_port));
        }
        self.status = status;
    }

    /// Write a controller command
    pub fn writeCommand(self: *Ps2Driver, cmd: u8) void {
        while (!(self.status.inputBuffer)) {
            self.readStatus();
        }
        arch.outb(self.command_port, cmd);
    }

    /// Send data to the PS/2 controller
    pub fn sendData(self: *Ps2Driver, data: u8) bool {
        if (!self.waitWrite()) return false;
        arch.outb(self.data_port, data);
        return true;
    }

    /// Read data from the PS/2 controller
    pub fn readData(self: *Ps2Driver) ?u8 {
        if (!self.waitRead()) return null;
        return arch.inb(self.data_port);
    }

    /// Flush the output buffer
    pub fn flushOutputBuffer(self: *Ps2Driver) void {
        _ = self.readData();
    }
};
