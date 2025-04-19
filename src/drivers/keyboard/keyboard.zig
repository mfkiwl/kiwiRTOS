//! This file provides a keyboard driver for the kiwiRTOS kernel.

// Re-export the polling-based keyboard module
pub const keyboard = @import("polling.zig");

pub const KeyboardDriver = keyboard.KeyboardDriver;
