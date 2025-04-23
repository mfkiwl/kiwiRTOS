//! This file provides a polling-based keyboard driver based on the Intel 8042 PS/2 controller.

const arch = @import("../../arch/arch.zig");
const ps2 = @import("../ps2.zig");
const std = @import("std");
const vga = @import("../vga.zig");
const sc = @import("./scancode.zig");

/// Writer type for std library integration
const Writer = std.io.Writer;

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

pub const KeyboardChar = struct {
    byte: u8,
    char: ?u8,
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
    scancode_set: sc.ScanCodeSet,
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

    /// Buffer for multi-byte scancodes
    scancode_buffer: u16 = 0,
    /// Buffer index
    buffer_index: u8 = 0,

    /// Initialize a keyboard driver
    pub fn init(ps2_driver: *ps2.Ps2Driver, vga_driver: *vga.VgaTextDriver) ?KeyboardDriver {
        var driver = KeyboardDriver{
            .ps2 = ps2_driver,
            .console = vga_driver,
            .scancode_set = sc.ScanCodeSet1,
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
            .scancode_buffer = 0,
            .buffer_index = 0,
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

    /// Set the scancode set
    pub fn setScanCodeSet(self: *KeyboardDriver, scancode_set: sc.ScanCodeSets) void {
        self.scancode_set = scancode_set.getScanCodeSet();
    }

    /// Reset the temporary state variables
    pub fn resetBuffer(self: *KeyboardDriver) void {
        self.extended_code = false;
        self.release_code = false;
        self.scancode_buffer = 0;
        self.buffer_index = 0;
    }

    /// Send a command to the keyboard
    pub fn sendCommand(self: *KeyboardDriver, cmd: KeyboardCommand) bool {
        const maxRetries = 3;
        var retries: usize = 0;
        while (retries < maxRetries) : (retries += 1) {
            var response: KeyboardResponse = KeyboardResponse.RESEND;
            while (response == KeyboardResponse.RESEND) {
                self.ps2.writeData(@intFromEnum(cmd));
                response = @enumFromInt(self.ps2.readData());
                if (response == KeyboardResponse.ACK) return true;
            }
        }
        return false;
    }

    /// Send a command with a parameter to the keyboard
    fn sendCommandWithParam(self: *KeyboardDriver, cmd: KeyboardCommand, param: u8) bool {
        const maxRetries = 3;
        var retries: usize = 0;
        while (retries < maxRetries) : (retries += 1) {
            var response: KeyboardResponse = KeyboardResponse.RESEND;
            while (response == KeyboardResponse.RESEND) {
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
        }
        return false;
    }

    /// Read a key from the keyboard (returns raw scan code)
    pub fn readScanCode(self: *KeyboardDriver) u8 {
        return self.ps2.readData();
    }

    /// Poll the keyboard until a key is pressed and return its ASCII value
    pub fn getChar(self: *KeyboardDriver) KeyboardChar {
        const byte: u8 = self.readScanCode();
        return KeyboardChar{ .byte = byte, .char = self.processByte(byte) };
    }

    /// Processes a single scancode byte
    pub fn processByte(self: *KeyboardDriver, byte: u8) ?u8 {
        // Handle special codes
        if (byte == self.scancode_set.extended) {
            self.extended_code = true;
            self.scancode_buffer = byte;
            self.buffer_index = 1;
            // self.console.println("Extended code", .{});
            return null;
        }
        // Skip release codes
        if (byte == self.scancode_set.release) {
            self.release_code = true;
            // self.console.println("Release code", .{});
            // If we're in extended mode, update the buffer
            if (self.extended_code) {
                self.scancode_buffer = (self.scancode_buffer << 8) | byte;
                self.buffer_index += 1;
            }
            return null;
        }

        var scancode: u16 = byte;

        // Combine with extended prefix if needed
        if (self.extended_code) {
            // self.console.println("Extended code", .{});
            scancode = (self.scancode_buffer << 8) | byte;
            self.buffer_index += 1;
        }

        // Handle key release events
        if (self.release_code) {
            // self.console.println("Release code", .{});
            // Update modifier state
            if (scancode == self.scancode_set.left_shift or scancode == self.scancode_set.right_shift) {
                self.shift_pressed = false;
            } else if (scancode == self.scancode_set.left_ctrl or scancode == self.scancode_set.right_ctrl) {
                self.ctrl_pressed = false;
            } else if (scancode == self.scancode_set.left_alt or scancode == self.scancode_set.right_alt) {
                self.alt_pressed = false;
            }

            // Reset state for next scancode
            self.release_code = false;
            self.extended_code = false;
            self.scancode_buffer = 0;
            self.buffer_index = 0;

            return null;
        }

        // Handle key press events
        // Update modifier state - using if statements instead of switch
        if (scancode == self.scancode_set.left_shift or scancode == self.scancode_set.right_shift) {
            self.shift_pressed = true;
            self.resetBuffer();
            return null;
        } else if (scancode == self.scancode_set.left_ctrl or scancode == self.scancode_set.right_ctrl) {
            self.ctrl_pressed = true;
            self.resetBuffer();
            return null;
        } else if (scancode == self.scancode_set.left_alt or scancode == self.scancode_set.right_alt) {
            self.alt_pressed = true;
            self.resetBuffer();
            return null;
        } else if (scancode == self.scancode_set.caps_lock) {
            self.caps_lock_active = !self.caps_lock_active;
            self.resetBuffer();
            return null;
        }

        // Get the character based on the full scancode
        const result = self.getCharFromScancode(scancode);

        // Reset state for next scancode
        self.resetBuffer();

        return result;
    }

    /// Convert scancode to hex string for lookup
    fn scancodeToHexString(_: *KeyboardDriver, scancode: u16) ![5]u8 {
        var buf: [5]u8 = undefined;

        // write the rest of the buffer as 0
        for (&buf) |*c| {
            c.* = 0;
        }

        if (scancode <= 0xFF) {
            // Single byte scancode
            _ = try std.fmt.bufPrint(&buf, "{X:0>2}", .{scancode});
            return buf;
        } else {
            // Extended scancode (E0 + byte)
            _ = try std.fmt.bufPrint(&buf, "{X:0>4}", .{scancode});
            return buf;
        }
        return buf;
    }

    /// Get the character value from a scancode
    fn getCharFromScancode(self: *KeyboardDriver, scancode: u16) ?u8 {
        // Convert scancode to string for map lookup
        var scancode_str: [5]u8 = undefined;
        scancode_str = self.scancodeToHexString(scancode) catch return null;

        // Create a slice of the string up to the first null byte
        var len: usize = 0;
        while (len < scancode_str.len and scancode_str[len] != 0) {
            len += 1;
        }
        const key_str = scancode_str[0..len];

        // self.console.println("Scancode: {s}", .{key_str});

        // Use the appropriate lookup table based on scancode type
        const key_map_opt = self.scancode_set.set.get(key_str);
        // self.console.println("Key map: {any}", .{key_map_opt});

        if (key_map_opt) |key_map| {
            // Determine if we should use shifted value
            // XOR with caps lock for letters
            return if ((self.shift_pressed or self.caps_lock_active) and (self.shift_pressed != self.caps_lock_active)) key_map.shifted else key_map.base;
        }
        return null;
    }

    // Simple scancode set 2 to ASCII mapping for common keys
    // This is a simplified mapping for common keys only
    pub fn mapScanCodeToAscii(self: *KeyboardDriver, scan_code: u8) u8 {
        _ = self; // Avoid unused parameter warning
        return scan_code;
    }

    /// Writer for the VGA text mode driver
    pub fn writer(self: *KeyboardDriver) Writer(*KeyboardDriver, error{}, writerFn) {
        return .{ .context = self };
    }

    /// Writer function for std.io.Writer interface
    pub fn writerFn(self: *KeyboardDriver, bytes: []const u8) error{}!usize {
        self.putStr(bytes);
        return bytes.len;
    }
};
