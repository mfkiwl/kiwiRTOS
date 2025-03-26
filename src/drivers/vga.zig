//! This file provides a VGA text mode driver (80x25)

const std = @import("std");
const utils = @import("../lib/utils.zig");
const builtin = @import("builtin");

/// VGA text mode width
pub const VGA_TEXT_WIDTH = @as(usize, 80);
/// VGA text mode height
pub const VGA_TEXT_HEIGHT = @as(usize, 25);

/// VGA text mode buffer address
pub const VGA_TEXT_BUFFER = switch (builtin.cpu.arch) {
    .x86 => 0xB8000,
    .aarch64, .riscv64, .riscv32 => 0x09000000,
    else => @compileError("Unsupported architecture"),
};

/// VGA text mode colors
pub const VgaTextColorCode = enum(u4) {
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

    /// Create a VGA text entry from a character and a color
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
    buffer: usize,
    /// Writer for std.io.Writer interface
    writer: Writer,

    /// Initialize a VGA text mode driver
    pub fn init(self: *VgaTextDriver, buffer_addr: usize) void {
        self.row = 0;
        self.column = 0;
        self.color = VgaTextColor.new(.GREEN, .BLACK);
        self.buffer = buffer_addr;
        self.writer = .{ .context = self };
        self.clear();
    }

    /// Set the current color of the VGA driver
    pub fn setColor(self: *VgaTextDriver, color: u8) void {
        self.color = color;
    }

    /// Put a character to the VGA buffer
    pub fn putChar(self: *VgaTextDriver, ch: u8) void {
        switch (ch) {
            '\n' => self.scroll(),
            else => {
                if (self.column >= VGA_TEXT_WIDTH) {
                    self.scroll();
                }
                self.putCharAt(ch, self.column, self.row);
                self.column += 1;
            },
        }
    }

    /// Put a character with custom color attributes at a specific position
    pub fn putCharAt(self: *VgaTextDriver, ch: u8, x: usize, y: usize) void {
        if (!(x >= VGA_TEXT_WIDTH or y >= VGA_TEXT_HEIGHT)) {
            const index = y * VGA_TEXT_WIDTH + x;
            utils.writeHalfWord(self.buffer + index, VgaTextEntry.new(ch, self.color).code);
        }
    }

    /// Write a string to the VGA buffer
    pub fn putStr(self: *VgaTextDriver, str: []const u8) !usize {
        for (str) |ch| {
            self.putChar(ch);
        }
        return str.len;
    }

    /// Writer function for std.io.Writer interface
    pub fn writerFn(self: *VgaTextDriver, bytes: []const u8) error{}!usize {
        return self.putStr(bytes);
    }

    pub fn println(self: *VgaTextDriver, comptime fmt: []const u8, args: anytype) void {
        self.writer.print(fmt ++ "\n", args) catch {};
    }

    /// Clear the VGA buffer
    pub fn clear(self: *VgaTextDriver) void {
        for (0..VGA_TEXT_HEIGHT) |y| {
            for (0..VGA_TEXT_WIDTH) |x| {
                self.putCharAt(' ', x, y);
            }
        }
    }

    /// Scroll the VGA buffer up by one line
    pub fn scroll(self: *VgaTextDriver) void {
        for (1..VGA_TEXT_HEIGHT) |y| {
            for (0..VGA_TEXT_WIDTH) |x| {
                const index = y * VGA_TEXT_WIDTH + x;
                const next_index = (y - 1) * VGA_TEXT_WIDTH + x;
                utils.writeHalfWord(self.buffer + next_index, utils.readHalfWord(self.buffer + index));
            }
        }
    }
};

/// Writer type for std library integration
const Writer = std.io.Writer(*VgaTextDriver, error{}, VgaTextDriver.writerFn);
