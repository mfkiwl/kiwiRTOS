//! This file provides various scancode lookup tables for the keyboard driver.

const std = @import("std");

/// Represents a mapping for a single key
const KeyMap = struct {
    /// The unshifted ASCII character
    base: u8,
    /// The shifted ASCII character
    shifted: u8,
};

/// Represents a scancode set
pub const ScanCodeSet = struct {
    set: std.StaticStringMap(KeyMap),

    /// Converts a scancode to its corresponding character
    pub fn getChar(self: ScanCodeSet, scancode: []const u8, shifted: bool) ?u8 {
        if (self.set.get(scancode)) |keymap| {
            return if (shifted) keymap.shifted else keymap.base;
        } else {
            return null;
        }
    }
};

/// Scancode set 1 (default)
pub const ScanCodeSet1: ScanCodeSet = .{
    .set = std.StaticStringMap(KeyMap).initComptime(.{
        .{ "02", KeyMap{ .base = '1', .shifted = '!' } },
    }),
};

/// Scancode set 2 (most common)
pub const ScanCodeSet2: ScanCodeSet = .{
    .set = std.StaticStringMap(KeyMap).initComptime(.{
        .{ "02", KeyMap{ .base = '1', .shifted = '!' } },
    }),
};

/// Scancode set 3 (rare)
pub const ScanCodeSet3: ScanCodeSet = .{
    .set = std.StaticStringMap(KeyMap).initComptime(.{
        .{ "02", KeyMap{ .base = '1', .shifted = '!' } },
    }),
};

/// Represents the set of supported scancodes
pub const ScanCodeSets = enum(u8) {
    /// Scancode set 1 (default)
    SCANCODE_SET_1 = 0x01,
    /// Scancode set 2 (most common)
    SCANCODE_SET_2 = 0x02,
    /// Scancode set 3 (rare)
    SCANCODE_SET_3 = 0x03,

    pub fn getScanCodeSet(self: ScanCodeSets) ScanCodeSet {
        return switch (self) {
            .SCANCODE_SET_1 => ScanCodeSet1,
            .SCANCODE_SET_2 => ScanCodeSet2,
            .SCANCODE_SET_3 => ScanCodeSet3,
        };
    }
};

