//! This file provides a keyboard driver for the kiwiRTOS kernel.

// Re-export the polling-based keyboard module
pub const keyboard = @import("polling.zig");
