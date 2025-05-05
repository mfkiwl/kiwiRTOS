//! This file provides a VGA text mode driver (80x25)

const arch = @import("../arch/arch.zig");
const builtin = @import("builtin");
const std = @import("std");

/// Writer type for std library integration
const Writer = std.io.Writer;

/// VGA text mode width
pub const VGA_TEXT_WIDTH = @as(usize, 80);
/// VGA text mode height
pub const VGA_TEXT_HEIGHT = @as(usize, 25);
/// VGA text mode size
pub const VGA_TEXT_SIZE = VGA_TEXT_WIDTH * VGA_TEXT_HEIGHT;

/// VGA text mode tab width
pub const VGA_TEXT_TAB_WIDTH = @as(usize, 8);

/// VGA text mode buffer address
pub const VGA_TEXT_BUFFER = arch.VGA_TEXT_BUFFER;

/// VGA CRT Controller (CRTC) I/O ports
/// CRTC Index port
pub const VGA_CRTC_INDEX = 0x3D4;
/// CRTC Data port
pub const VGA_CRTC_DATA = 0x3D5;
/// VGA cursor low byte port
pub const VGA_CURSOR_LOW = 0x0F;
/// VGA cursor high byte port
pub const VGA_CURSOR_HIGH = 0x0E;

/// VGA text mode colors
pub const VgaTextColorCode = enum(u4) {
    /// VGA Text Mode Black
    VGA_COLOR_BLACK = 0,
    /// VGA Text Mode Blue
    VGA_COLOR_BLUE = 1,
    /// VGA Text Mode Green
    VGA_COLOR_GREEN = 2,
    /// VGA Text Mode Cyan
    VGA_COLOR_CYAN = 3,
    /// VGA Text Mode Red
    VGA_COLOR_RED = 4,
    /// VGA Text Mode Magenta
    VGA_COLOR_MAGENTA = 5,
    /// VGA Text Mode Brown
    VGA_COLOR_BROWN = 6,
    /// VGA Text Mode Light Gray
    VGA_COLOR_LIGHT_GRAY = 7,
    /// VGA Text Mode Dark Gray
    VGA_COLOR_DARK_GRAY = 8,
    /// VGA Text Mode Light Blue
    VGA_COLOR_LIGHT_BLUE = 9,
    /// VGA Text Mode Light Green
    VGA_COLOR_LIGHT_GREEN = 10,
    /// VGA Text Mode Light Cyan
    VGA_COLOR_LIGHT_CYAN = 11,
    /// VGA Text Mode Light Red
    VGA_COLOR_LIGHT_RED = 12,
    /// VGA Text Mode Light Magenta
    VGA_COLOR_LIGHT_MAGENTA = 13,
    /// VGA Text Mode Yellow
    VGA_COLOR_YELLOW = 14,
    /// VGA Text Mode White
    VGA_COLOR_WHITE = 15,
};

/// Represents a VGA text color
pub const VgaTextColor = packed struct {
    /// The foreground color code
    fg: u4,
    /// The background color code
    bg: u4,

    /// Create a new VGA text color from foreground and background colors
    pub fn new(fg: VgaTextColorCode, bg: VgaTextColorCode) VgaTextColor {
        return VgaTextColor{
            .fg = @as(u4, @intFromEnum(fg)),
            .bg = @as(u4, @intFromEnum(bg)),
        };
    }
};

/// Represents a VGA text entry (a character with color attributes)
pub const VgaTextEntry = packed struct {
    /// ASCII character
    ascii: u8,
    /// Foreground color
    fg: u4,
    /// Background color
    bg: u4,

    /// Create a VGA text entry from a unicode character and a color
    pub fn new(ch: u8, color: VgaTextColor) VgaTextEntry {
        return VgaTextEntry{
            .ascii = ch,
            .fg = color.fg,
            .bg = color.bg,
        };
    }
};

