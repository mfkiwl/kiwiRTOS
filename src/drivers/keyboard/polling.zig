//! This file provides a polling-based keyboard driver based on the Intel 8042 PS/2 controller.

const arch = @import("../../arch/arch.zig");
const ps2 = @import("../ps2.zig");
const std = @import("std");
const vga = @import("../vga.zig");
const sc = @import("./scancode.zig");

/// PS/2 keyboard implemented commands
pub const KeyboardCommand = enum(u8) {
    KB_CMD_SET_LEDS = 0xED,
    KB_CMD_SET_SCANCODE = 0xF0,
    KB_CMD_RESET = 0xFF,
    KB_CMD_ENABLE = 0xF4,
};

/// PS/2 keyboard responses
pub const KeyboardResponse = enum(u8) {
    ACK = 0xFA,
    RESEND = 0xFE,
    SELF_TEST_PASS = 0xAA,
};

/// PS/2 keyboard LED command parameters
pub const KeyboardLED = packed struct {
    scroll_lock: u1,
    num_lock: u1,
    caps_lock: u1,
};

/// Keyboard driver
pub const KeyboardDriver = struct {
    /// The PS/2 driver
    ps2: *ps2.Ps2Driver,
    /// The VGA driver
    console: *vga.VgaTextDriver,
    /// The scancode set
    scancode_set: sc.ScanCodeSets,
    /// The LED state
    led_state: KeyboardLED,
    /// Whether the extended code is active
    extended_code: bool = false,
    /// Whether the release code is active
    release_code: bool = false,
    /// Whether the shift key is pressed
    shift_pressed: bool = false,
    /// Whether the control key is pressed
    ctrl_pressed: bool = false,
    /// Whether the alt key is pressed
    alt_pressed: bool = false,
    /// Whether the caps lock is active
    caps_lock_active: bool = false,

    /// Initialize a keyboard driver
    pub fn init(ps2_driver: *ps2.Ps2Driver, vga_driver: *vga.VgaTextDriver) ?KeyboardDriver {
        var driver = KeyboardDriver{
            .ps2 = ps2_driver,
            .console = vga_driver,
            .scancode_set = sc.ScanCodeSets.SCANCODE_SET_2,
            .led_state = KeyboardLED{
                .scroll_lock = 0,
                .num_lock = 0,
                .caps_lock = 0,
            },
            .extended_code = false,
            .release_code = false,
            .shift_pressed = false,
            .ctrl_pressed = false,
            .alt_pressed = false,
            .caps_lock_active = false,
        };

        // Reset the keyboard
        if (!driver.sendCommand(KeyboardCommand.KB_CMD_RESET)) {
            driver.console.println("Keyboard reset failed", .{});
            return null;
        }

        // Wait for self-test response
        if (@as(KeyboardResponse, @enumFromInt(driver.ps2.readData())) != KeyboardResponse.SELF_TEST_PASS) {
            driver.console.println("Keyboard self-test failed", .{});
            return null;
        }

        // Set scan code set 2 (most common)
        if (!driver.sendCommandWithParam(KeyboardCommand.KB_CMD_SET_SCANCODE, @intFromEnum(sc.ScanCodeSets.SCANCODE_SET_2))) {
            // if (!driver.sendCommandWithParam(KeyboardCommand.KB_CMD_SET_SCANCODE, @intFromEnum(sc.ScanCodeSet.set2))) {
            driver.console.println("Setting scan code set failed", .{});
            return null;
        }

        // Enable keyboard
        if (!driver.sendCommand(KeyboardCommand.KB_CMD_ENABLE)) {
            driver.console.println("Enabling keyboard failed", .{});
            return null;
        }

        return driver;
    }

    /// Send a command to the keyboard
    pub fn sendCommand(self: *KeyboardDriver, cmd: KeyboardCommand) bool {
        // TODO: Handle RESEND
        var response: KeyboardResponse = undefined;
        while (response != KeyboardResponse.ACK) {
            self.ps2.writeData(@intFromEnum(cmd));
            response = @enumFromInt(self.ps2.readData());
        }
        return response == KeyboardResponse.ACK;
    }

    /// Send a command with a parameter to the keyboard
    fn sendCommandWithParam(self: *KeyboardDriver, cmd: KeyboardCommand, param: u8) bool {
        var response: KeyboardResponse = undefined;
        while (true) {
            self.ps2.writeData(@intFromEnum(cmd));
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
    pub fn getChar(self: *KeyboardDriver) u8 {
        while (true) {
            const code = self.readScanCode();
            // Skip release codes (0xF0 prefix in scan code set 2)
            if (code == 0xF0) {
                _ = self.readScanCode(); // Consume the next byte (the actual key that was released)
                continue;
            } else {
                return self.mapScanCodeToAscii(code);
            }
        }
    }

    // Simple scancode set 2 to ASCII mapping for common keys
    // This is a simplified mapping for common keys only
    pub fn mapScanCodeToAscii(self: *KeyboardDriver, scan_code: u8) u8 {
        _ = self; // Avoid unused parameter warning
        return scan_code;
        // const ascii_table = [_]?u8{
        //     // 0x00-0x0F
        //     null, null, null, null, null, null, null, null, null, null, null, null, null, '\t', '`',  null,
        //     // 0x10-0x1F
        //     null, null, null, null, null, 'q',  '1',  null, null, null, 'z',  's',  'a',  'w',  '2',  null,
        //     // 0x20-0x2F
        //     null, 'c',  'x',  'd',  'e',  '4',  '3',  null, null, ' ',  'v',  'f',  't',  'r',  '5',  null,
        //     // 0x30-0x3F
        //     null, 'n',  'b',  'h',  'g',  'y',  '6',  null, null, null, 'm',  'j',  'u',  '7',  '8',  null,
        //     // 0x40-0x4F
        //     null, ',',  'k',  'i',  'o',  '0',  '9',  null, null, '.',  '/',  'l',  ';',  'p',  '-',  null,
        //     // 0x50-0x5F
        //     null, null, '\'', null, '[',  '=',  null, null, null, null, '\n', ']',  null, '\\', null, null,
        // };

        // if (scan_code < ascii_table.len) {
        //     return ascii_table[scan_code];
        // }

        // return null;
    }
};
