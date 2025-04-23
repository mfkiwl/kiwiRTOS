//! This file provides various scancode lookup tables for the keyboard driver.

const std = @import("std");

/// Represents a mapping for a single key
const KeyMap = struct {
    /// The unshifted ASCII character
    base: u8,
    /// The shifted ASCII character
    shifted: u8,
};

/// Represents a lookup table that maps 16-bit scancodes (including extended keys)
/// to their corresponding KeyMap values.
///
/// This uses u16 to represent both regular codes and extended codes:
/// - Normal scancodes: 0x00-0xFF
/// - Extended scancodes: 0xE0XX (where XX is the second byte)
/// Represents a scancode set
pub const ScanCodeSet = struct {
    /// The scancode lookup table
    set: std.StaticStringMap(KeyMap),
    /// The extended scancode
    extended: ?u16,
    /// The release scancode
    release: ?u16,
    /// The left shift scancode
    left_shift: ?u16,
    /// The right shift scancode
    right_shift: ?u16,
    /// The left ctrl scancode
    left_ctrl: ?u16,
    /// The right ctrl scancode
    right_ctrl: ?u16,
    /// The left alt scancode
    left_alt: ?u16,
    /// The right alt scancode
    right_alt: ?u16,
    /// The caps lock scancode
    caps_lock: ?u16,

    /// Converts a scancode to its corresponding character
    pub fn getChar(self: ScanCodeSet, scancode: []const u8, shifted: bool) ?u8 {
        if (self.set.get(scancode)) |keymap| {
            return if (shifted) keymap.shifted else keymap.base;
        } else {
            return null;
        }
    }
};

/// Scancode set 1 (default) for a "US QWERTY" keyboard
pub const ScanCodeSet1: ScanCodeSet = .{
    .set = std.StaticStringMap(KeyMap).initComptime(.{
        // Regular keys (single-byte scancodes)
        // 0x00-0x0F
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
        // 0x10-0x1F
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
        // 0x20-0x2F
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
        // 0x30-0x3F
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
        // 0x54-0x5F
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
    }),
    .extended = 0xE0,
    .release = 0x9E,
    .left_shift = 0x2A,
    .right_shift = 0x36,
    .left_ctrl = 0x1D,
    .right_ctrl = 0x1D,
    .left_alt = 0xB8,
    // Extended prefix
    .right_alt = 0x38,
    .caps_lock = 0xBA,
};