/// VGA text mode driver
pub const VgaTextDriver = struct {
    /// Pointer to VGA buffer (memory-mapped)
    buffer: [*]volatile u16,
    /// Current cursor position
    row: usize,
    /// Current cursor position
    column: usize,
    /// Current text color
    color: VgaTextColor,

    /// Initialize a VGA text mode driver
    pub fn init(buffer_addr: usize) VgaTextDriver {
        // Enable the cursor
        arch.outb(VGA_CRTC_INDEX, 0x0A);
        arch.outb(VGA_CRTC_DATA, (arch.inb(VGA_CRTC_DATA) & 0xC0) | 0);

        // Enable blinking
        arch.outb(VGA_CRTC_INDEX, 0x0B);
        arch.outb(VGA_CRTC_DATA, (arch.inb(VGA_CRTC_DATA) & 0xE0) | 15);

        var driver: VgaTextDriver = VgaTextDriver{
            .buffer = @ptrFromInt(buffer_addr),
            .row = 0,
            .column = 0,
            .color = VgaTextColor.new(.VGA_COLOR_GREEN, .VGA_COLOR_BLACK),
        };
        driver.clear();
        driver.updateCursor();
        return driver;
    }

    /// Clear the VGA buffer
    pub fn clear(self: *VgaTextDriver) void {
        const empty_char = @as(u16, @bitCast(VgaTextEntry.new('\x00', self.color)));
        for (0..VGA_TEXT_SIZE) |i| {
            self.buffer[i] = empty_char;
        }
        self.row = 0;
        self.column = 0;
        self.updateCursor();
    }

    /// Scroll the VGA buffer up by one line
    pub fn scroll(self: *VgaTextDriver) void {
        // Move all lines up by one
        for (1..VGA_TEXT_HEIGHT) |y| {
            for (0..VGA_TEXT_WIDTH) |x| {
                const index = y * VGA_TEXT_WIDTH + x;
                const next_index = (y - 1) * VGA_TEXT_WIDTH + x;
                self.buffer[next_index] = self.buffer[index];
            }
        }

        // Clear the last line
        const last_row = VGA_TEXT_HEIGHT - 1;
        for (0..VGA_TEXT_WIDTH) |x| {
            const index = last_row * VGA_TEXT_WIDTH + x;
            self.buffer[index] = @as(u16, @bitCast(VgaTextEntry.new('\x00', self.color)));
        }

        // Update cursor position
        if (self.row > 0) {
            self.row -= 1;
        }
        self.updateCursor();
    }

    /// Updates the hardware cursor position
    pub fn updateCursor(self: *const VgaTextDriver) void {
        const pos = self.row * VGA_TEXT_WIDTH + self.column;

        // Send high byte of cursor position
        arch.outb(VGA_CRTC_INDEX, VGA_CURSOR_HIGH);
        arch.outb(VGA_CRTC_DATA, @as(u8, @truncate(pos >> 8)));

        // Send low byte of cursor position
        arch.outb(VGA_CRTC_INDEX, VGA_CURSOR_LOW);
        arch.outb(VGA_CRTC_DATA, @as(u8, @truncate(pos)));
    }

    /// Set the current color of the VGA driver
    pub fn setColor(self: *VgaTextDriver, color: VgaTextColor) void {
        self.color = color;
    }

    /// Get the character at a specific position
    pub fn getCharAt(self: *VgaTextDriver, x: usize, y: usize) u8 {
        if (!(x >= VGA_TEXT_WIDTH or y >= VGA_TEXT_HEIGHT)) {
            const index = y * VGA_TEXT_WIDTH + x;
            const entry: VgaTextEntry = @bitCast(self.buffer[index]);
            return entry.ascii;
        }
        return '\x00';
    }

    /// Put a character with custom color attributes at a specific position
    pub fn setCharAt(self: *VgaTextDriver, ch: u8, x: usize, y: usize) void {
        if (!(x >= VGA_TEXT_WIDTH or y >= VGA_TEXT_HEIGHT)) {
            const index = y * VGA_TEXT_WIDTH + x;
            self.buffer[index] = @as(u16, @bitCast(VgaTextEntry.new(ch, self.color)));
        }
    }

    /// Put a character to the VGA buffer
    pub fn setChar(self: *VgaTextDriver, ch: u8) void {
        switch (ch) {
            // Newlines should create a new line
            '\n' => {
                self.column = 0;
                self.row += 1;
            },
            // Backspaces should move the cursor back one column
            '\x08' => {
                while (self.column > 0 and self.getCharAt(self.column, self.row) == '\x00') {
                    self.column -= 1;
                }
                self.setCharAt(0, self.column, self.row);
            },
            // Tabs should move the cursor to the next tab stop
            '\t' => {
                self.column = (self.column + VGA_TEXT_TAB_WIDTH) & ~@as(usize, VGA_TEXT_TAB_WIDTH - 1);
            },
            else => {
                self.setCharAt(ch, self.column, self.row);
                self.column += 1;
            },
        }
        if (self.column >= VGA_TEXT_WIDTH) {
            self.column = 0;
            self.row += 1;
        }
        if (self.row >= VGA_TEXT_HEIGHT) {
            // When we reach the bottom of the screen, scroll instead of resetting row
            self.scroll();
            // No need to set row to 0, scroll() already decremented the row
        }
        self.updateCursor();
    }

    /// Write a string to the VGA buffer
    pub fn putStr(self: *VgaTextDriver, str: []const u8) void {
        for (str) |ch| {
            self.setChar(ch);
        }
    }

    /// Writer for the VGA text mode driver
    pub fn writer(self: *VgaTextDriver) Writer(*VgaTextDriver, error{}, writerFn) {
        return .{ .context = self };
    }

    /// Writer function for std.io.Writer interface
    pub fn writerFn(self: *VgaTextDriver, bytes: []const u8) error{}!usize {
        self.putStr(bytes);
        return bytes.len;
    }

    /// Print a formatted string to the VGA buffer
    pub fn printf(self: *VgaTextDriver, comptime format: []const u8, args: anytype) void {
        self.writer().print(format, args) catch unreachable;
    }

    /// Print a formatted string to the VGA buffer
    pub fn printk(self: *VgaTextDriver, comptime format: []const u8, args: anytype) void {
        self.writer().print(format, args) catch unreachable;
    }

    /// Print a formatted string to the VGA buffer followed by a newline
    pub fn println(self: *VgaTextDriver, comptime format: []const u8, args: anytype) void {
        self.writer().print(format ++ "\n", args) catch unreachable;
    }
};
