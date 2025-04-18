//! This file provides a polling-based keyboard driver based on the Intel 8042 PS/2 controller.

const arch = @import("../../arch/arch.zig");
const ps2 = @import("../ps2.zig");
const std = @import("std");

/// PS/2 keyboard commands
pub const KeyboardCommand = enum(u8) {
    pub const KB_CMD_RESET: u8 = 0xFF;
    pub const KB_CMD_SET_SCANCODE: u8 = 0xF0;
    pub const KB_CMD_ENABLE: u8 = 0xF4;
    pub const KB_CMD_SET_LEDS: u8 = 0xED;
};

/// PS/2 keyboard responses
pub const KeyboardResponse = enum(u8) {
    pub const ACK: u8 = 0xFA;
    pub const RESEND: u8 = 0xFE;
    pub const SELF_TEST_PASS: u8 = 0xAA;
};

/// PS/2 keyboard scancode set
pub const KeyboardScancodeSet = enum(u8) {
    /// Scancode set 1 (default)
    pub const SCANCODE_SET_1: u8 = 0x01;
    /// Scancode set 2 (most common)
    pub const SCANCODE_SET_2: u8 = 0x02;
    /// Scancode set 3 (rare)
    pub const SCANCODE_SET_3: u8 = 0x03;
};

pub const ScanCodeSet = union(enum) {
    set1: void,
    set2: void,
    set3: void,
};

/// Keyboard driver
pub const KeyboardDriver = struct {
    ps2: *ps2.Ps2Driver,

    /// Initialize a keyboard driver
    pub fn init(ps2_driver: *ps2.Ps2Driver) ?KeyboardDriver {
        var driver: KeyboardDriver = undefined;
        driver = KeyboardDriver{
            .ps2 = ps2_driver,
        };

        // Reset the keyboard
        if (!driver.sendCommand(KeyboardCommand.KB_CMD_RESET)) {
            // printk("Keyboard reset failed\n");
            return null;
        }

        // Wait for self-test response
        if (driver.ps2.readData() != KeyboardResponse.SELF_TEST_PASS) {
            // printk("Keyboard self-test failed\n");
            return null;
        }

        // Set scan code set 2 (most common)
        if (!driver.sendCommandWithParam(KeyboardCommand.KB_CMD_SET_SCANCODE, KeyboardScancodeSet.SCANCODE_SET_2)) {
            // printk("Setting scan code set failed\n");
            return null;
        }

        // Enable keyboard
        if (!driver.sendCommand(KeyboardCommand.KB_CMD_ENABLE)) {
            // printk("Enabling keyboard failed\n");
            return null;
        }
        return driver;
    }

    /// Send a command to the keyboard
    pub fn sendCommand(self: *KeyboardDriver, cmd: KeyboardCommand) bool {
        // TODO: Handle RESEND
        var response: KeyboardResponse = undefined;
        while (response != KeyboardResponse.ACK) {
            self.ps2.writeCommand(cmd);
            response = @enumFromInt(self.ps2.readData());
        }
        return response == KeyboardResponse.ACK;
    }

    /// Send a command with a parameter to the keyboard
    fn sendCommandWithParam(self: *KeyboardDriver, cmd: KeyboardCommand, param: u8) bool {
        var response: KeyboardResponse = undefined;
        while (true) {
            self.ps2.writeCommand(cmd);
            response = @enumFromInt(self.ps2.readData());
            if (response == KeyboardResponse.ACK) {
                self.ps2.writeData(param);
                response = @enumFromInt(self.ps2.readData());
                if (response == KeyboardResponse.ACK) {
                    return true;
                }
            }
        }
        return response == KeyboardResponse.ACK;
    }

    /// Read a key from the keyboard (returns raw scan code)
    pub fn readScanCode(self: *KeyboardDriver) u8 {
        return self.ps2.readData();
    }

    /// Poll the keyboard until a key is pressed and return its ASCII value
    pub fn readKey(self: *KeyboardDriver) u8 {
        while (true) {
            if (self.readScanCode()) |code| {
                // Skip release codes (0xF0 prefix in scan code set 2)
                if (code == 0xF0) {
                    _ = self.readScanCode(); // Consume the next byte (the actual key that was released)
                    continue;
                }

                return self.mapScanCodeToAscii(code);
            }
        }
    }

    // Simple scancode set 2 to ASCII mapping for common keys
    // This is a simplified mapping for common keys only
    fn mapScanCodeToAscii(scan_code: u8) ?u8 {
        const ascii_table = [_]?u8{
            // 0x00-0x0F
            null, null, null, null, null, null, null, null, null, null, null, null, null, '\t', '`',  null,
            // 0x10-0x1F
            null, null, null, null, null, 'q',  '1',  null, null, null, 'z',  's',  'a',  'w',  '2',  null,
            // 0x20-0x2F
            null, 'c',  'x',  'd',  'e',  '4',  '3',  null, null, ' ',  'v',  'f',  't',  'r',  '5',  null,
            // 0x30-0x3F
            null, 'n',  'b',  'h',  'g',  'y',  '6',  null, null, null, 'm',  'j',  'u',  '7',  '8',  null,
            // 0x40-0x4F
            null, ',',  'k',  'i',  'o',  '0',  '9',  null, null, '.',  '/',  'l',  ';',  'p',  '-',  null,
            // 0x50-0x5F
            null, null, '\'', null, '[',  '=',  null, null, null, null, '\n', ']',  null, '\\', null, null,
        };

        if (scan_code < ascii_table.len) {
            return ascii_table[scan_code];
        }

        return null;
    }
};