/// Scancode set 2 (most common) for a "US QWERTY" keyboard
pub const ScanCodeSet2: ScanCodeSet = .{
    .set = std.StaticStringMap(KeyMap).initComptime(.{
        .{ "01", KeyMap{ .base = 0x1B, .shifted = 0x1B } }, // F9
        .{ "03", KeyMap{ .base = 0x15, .shifted = 0x15 } }, // F5
        .{ "04", KeyMap{ .base = 0x13, .shifted = 0x13 } }, // F3
        .{ "05", KeyMap{ .base = 0x11, .shifted = 0x11 } }, // F1
        .{ "06", KeyMap{ .base = 0x12, .shifted = 0x12 } }, // F2
        .{ "07", KeyMap{ .base = 0x1C, .shifted = 0x1C } }, // F12
        .{ "09", KeyMap{ .base = 0x1A, .shifted = 0x1A } }, // F10
        .{ "0A", KeyMap{ .base = 0x18, .shifted = 0x18 } }, // F8
        .{ "0B", KeyMap{ .base = 0x16, .shifted = 0x16 } }, // F6
        .{ "0C", KeyMap{ .base = 0x14, .shifted = 0x14 } }, // F4
        .{ "0D", KeyMap{ .base = '\t', .shifted = '\t' } }, // Tab
        .{ "0E", KeyMap{ .base = '`', .shifted = '~' } }, // ` (backtick)
        .{ "11", KeyMap{ .base = 0, .shifted = 0 } }, // Left Alt
        .{ "12", KeyMap{ .base = 0, .shifted = 0 } }, // Left Shift
        .{ "14", KeyMap{ .base = 0, .shifted = 0 } }, // Left Ctrl
        .{ "15", KeyMap{ .base = 'q', .shifted = 'Q' } }, // Q
        .{ "16", KeyMap{ .base = '1', .shifted = '!' } }, // 1
        .{ "1A", KeyMap{ .base = 'z', .shifted = 'Z' } }, // Z
        .{ "1B", KeyMap{ .base = 's', .shifted = 'S' } }, // S
        .{ "1C", KeyMap{ .base = 'a', .shifted = 'A' } }, // A
        .{ "1D", KeyMap{ .base = 'w', .shifted = 'W' } }, // W
        .{ "1E", KeyMap{ .base = '2', .shifted = '@' } }, // 2
        .{ "21", KeyMap{ .base = 'c', .shifted = 'C' } }, // C
        .{ "22", KeyMap{ .base = 'x', .shifted = 'X' } }, // X
        .{ "23", KeyMap{ .base = 'd', .shifted = 'D' } }, // D
        .{ "24", KeyMap{ .base = 'e', .shifted = 'E' } }, // E
        .{ "25", KeyMap{ .base = '4', .shifted = '$' } }, // 4
        .{ "26", KeyMap{ .base = '3', .shifted = '#' } }, // 3
        .{ "29", KeyMap{ .base = ' ', .shifted = ' ' } }, // Space
        .{ "2A", KeyMap{ .base = 'v', .shifted = 'V' } }, // V
        .{ "2B", KeyMap{ .base = 'f', .shifted = 'F' } }, // F
        .{ "2C", KeyMap{ .base = 't', .shifted = 'T' } }, // T
        .{ "2D", KeyMap{ .base = 'r', .shifted = 'R' } }, // R
        .{ "2E", KeyMap{ .base = '5', .shifted = '%' } }, // 5
        .{ "31", KeyMap{ .base = 'n', .shifted = 'N' } }, // N
        .{ "32", KeyMap{ .base = 'b', .shifted = 'B' } }, // B
        .{ "33", KeyMap{ .base = 'h', .shifted = 'H' } }, // H
        .{ "34", KeyMap{ .base = 'g', .shifted = 'G' } }, // G
        .{ "35", KeyMap{ .base = 'y', .shifted = 'Y' } }, // Y
        .{ "36", KeyMap{ .base = '6', .shifted = '^' } }, // 6
        .{ "3A", KeyMap{ .base = 'm', .shifted = 'M' } }, // M
        .{ "3B", KeyMap{ .base = 'j', .shifted = 'J' } }, // J
        .{ "3C", KeyMap{ .base = 'u', .shifted = 'U' } }, // U
        .{ "3D", KeyMap{ .base = '7', .shifted = '&' } }, // 7
        .{ "3E", KeyMap{ .base = '8', .shifted = '*' } }, // 8
        .{ "41", KeyMap{ .base = ',', .shifted = '<' } }, // , (comma)
        .{ "42", KeyMap{ .base = 'k', .shifted = 'K' } }, // K
        .{ "43", KeyMap{ .base = 'i', .shifted = 'I' } }, // I
        .{ "44", KeyMap{ .base = 'o', .shifted = 'O' } }, // O
        .{ "45", KeyMap{ .base = '0', .shifted = ')' } }, // 0
        .{ "46", KeyMap{ .base = '9', .shifted = '(' } }, // 9
        .{ "49", KeyMap{ .base = '.', .shifted = '>' } }, // . (period)
        .{ "4A", KeyMap{ .base = '/', .shifted = '?' } }, // / (slash)
        .{ "4B", KeyMap{ .base = 'l', .shifted = 'L' } }, // L
        .{ "4C", KeyMap{ .base = ';', .shifted = ':' } }, // ; (semicolon)
        .{ "4D", KeyMap{ .base = 'p', .shifted = 'P' } }, // P
        .{ "4E", KeyMap{ .base = '-', .shifted = '_' } }, // - (dash)
        .{ "52", KeyMap{ .base = '\'', .shifted = '"' } }, // ' (single quote)
        .{ "54", KeyMap{ .base = '[', .shifted = '{' } }, // [ (left bracket)
        .{ "55", KeyMap{ .base = '=', .shifted = '+' } }, // = (equals)
        .{ "5A", KeyMap{ .base = '\n', .shifted = '\n' } }, // Enter
        .{ "5B", KeyMap{ .base = ']', .shifted = '}' } }, // ] (right bracket)
        .{ "5D", KeyMap{ .base = '\\', .shifted = '|' } }, // \ (backslash)
        .{ "66", KeyMap{ .base = 0x08, .shifted = 0x08 } }, // Backspace
        .{ "69", KeyMap{ .base = '1', .shifted = '1' } }, // Keypad 1
        .{ "6B", KeyMap{ .base = '4', .shifted = '4' } }, // Keypad 4
        .{ "6C", KeyMap{ .base = '7', .shifted = '7' } }, // Keypad 7
        .{ "70", KeyMap{ .base = '0', .shifted = '0' } }, // Keypad 0
        .{ "71", KeyMap{ .base = '.', .shifted = '.' } }, // Keypad .
        .{ "72", KeyMap{ .base = '2', .shifted = '2' } }, // Keypad 2
        .{ "73", KeyMap{ .base = '5', .shifted = '5' } }, // Keypad 5
        .{ "74", KeyMap{ .base = '6', .shifted = '6' } }, // Keypad 6
        .{ "75", KeyMap{ .base = '8', .shifted = '8' } }, // Keypad 8
        .{ "76", KeyMap{ .base = 0x1B, .shifted = 0x1B } }, // Escape
        .{ "77", KeyMap{ .base = 0, .shifted = 0 } }, // Num Lock
        .{ "78", KeyMap{ .base = 0x17, .shifted = 0x17 } }, // F11
        .{ "79", KeyMap{ .base = '+', .shifted = '+' } }, // Keypad +
        .{ "7A", KeyMap{ .base = '3', .shifted = '3' } }, // Keypad 3
        .{ "7B", KeyMap{ .base = '-', .shifted = '-' } }, // Keypad -
        .{ "7C", KeyMap{ .base = '*', .shifted = '*' } }, // Keypad *
        .{ "7D", KeyMap{ .base = '9', .shifted = '9' } }, // Keypad 9
        .{ "7E", KeyMap{ .base = 0, .shifted = 0 } }, // Scroll Lock
        .{ "83", KeyMap{ .base = 0x19, .shifted = 0x19 } }, // F7
        .{ "E014", KeyMap{ .base = 0, .shifted = 0 } }, // Right Ctrl
        .{ "E01F", KeyMap{ .base = 0, .shifted = 0 } }, // Left GUI
        .{ "E027", KeyMap{ .base = 0, .shifted = 0 } }, // Right GUI
        .{ "E04A", KeyMap{ .base = '/', .shifted = '/' } }, // Keypad /
        .{ "E05A", KeyMap{ .base = '\n', .shifted = '\n' } }, // Keypad Enter
        .{ "E011", KeyMap{ .base = 0, .shifted = 0 } }, // Right Alt
        .{ "E06B", KeyMap{ .base = 0x1B, .shifted = 0x1B } }, // Left Arrow
        .{ "E06C", KeyMap{ .base = 0x18, .shifted = 0x18 } }, // Home
        .{ "E070", KeyMap{ .base = 0x1F, .shifted = 0x1F } }, // Insert
        .{ "E071", KeyMap{ .base = 0x7F, .shifted = 0x7F } }, // Delete
        .{ "E072", KeyMap{ .base = 0x1C, .shifted = 0x1C } }, // Down Arrow
        .{ "E074", KeyMap{ .base = 0x1A, .shifted = 0x1A } }, // Right Arrow
        .{ "E075", KeyMap{ .base = 0x19, .shifted = 0x19 } }, // Up Arrow
        .{ "E069", KeyMap{ .base = 0x1D, .shifted = 0x1D } }, // End
        .{ "E07D", KeyMap{ .base = 0x19, .shifted = 0x19 } }, // Page Up
        .{ "E07A", KeyMap{ .base = 0x1E, .shifted = 0x1E } }, // Page Down
    }),
    .extended = 0xE0,
    .release = 0xF0,
    .left_shift = 0x12,
    .right_shift = 0x59,
    .left_ctrl = 0x14,
    .right_ctrl = 0x14,
    .left_alt = 0x11,
    .right_alt = 0x11,
    .caps_lock = 0x58,
};

