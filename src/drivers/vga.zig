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

/// VGA text mode buffer address
pub const VGA_TEXT_BUFFER = arch.VGA_TEXT_BUFFER;

/// VGA I/O ports
const VGA_CRTC_INDEX = 0x3D4;
const VGA_CRTC_DATA = 0x3D5;
const VGA_CURSOR_HIGH = 0x0E;
const VGA_CURSOR_LOW = 0x0F;

/// VGA text mode colors
pub const VgaTextColorCode = enum(u8) {
    BLACK = 0,
    BLUE = 1,
    GREEN = 2,
    CYAN = 3,
    RED = 4,
    MAGENTA = 5,
    BROWN = 6,
    LIGHT_GRAY = 7,
    DARK_GRAY = 8,
    LIGHT_BLUE = 9,
    LIGHT_GREEN = 10,
    LIGHT_CYAN = 11,
    LIGHT_RED = 12,
    LIGHT_MAGENTA = 13,
    YELLOW = 14,
    WHITE = 15,
};

/// Represents a VGA text color
pub const VgaTextColor = struct {
    code: u8,

    /// Create a new VGA text color from foreground and background colors
    pub fn new(fg: VgaTextColorCode, bg: VgaTextColorCode) VgaTextColor {
        return VgaTextColor{
            .code = (@as(u8, @intFromEnum(bg)) << 4) | @as(u8, @intFromEnum(fg)),
        };
    }
};

/// Represents a VGA text entry (a character with color attributes)
pub const VgaTextEntry = struct {
    code: u16,

    /// Create a VGA text entry from a unicode character and a color
    pub fn new(ch: u8, color: VgaTextColor) VgaTextEntry {
        return VgaTextEntry{
            .code = @as(u16, ch) | (@as(u16, color.code) << 8),
        };
    }
};

// TODO: VGA driver currently uses port I/O because it uses inb and outb
// It should use the offsets of a buffer address

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

        arch.outb(VGA_CRTC_INDEX, 0x0B);
        arch.outb(VGA_CRTC_DATA, (arch.inb(VGA_CRTC_DATA) & 0xE0) | 15);

        var driver: VgaTextDriver = undefined;
        driver = VgaTextDriver{
            .buffer = @ptrFromInt(buffer_addr),
            .row = 0,
            .column = 0,
            .color = VgaTextColor.new(.GREEN, .BLACK),
        };
        driver.clear();
        driver.updateCursor();
        return driver;
    }

    /// Clear the VGA buffer
    pub fn clear(self: *VgaTextDriver) void {
        for (0..VGA_TEXT_HEIGHT) |y| {
            for (0..VGA_TEXT_WIDTH) |x| {
                const index = y * VGA_TEXT_WIDTH + x;
                self.buffer[index] = VgaTextEntry.new(' ', self.color).code;
            }
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
            self.buffer[index] = VgaTextEntry.new(' ', self.color).code;
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

    /// Put a character with custom color attributes at a specific position
    pub fn putCharAt(self: *VgaTextDriver, ch: u8, x: usize, y: usize) void {
        if (!(x >= VGA_TEXT_WIDTH or y >= VGA_TEXT_HEIGHT)) {
            const index = y * VGA_TEXT_WIDTH + x;
            self.buffer[index] = VgaTextEntry.new(ch, self.color).code;
        }
    }

    /// Put a character to the VGA buffer
    pub fn putChar(self: *VgaTextDriver, ch: u8) void {
        switch (ch) {
            '\n' => {
                self.column = 0;
                self.row += 1;
            },
            else => {
                self.putCharAt(ch, self.column, self.row);
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
            self.putChar(ch);
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