/// Extended code lookup table that maps 16-bit scancodes (including extended keys)
/// to their corresponding KeyMap values.
///
/// This uses u16 to represent both regular codes and extended codes:
/// - Normal scancodes: 0x00-0xFF
/// - Extended scancodes: 0xE0XX (where XX is the second byte)
pub const EXTENDED_SCAN_CODE_MAP = std.StaticStringMap(KeyMap).initComptime(.{
    // Regular keys (single-byte scancodes)
    .{ "02", KeyMap{ .base = '1', .shifted = '!' } },
    .{ "03", KeyMap{ .base = '2', .shifted = '@' } },
    .{ "04", KeyMap{ .base = '3', .shifted = '#' } },
    .{ "05", KeyMap{ .base = '4', .shifted = '$' } },
    .{ "06", KeyMap{ .base = '5', .shifted = '%' } },
    .{ "07", KeyMap{ .base = '6', .shifted = '^' } },
    .{ "08", KeyMap{ .base = '7', .shifted = '&' } },
    .{ "09", KeyMap{ .base = '8', .shifted = '*' } },
    .{ "0A", KeyMap{ .base = '9', .shifted = '(' } },
    .{ "0B", KeyMap{ .base = '0', .shifted = ')' } },
    .{ "0C", KeyMap{ .base = '-', .shifted = '_' } },
    .{ "0D", KeyMap{ .base = '=', .shifted = '+' } },
    .{ "0E", KeyMap{ .base = '\x08', .shifted = '\x08' } }, // Backspace
    .{ "0F", KeyMap{ .base = '\t', .shifted = '\t' } }, // Tab

    .{ "10", KeyMap{ .base = 'q', .shifted = 'Q' } },
    .{ "11", KeyMap{ .base = 'w', .shifted = 'W' } },
    .{ "12", KeyMap{ .base = 'e', .shifted = 'E' } },
    .{ "13", KeyMap{ .base = 'r', .shifted = 'R' } },
    .{ "14", KeyMap{ .base = 't', .shifted = 'T' } },
    .{ "15", KeyMap{ .base = 'y', .shifted = 'Y' } },
    .{ "16", KeyMap{ .base = 'u', .shifted = 'U' } },
    .{ "17", KeyMap{ .base = 'i', .shifted = 'I' } },
    .{ "18", KeyMap{ .base = 'o', .shifted = 'O' } },
    .{ "19", KeyMap{ .base = 'p', .shifted = 'P' } },
    .{ "1A", KeyMap{ .base = '[', .shifted = '{' } },
    .{ "1B", KeyMap{ .base = ']', .shifted = '}' } },
    .{ "1C", KeyMap{ .base = '\n', .shifted = '\n' } }, // Enter
    .{ "1E", KeyMap{ .base = 'a', .shifted = 'A' } },
    .{ "1F", KeyMap{ .base = 's', .shifted = 'S' } },

    .{ "20", KeyMap{ .base = 'd', .shifted = 'D' } },
    .{ "21", KeyMap{ .base = 'f', .shifted = 'F' } },
    .{ "22", KeyMap{ .base = 'g', .shifted = 'G' } },
    .{ "23", KeyMap{ .base = 'h', .shifted = 'H' } },
    .{ "24", KeyMap{ .base = 'j', .shifted = 'J' } },
    .{ "25", KeyMap{ .base = 'k', .shifted = 'K' } },
    .{ "26", KeyMap{ .base = 'l', .shifted = 'L' } },
    .{ "27", KeyMap{ .base = ';', .shifted = ':' } },
    .{ "28", KeyMap{ .base = '\'', .shifted = '"' } },
    .{ "29", KeyMap{ .base = '`', .shifted = '~' } },
    .{ "2B", KeyMap{ .base = '\\', .shifted = '|' } },
    .{ "2C", KeyMap{ .base = 'z', .shifted = 'Z' } },
    .{ "2D", KeyMap{ .base = 'x', .shifted = 'X' } },
    .{ "2E", KeyMap{ .base = 'c', .shifted = 'C' } },
    .{ "2F", KeyMap{ .base = 'v', .shifted = 'V' } },

    .{ "30", KeyMap{ .base = 'b', .shifted = 'B' } },
    .{ "31", KeyMap{ .base = 'n', .shifted = 'N' } },
    .{ "32", KeyMap{ .base = 'm', .shifted = 'M' } },
    .{ "33", KeyMap{ .base = ',', .shifted = '<' } },
    .{ "34", KeyMap{ .base = '.', .shifted = '>' } },
    .{ "35", KeyMap{ .base = '/', .shifted = '?' } },
    .{ "37", KeyMap{ .base = '*', .shifted = '*' } }, // Keypad *
    .{ "39", KeyMap{ .base = ' ', .shifted = ' ' } }, // Space
    .{ "47", KeyMap{ .base = '7', .shifted = '7' } }, // Keypad 7
    .{ "48", KeyMap{ .base = '8', .shifted = '8' } }, // Keypad 8
    .{ "49", KeyMap{ .base = '9', .shifted = '9' } }, // Keypad 9
    .{ "4A", KeyMap{ .base = '-', .shifted = '-' } }, // Keypad -
    .{ "4B", KeyMap{ .base = '4', .shifted = '4' } }, // Keypad 4
    .{ "4C", KeyMap{ .base = '5', .shifted = '5' } }, // Keypad 5
    .{ "4D", KeyMap{ .base = '6', .shifted = '6' } }, // Keypad 6
    .{ "4E", KeyMap{ .base = '+', .shifted = '+' } }, // Keypad +
    .{ "4F", KeyMap{ .base = '1', .shifted = '1' } }, // Keypad 1
    .{ "50", KeyMap{ .base = '2', .shifted = '2' } }, // Keypad 2
    .{ "51", KeyMap{ .base = '3', .shifted = '3' } }, // Keypad 3
    .{ "52", KeyMap{ .base = '0', .shifted = '0' } }, // Keypad 0
    .{ "53", KeyMap{ .base = '.', .shifted = '.' } }, // Keypad .

    // Extended keys (E0 prefixed scancodes)
    .{ "E01C", KeyMap{ .base = '\n', .shifted = '\n' } }, // Keypad Enter
    .{ "E035", KeyMap{ .base = '/', .shifted = '/' } }, // Keypad /
    .{ "E047", KeyMap{ .base = 0x1B, .shifted = 0x1B } }, // Home (using ESC as code)
    .{ "E048", KeyMap{ .base = 0x18, .shifted = 0x18 } }, // Up Arrow (custom code)
    .{ "E049", KeyMap{ .base = 0x19, .shifted = 0x19 } }, // Page Up (custom code)
    .{ "E04B", KeyMap{ .base = 0x1A, .shifted = 0x1A } }, // Left Arrow (custom code)
    .{ "E04D", KeyMap{ .base = 0x1C, .shifted = 0x1C } }, // Right Arrow (custom code)
    .{ "E04F", KeyMap{ .base = 0x1D, .shifted = 0x1D } }, // End (custom code)
    .{ "E050", KeyMap{ .base = 0x1E, .shifted = 0x1E } }, // Down Arrow (custom code)
    .{ "E051", KeyMap{ .base = 0x1F, .shifted = 0x1F } }, // Page Down (custom code)
    .{ "E052", KeyMap{ .base = 0x15, .shifted = 0x15 } }, // Insert (custom code)
    .{ "E053", KeyMap{ .base = 0x7F, .shifted = 0x7F } }, // Delete (DEL character)
});