/// Scancode set 3 (rare) for a "US QWERTY" keyboard
pub const ScanCodeSet3: ScanCodeSet = .{
    .set = std.StaticStringMap(KeyMap).initComptime(.{
        .{ "02", KeyMap{ .base = '1', .shifted = '!' } },
    }),
    .extended = 0xE0,
    .release = 0xF0,
    .left_shift = 0x12,
    .right_shift = 0x59,
    .left_ctrl = 0x14,
    .right_ctrl = 0x14,
};

/// Represents the set of supported scancodes
///
/// A scan code set is a set of codes that determine when a key is pressed or repeated, or released. There are 3 different sets of scan codes. The oldest is "scan code set 1", the default is "scan code set 2", and there is a newer (more complex) "scan code set 3". Note: Normally on PC compatible systems the keyboard itself uses scan code set 2 and the keyboard controller translates this into scan code set 1 for compatibility. See "8042"_PS/2_Controller for more information about this translation.
pub const ScanCodeSets = enum(u8) {
    /// Scancode set 1 (default)
    SCANCODE_SET_1 = 0x01,
    /// Scancode set 2 (most common)
    SCANCODE_SET_2 = 0x02,
    /// Scancode set 3 (rare)
    SCANCODE_SET_3 = 0x03,

    /// Get the scancode set
    pub fn getScanCodeSet(self: ScanCodeSets) ScanCodeSet {
        return switch (self) {
            .SCANCODE_SET_1 => ScanCodeSet1,
            .SCANCODE_SET_2 => ScanCodeSet2,
            .SCANCODE_SET_3 => ScanCodeSet3,
        };
    }
};
