//! This module provides utility functions for the kiwiRTOS kernel.

/// Print functions for debug
pub extern fn printk(fmt: [*:0]const u8, ...) void;