/// Standard PS/2 keyboard scancodes (Set 1)
pub const ScanCode = struct {
    // Special codes
    pub const EXTENDED = 0xE0;
    pub const RELEASE = 0xF0;

    // Modifiers
    pub const LEFT_SHIFT = 0x2A;
    pub const RIGHT_SHIFT = 0x36;
    pub const LEFT_CTRL = 0x1D;
    pub const RIGHT_CTRL = 0xE01D; // Extended code
    pub const LEFT_ALT = 0x38;
    pub const RIGHT_ALT = 0xE038; // Extended code
    pub const CAPS_LOCK = 0x3A;
};

/// Keyboard state tracker
pub const KeyboardState = struct {
    extended_code: bool = false,
    release_code: bool = false,

    shift_pressed: bool = false,
    ctrl_pressed: bool = false,
    alt_pressed: bool = false,
    caps_lock_active: bool = false,

    // Buffer for multi-byte scancodes
    scancode_buffer: u16 = 0,
    buffer_index: u8 = 0,

    /// Processes a single scancode byte
    pub fn processByte(self: *KeyboardState, byte: u8) ?u8 {
        // Handle special codes
        if (byte == ScanCode.EXTENDED) {
            self.extended_code = true;
            self.scancode_buffer = byte;
            self.buffer_index = 1;
            return null;
        }

        if (byte == ScanCode.RELEASE) {
            self.release_code = true;

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
            scancode = (self.scancode_buffer << 8) | byte;
            self.buffer_index += 1;
        }

        // Handle key release events
        if (self.release_code) {
            // Update modifier state
            switch (scancode) {
                ScanCode.LEFT_SHIFT, ScanCode.RIGHT_SHIFT => self.shift_pressed = false,
                ScanCode.LEFT_CTRL => self.ctrl_pressed = false,
                ScanCode.RIGHT_CTRL => self.ctrl_pressed = false,
                ScanCode.LEFT_ALT => self.alt_pressed = false,
                ScanCode.RIGHT_ALT => self.alt_pressed = false,
                else => {},
            }

            // Reset state for next scancode
            self.release_code = false;
            self.extended_code = false;
            self.scancode_buffer = 0;
            self.buffer_index = 0;

            return null;
        }

        // Handle key press events
        // Update modifier state
        switch (scancode) {
            ScanCode.LEFT_SHIFT, ScanCode.RIGHT_SHIFT => {
                self.shift_pressed = true;
                self.reset();
                return null;
            },
            ScanCode.LEFT_CTRL, ScanCode.RIGHT_CTRL => {
                self.ctrl_pressed = true;
                self.reset();
                return null;
            },
            ScanCode.LEFT_ALT, ScanCode.RIGHT_ALT => {
                self.alt_pressed = true;
                self.reset();
                return null;
            },
            ScanCode.CAPS_LOCK => {
                self.caps_lock_active = !self.caps_lock_active;
                self.reset();
                return null;
            },
            else => {},
        }

        // Get the character based on the full scancode
        const result = self.getCharFromScancode(scancode);

        // Reset state for next scancode
        self.reset();

        return result;
    }

    /// Convert scancode to hex string for lookup
    fn scancodeToHexString(scancode: u16) ![5]u8 {
        var buf: [5]u8 = undefined;

        if (scancode <= 0xFF) {
            // Single byte scancode
            _ = try std.fmt.bufPrint(&buf, "{X:0>2}", .{scancode});
            return buf;
        } else {
            // Extended scancode (E0 + byte)
            _ = try std.fmt.bufPrint(&buf, "{X:0>4}", .{scancode});
            return buf;
        }
    }

    /// Get the character value from a scancode
    fn getCharFromScancode(self: *KeyboardState, scancode: u16) ?u8 {
        // Convert scancode to string for map lookup
        var scancode_str: [5]u8 = undefined;
        scancode_str = scancodeToHexString(scancode) catch return null;

        // Use the appropriate lookup table based on scancode type
        const key_map_opt = EXTENDED_SCAN_CODE_MAP.get(&scancode_str);
        if (key_map_opt) |key_map| {
            // Determine if we should use shifted value
            // XOR with caps lock for letters
            const use_shift = blk: {
                if (self.shift_pressed != self.caps_lock_active) {
                    // For letters, shift is toggled by caps lock
                    const char = if (self.shift_pressed) key_map.shifted else key_map.base;
                    if ((char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z')) {
                        break :blk true;
                    }
                }
                break :blk self.shift_pressed;
            };

            return if (use_shift) key_map.shifted else key_map.base;
        }

        return null;
    }

    /// Reset the temporary state variables
    fn reset(self: *KeyboardState) void {
        self.extended_code = false;
        self.release_code = false;
        self.scancode_buffer = 0;
        self.buffer_index = 0;
    }
};

/// Example usage function
pub fn main() !void {
    // Example scancode sequence for typing "Hi!"
    // 0x23 (H key press), 0xF0, 0x23 (H key release)
    // 0x17 (i key press), 0xF0, 0x17 (i key release)
    // 0x2A (Left Shift press), 0x02 (1 key press) -> "!"
    // 0xF0, 0x02 (1 key release), 0xF0, 0x2A (Left Shift release)
    const scancode_sequence = [_]u8{ 0x23, 0xF0, 0x23, 0x17, 0xF0, 0x17, 0x2A, 0x02, 0xF0, 0x02, 0xF0, 0x2A };

    var kb_state = KeyboardState{};
    var output = std.ArrayList(u8).init(std.heap.page_allocator);
    defer output.deinit();

    std.debug.print("Processing scancode sequence...\n", .{});

    for (scancode_sequence) |byte| {
        if (kb_state.processByte(byte)) |char| {
            try output.append(char);
            std.debug.print("Processed byte: 0x{X:0>2}, Output char: '{c}'\n", .{ byte, char });
        } else {
            std.debug.print("Processed byte: 0x{X:0>2}, No output\n", .{byte});
        }
    }

    std.debug.print("Final output: {s}\n", .{output.items});
}

/// Process a sequence of scancodes
pub fn processScancodeSequence(scancodes: []const u8) ![]u8 {
    var kb_state = KeyboardState{};
    var output = std.ArrayList(u8).init(std.heap.page_allocator);

    for (scancodes) |byte| {
        if (kb_state.processByte(byte)) |char| {
            try output.append(char);
        }
    }

    return output.toOwnedSlice();
}

/// A lookup table for scancode to ASCII character mappings
pub const scan2ascii: [256]KeyMap = blk: {
    var m: [256]KeyMap = undefined;
    // default to no mapping
    for (m) |*entry| entry.* = KeyMap{ .base = 0, .shifted = 0 };

    // letters
    m[0x1C] = KeyMap{ .base = 'a', .shifted = 'A' };
    m[0x32] = KeyMap{ .base = 'b', .shifted = 'B' };
    m[0x21] = KeyMap{ .base = 'c', .shifted = 'C' };
    m[0x23] = KeyMap{ .base = 'd', .shifted = 'D' };
    m[0x24] = KeyMap{ .base = 'e', .shifted = 'E' };
    m[0x2B] = KeyMap{ .base = 'f', .shifted = 'F' };
    m[0x34] = KeyMap{ .base = 'g', .shifted = 'G' };
    m[0x33] = KeyMap{ .base = 'h', .shifted = 'H' };
    m[0x43] = KeyMap{ .base = 'i', .shifted = 'I' };
    m[0x3B] = KeyMap{ .base = 'j', .shifted = 'J' };
    m[0x42] = KeyMap{ .base = 'k', .shifted = 'K' };
    m[0x4B] = KeyMap{ .base = 'l', .shifted = 'L' };
    m[0x3A] = KeyMap{ .base = 'm', .shifted = 'M' };
    m[0x31] = KeyMap{ .base = 'n', .shifted = 'N' };
    m[0x44] = KeyMap{ .base = 'o', .shifted = 'O' };
    m[0x4D] = KeyMap{ .base = 'p', .shifted = 'P' };
    m[0x15] = KeyMap{ .base = 'q', .shifted = 'Q' };
    m[0x2D] = KeyMap{ .base = 'r', .shifted = 'R' };
    m[0x1B] = KeyMap{ .base = 's', .shifted = 'S' };
    m[0x2C] = KeyMap{ .base = 't', .shifted = 'T' };
    m[0x3C] = KeyMap{ .base = 'u', .shifted = 'U' };
    m[0x2A] = KeyMap{ .base = 'v', .shifted = 'V' };
    m[0x1D] = KeyMap{ .base = 'w', .shifted = 'W' };
    m[0x22] = KeyMap{ .base = 'x', .shifted = 'X' };
    m[0x35] = KeyMap{ .base = 'y', .shifted = 'Y' };
    m[0x1A] = KeyMap{ .base = 'z', .shifted = 'Z' };

    // digits
    m[0x16] = KeyMap{ .base = '1', .shifted = '!' };
    m[0x1E] = KeyMap{ .base = '2', .shifted = '@' };
    m[0x26] = KeyMap{ .base = '3', .shifted = '#' };
    m[0x25] = KeyMap{ .base = '4', .shifted = '$' };
    m[0x2E] = KeyMap{ .base = '5', .shifted = '%' };
    m[0x36] = KeyMap{ .base = '6', .shifted = '^' };
    m[0x3D] = KeyMap{ .base = '7', .shifted = '&' };
    m[0x3E] = KeyMap{ .base = '8', .shifted = '*' };
    m[0x46] = KeyMap{ .base = '9', .shifted = '(' };
    m[0x45] = KeyMap{ .base = '0', .shifted = ')' };

    // space, punctuation...
    m[0x29] = KeyMap{ .base = ' ', .shifted = ' ' };
    m[0x0E] = KeyMap{ .base = '`', .shifted = '~' };
    m[0x4E] = KeyMap{ .base = '-', .shifted = '_' };
    m[0x55] = KeyMap{ .base = '=', .shifted = '+' };
    m[0x5D] = KeyMap{ .base = '\\', .shifted = '|' };
    m[0x54] = KeyMap{ .base = '[', .shifted = '{' };
    m[0x5B] = KeyMap{ .base = ']', .shifted = '}' };
    m[0x4C] = KeyMap{ .base = ';', .shifted = ':' };
    m[0x52] = KeyMap{ .base = '\'', .shifted = '"' };
    m[0x41] = KeyMap{ .base = ',', .shifted = '<' };
    m[0x49] = KeyMap{ .base = '.', .shifted = '>' };
    m[0x4A] = KeyMap{ .base = '/', .shifted = '?' };
    break :blk m;
};

pub const Key = enum(u16) {
    Unknown,
    // ASCII & control
    Escape,
    Digit1,
    Digit2,
    Digit3,
    Digit4,
    Digit5,
    Digit6,
    Digit7,
    Digit8,
    Digit9,
    Digit0,
    Minus,
    Equal,
    Backspace,
    Tab,
    Q,
    W,
    E,
    R,
    T,
    Y,
    U,
    I,
    O,
    P,
    LBracket,
    RBracket,
    Enter,
    LCtrl,
    A,
    S,
    D,
    F,
    G,
    H,
    J,
    K,
    L,
    Semicolon,
    Quote,
    Backtick,
    LShift,
    Backslash,
    Z,
    X,
    C,
    V,
    B,
    N,
    M,
    Comma,
    Period,
    Slash,
    RShift,
    LAlt,
    Space,
    CapsLock,

    // Function keys
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,

    // Lock keys
    NumLock,
    ScrollLock,

    // Keypad
    KP_0,
    KP_1,
    KP_2,
    KP_3,
    KP_4,
    KP_5,
    KP_6,
    KP_7,
    KP_8,
    KP_9,
    KP_Decimal,
    KP_Multiply,
    KP_Add,
    KP_Subtract,
    KP_Divide,
    KP_Enter,

    // Arrows & nav
    Insert,
    Delete,
    Home,
    End,
    PageUp,
    PageDown,
    ArrowUp,
    ArrowDown,
    ArrowLeft,
    ArrowRight,

    // PrintScreen / Pause
    PrintScreen,
    Pause,

    // GUI / apps
    LGui,
    RGui,
    Apps,

    // Multimedia (E0-prefixed)
    MPrevTrack,
    MNextTrack,
    MPlay,
    MStop,
    MMute,
    MVolUp,
    MVolDown,
    MCalculator,
    MWWWHome,
    MWWWBack,
    MWWWForward,
    MWWWStop,
    MWWWRefresh,
    MWWWFavorites,
    MWWWSearch,
    MEmail,
    MMyComputer,
    MMediaSelect,

    // ACPI (E0-prefixed)
    ACPI_Power,
    ACPI_Sleep,
    ACPI_Wake,
};

// /// A helper to build a 256‑entry table with default = Key.Unknown
// fn buildMap(comptime entries: []const u8, comptime keys: []const Key) [256]Key {
//     comptime {
//         assert(entries.len == keys.len);
//     }
//     var map: [256]Key = undefined;
//     // fill defaults
//     for (map[0..]) |*slot| slot.* = Key.Unknown;
//     // populate
//     for (entries) |code, idx| map[code] = keys[idx];
//     return map;
// }

// pub const ScanCodeSet1: [256]Key = buildMap(
//     // codes
//     &.{
//         0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
//         0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E,
//         0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D,
//         0x2E, 0x2F, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C,
//         0x3D, 0x3E, 0x3F, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B,
//         0x4C, 0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x57,
//         0x58,
//         // (E0)-prefixed entries would need a separate table or handling
//     },
//     // corresponding Keys
//     &.{
//         .Escape, .Digit1, .Digit2, .Digit3, .Digit4, .Digit5, .Digit6, .Digit7,     .Digit8,    .Digit9,      .Digit0,   .Minus,    .Equal,     .Backspace,   .Tab,
//         .Q,      .W,      .E,      .R,      .T,      .Y,      .U,      .I,          .O,         .P,           .LBracket, .RBracket, .Enter,     .LCtrl,       .A,
//         .S,      .D,      .F,      .G,      .H,      .J,      .K,      .L,          .Semicolon, .Quote,       .Backtick, .LShift,   .Backslash, .Z,           .X,
//         .C,      .V,      .B,      .N,      .M,      .Comma,  .Period, .Slash,      .RShift,    .KP_Multiply, .LAlt,     .Space,    .CapsLock,  .F1,          .F2,
//         .F3,     .F4,     .F5,     .F6,     .F7,     .F8,     .F9,     .F10,        .NumLock,   .ScrollLock,  .KP_7,     .KP_8,     .KP_9,      .KP_Subtract, .KP_4,
//         .KP_5,   .KP_6,   .KP_Add, .KP_1,   .KP_2,   .KP_3,   .KP_0,   .KP_Decimal, .F11,       .F12,
//     },
// );

// pub const ScanCodeSet2: [256]Key = buildMap(
//     &.{ /* fill in with the "make" codes from your Set 2 table */ },
//     &.{ /* …and their corresponding Key enum values… */ },
// );

// pub const ScanCodeSet3: [256]Key = buildMap(
//     // only the letter mappings are defined here; everything else is Unknown
//     &.{ 0x1C,0x32,0x21,0x23,0x24,0x2B,0x34,0x33,0x43,0x3B,0x42,0x4B,0x3A,0x31,0x44,0x4D,0x15,0x2D,0x1B,0x2C,0x3C,0x2A,0x1D,0x22,0x35,0x1A },
//     &.{ .A, .B, .C, .D, .E, .F, .G, .H, .I, .J, .K, .L, .M, .N, .O, .P, .Q, .R, .S, .T, .U, .V, .W, .X, .Y, .Z },
// );
