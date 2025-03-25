//! This file provides a VGA text mode driver (80x25)

const std = @import("std");
const utils = @import("../lib/utils.zig");

/// VGA text mode width
pub const VGA_TEXT_WIDTH = usize(80);
/// VGA text mode height
pub const VGA_TEXT_HEIGHT = usize(25);
/// Physical memory address of VGA text mode buffer
pub const VGA_TEXT_BUFFER = @as([*]volatile u16, @ptrFromInt(0xB8000));

/// VGA text mode colors
pub const VgaTextColor = enum(u4) {
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

/// VGA text mode driver
pub const VgaTextDriver = struct {
    /// Current cursor position
    row: usize,
    /// Current cursor position
    column: usize,
    /// Current text color
    color: u8,
    /// Pointer to VGA buffer (memory-mapped)
    buffer: usize, //

    /// Initialize a VGA text mode driver
    pub fn init(self: *VgaTextDriver, buffer_addr: usize) void {
        self.row = 0;
        self.column = 0;
        self.color = entryColor(.GREEN, .BLACK);
        self.buffer = buffer_addr;
        self.clear();
    }

    /// Create a color byte from foreground and background colors
    pub fn entryColor(fg: VgaTextColor, bg: VgaTextColor) u8 {
        return @as(u8, @intFromEnum(fg)) | (@as(u8, @intFromEnum(bg)) << 4);
    }

    /// Create a VGA entry (character with color attributes)
    pub fn entry(ch: u8, color: u8) u16 {
        return @as(u16, ch) | (@as(u16, color) << 8);
    }

    /// Set the current color of the VGA driver
    pub fn setColor(self: *VgaTextDriver, color: u8) void {
        self.color = color;
    }

    /// Put a character to the VGA buffer
    pub fn putChar(self: *VgaTextDriver, ch: u8) void {
        self.buffer[self.row * VGA_TEXT_WIDTH + self.column] = entry(ch, self.color);
        self.column += 1;
    }

    /// Put a character with custom color attributes at a specific position
    pub fn putCharCustom(self: *VgaTextDriver, ch: u8, color: u8, x: usize, y: usize) void {
        self.buffer[y * VGA_TEXT_WIDTH + x] = entry(ch, color);
    }

    /// Write a string to the VGA buffer
    pub fn putStr(self: *VgaTextDriver, str: []const u8) void {
        for (str) |ch| {
            self.putChar(ch);
        }
    }

    /// Write a string to the VGA buffer at a specific position
    pub fn putStrCustom(self: *VgaTextDriver, str: []const u8, color: u8, x: usize, y: usize) void {
        for (str) |ch| {
            self.putCharCustom(ch, color, x, y);
        }
    }

    /// Clear the VGA buffer
    pub fn clear(self: *VgaTextDriver) void {
        for (0..VGA_TEXT_HEIGHT) |y| {
            for (0..VGA_TEXT_WIDTH) |x| {
                const index = y * VGA_TEXT_WIDTH + x;
                self.buffer[index] = entry(' ', self.color);
            }
        }
    }

    /// Scroll the VGA buffer up by one line
    pub fn scroll(self: *VgaTextDriver) void {
        for (0..VGA_TEXT_HEIGHT) |y| {
            for (0..VGA_TEXT_WIDTH) |x| {
                const index = y * VGA_TEXT_WIDTH + x;
                self.buffer[index] = self.buffer[index + VGA_TEXT_WIDTH];
            }
        }
    }
};

// /// Create a VGA entry (character with color attributes)
// fn createEntry(char: u8, entryColor: u8) u16 {
//     return @as(u16, char) | (@as(u16, entryColor) << 8);
// }

// /// Initialize the VGA text mode driver
// pub fn initialize() void {
//     // Clear the screen with default color
//     setColor(.WHITE, .BLACK);
//     clearScreen();
//     setCursorPosition(0, 0);
// }

// /// Set the current color for text output
// pub fn setColor(fg: VgaColor, bg: VgaColor) void {
//     color = createColor(fg, bg);
// }

// /// Clear the entire screen with the current color
// pub fn clearScreen() void {
//     const vgaBuffer = @intToPtr([*]volatile u16, VGA_MEMORY);

//     // Fill the entire buffer with spaces using current color
//     for (0..VGA_HEIGHT) |y| {
//         for (0..VGA_WIDTH) |x| {
//             const index = y * VGA_WIDTH + x;
//             vgaBuffer[index] = createEntry(' ', color);
//         }
//     }

//     // Reset cursor position
//     row = 0;
//     column = 0;
//     updateCursor();
// }

// /// Set the cursor position
// pub fn setCursorPosition(x: usize, y: usize) void {
//     if (x >= VGA_WIDTH || y >= VGA_HEIGHT) {
//         return; // Out of bounds
//     }

//     row = y;
//     column = x;
//     updateCursor();
// }

// /// Update the hardware cursor position
// fn updateCursor() void {
//     const position = row * VGA_WIDTH + column;

//     // The VGA controller uses two I/O ports for cursor position
//     // 0x3D4 is the command port, 0x3D5 is the data port

//     // Tell the VGA we're setting the low cursor byte
//     asm volatile("outb %[port], %[cmd]"
//         :
//         : [port] "{dx}" (@as(u16, 0x3D4)),
//           [cmd] "{al}" (@as(u8, 0x0F))
//     );

//     // Send the low byte of the position
//     asm volatile("outb %[port], %[data]"
//         :
//         : [port] "{dx}" (@as(u16, 0x3D5)),
//           [data] "{al}" (@as(u8, @truncate(u8, position)))
//     );

//     // Tell the VGA we're setting the high cursor byte
//     asm volatile("outb %[port], %[cmd]"
//         :
//         : [port] "{dx}" (@as(u16, 0x3D4)),
//           [cmd] "{al}" (@as(u8, 0x0E))
//     );

//     // Send the high byte of the position
//     asm volatile("outb %[port], %[data]"
//         :
//         : [port] "{dx}" (@as(u16, 0x3D5)),
//           [data] "{al}" (@as(u8, @truncate(u8, position >> 8)))
//     );
// }

// /// Write a single character to the screen at the current position
// pub fn putChar(char: u8) void {
//     const vgaBuffer = @intToPtr([*]volatile u16, VGA_MEMORY);

//     // Handle special characters
//     switch (char) {
//         '\n' => { // New line
//             column = 0;
//             row += 1;
//         },
//         '\r' => { // Carriage return
//             column = 0;
//         },
//         '\t' => { // Tab (advance to next 8-char boundary)
//             column = (column + 8) & ~@as(usize, 7);
//         },
//         '\b' => { // Backspace
//             if (column > 0) {
//                 column -= 1;
//                 // Clear the character at the current position
//                 const index = row * VGA_WIDTH + column;
//                 vgaBuffer[index] = createEntry(' ', color);
//             }
//         },
//         else => { // Regular character
//             const index = row * VGA_WIDTH + column;
//             vgaBuffer[index] = createEntry(char, color);
//             column += 1;
//         }
//     }

//     // Handle end of line
//     if (column >= VGA_WIDTH) {
//         column = 0;
//         row += 1;
//     }

//     // Handle scrolling if we've reached the bottom
//     if (row >= VGA_HEIGHT) {
//         scroll();
//     }

//     // Update the hardware cursor
//     updateCursor();
// }

// /// Write a string to the screen
// pub fn write(str: []const u8) void {
//     for (str) |char| {
//         putChar(char);
//     }
// }

// /// Write a formatted string to the screen (printf-like)
// pub fn printf(comptime fmt: []const u8, args: anytype) void {
//     // Create a buffer for the formatted string
//     var buffer: [1024]u8 = undefined;

//     // Format the string into the buffer
//     const result = std.fmt.bufPrint(&buffer, fmt, args) catch {
//         write("Error formatting string");
//         return;
//     };

//     // Write the formatted string to the screen
//     write(result);
// }

// /// Scroll the screen up by one line
// fn scroll() void {
//     const vgaBuffer = @intToPtr([*]volatile u16, VGA_MEMORY);

//     // Move each line up one position
//     for (1..VGA_HEIGHT) |y| {
//         for (0..VGA_WIDTH) |x| {
//             const sourceIndex = y * VGA_WIDTH + x;
//             const destIndex = (y - 1) * VGA_WIDTH + x;
//             vgaBuffer[destIndex] = vgaBuffer[sourceIndex];
//         }
//     }

//     // Clear the last line
//     const lastRow = VGA_HEIGHT - 1;
//     for (0..VGA_WIDTH) |x| {
//         const index = lastRow * VGA_WIDTH + x;
//         vgaBuffer[index] = createEntry(' ', color);
//     }

//     // Move cursor to the beginning of the last line
//     row = lastRow;
//     column = 0;
// }
