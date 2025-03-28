//! This file provides a VGA text mode driver (80x25)

const std = @import("std");
const utils = @import("../lib/utils.zig");
const builtin = @import("builtin");

const fmt = std.fmt;
const Writer = std.io.Writer;

/// VGA text mode width
pub const VGA_TEXT_WIDTH = @as(usize, 80);
/// VGA text mode height
pub const VGA_TEXT_HEIGHT = @as(usize, 25);
/// VGA text mode size
pub const VGA_TEXT_SIZE = VGA_TEXT_WIDTH * VGA_TEXT_HEIGHT;

/// VGA text mode buffer address
pub const VGA_TEXT_BUFFER = switch (builtin.cpu.arch) {
    .x86 => 0xB8000,
    .aarch64, .riscv64, .riscv32 => 0x09000000,
    else => @compileError("Unsupported architecture"),
};

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

/// VGA text mode driver
pub const VgaTextDriver = struct {
    /// Current cursor position
    row: usize,
    /// Current cursor position
    column: usize,
    /// Current text color
    color: VgaTextColor,
    /// Pointer to VGA buffer (memory-mapped)
    buffer: [*]volatile u16,

    /// Initialize a VGA text mode driver
    pub fn init(buffer_addr: usize) VgaTextDriver {
        // Enable the cursor
        utils.outb(VGA_CRTC_INDEX, 0x0A);
        utils.outb(VGA_CRTC_DATA, (utils.inb(VGA_CRTC_DATA) & 0xC0) | 0);

        utils.outb(VGA_CRTC_INDEX, 0x0B);
        utils.outb(VGA_CRTC_DATA, (utils.inb(VGA_CRTC_DATA) & 0xE0) | 15);

        var driver = VgaTextDriver{
            .row = 0,
            .column = 0,
            .buffer = @ptrFromInt(buffer_addr),
            .color = VgaTextColor.new(.GREEN, .BLACK),
        };

        driver.updateCursor();
        return driver;
    }

    /// Clear the screen using the active background color as the color to be painted.
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
        for (1..VGA_TEXT_HEIGHT) |y| {
            for (0..VGA_TEXT_WIDTH) |x| {
                const index = y * VGA_TEXT_WIDTH + x;
                const next_index = (y - 1) * VGA_TEXT_WIDTH + x;
                self.buffer[next_index] = self.buffer[index];
            }
        }
        self.updateCursor();
    }

    /// Updates the hardware cursor position
    pub fn updateCursor(self: *const VgaTextDriver) void {
        const pos = self.row * VGA_TEXT_WIDTH + self.column;

        // Send high byte of cursor position
        utils.outb(VGA_CRTC_INDEX, VGA_CURSOR_HIGH);
        utils.outb(VGA_CRTC_DATA, @as(u8, @truncate(pos >> 8)));

        // Send low byte of cursor position
        utils.outb(VGA_CRTC_INDEX, VGA_CURSOR_LOW);
        utils.outb(VGA_CRTC_DATA, @as(u8, @truncate(pos)));
    }

    /// Set the current color of the VGA driver
    pub fn setColor(self: *VgaTextDriver, color: u8) void {
        self.color = color;
    }

    /// Puts a character at the specific coordinates using the specified color.
    pub fn putCharAt(self: *VgaTextDriver, c: u8, newColor: VgaTextColor, x: usize, y: usize) void {
        if (!(x >= VGA_TEXT_WIDTH or y >= VGA_TEXT_HEIGHT)) {
            const index = y * VGA_TEXT_WIDTH + x;
            self.buffer[index] = VgaTextEntry.new(c, newColor).code;
        }
    }

    /// Prints a single character
    pub fn putChar(self: *VgaTextDriver, c: u8) void {
        self.putCharAt(c, self.color, self.column, self.row);
        self.column += 1;
        if (self.column == VGA_TEXT_WIDTH) {
            self.column = 0;
            self.row += 1;
            if (self.row == VGA_TEXT_HEIGHT)
                self.row = 0;
        }
        self.updateCursor();
    }

    pub fn putString(self: *VgaTextDriver, data: []const u8) void {
        for (data) |c| {
            self.putChar(c);
        }
    }

    /// Sets the current cursor location.
    pub fn setLocation(self: *VgaTextDriver, x: u8, y: u8) void {
        self.column = x % VGA_TEXT_WIDTH;
        self.row = y % VGA_TEXT_HEIGHT;
        self.updateCursor();
    }

    pub fn writer(self: *VgaTextDriver) Writer(*VgaTextDriver, error{}, writerCallback) {
        return .{ .context = self };
    }

    fn writerCallback(self: *VgaTextDriver, string: []const u8) error{}!usize {
        self.putString(string);
        return string.len;
    }

    pub fn printf(self: *VgaTextDriver, comptime format: []const u8, args: anytype) void {
        fmt.format(self.writer(), format, args) catch unreachable;
    }
};

// Create a global instance for backward compatibility
var default_driver: VgaTextDriver = undefined;

pub fn setLocation(x: u8, y: u8) void {
    default_driver.setLocation(x, y);
}

pub fn putChar(c: u8) void {
    default_driver.putChar(c);
}

pub fn putString(data: []const u8) void {
    default_driver.putString(data);
}

pub const writer = Writer(*VgaTextDriver, error{}, VgaTextDriver.writerCallback){ .context = &default_driver };

pub fn printf(comptime format: []const u8, args: anytype) void {
    default_driver.printf(format, args);
}

pub fn init() void {
    default_driver = VgaTextDriver.init(VGA_TEXT_BUFFER);
}

pub fn clear() void {
    default_driver.clear();
}
