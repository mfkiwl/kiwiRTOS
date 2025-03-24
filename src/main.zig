//! This is the main entrypoint for the kernel

const std = @import("std");
const uart = @import("drivers/uart.zig");
const vga = @import("drivers/vga.zig");
const utils = @import("lib/utils.zig");

// This the trap/exception entrypoint, this will be invoked any time
// we get an exception (e.g if something in the kernel goes wrong) or
// an interrupt gets delivered.
export fn trap() align(4) callconv(.C) noreturn {
    while (true) {}
}

// This is the kernel's entrypoint which will be invoked by the booting
// CPU (aka hart) after the boot code has executed.
export fn kmain() callconv(.C) void {
    // All we're doing is setting up access to the serial device (UART)
    // and printing a simple message to make sure the kernel has started!
    var uart_driver: uart.UartDriver = undefined;
    uart.UartDriver.init(&uart_driver, uart.UART_BASE);
    // Who knows, maybe in the future we'll have rv128...
    uart.println(&uart_driver, "Zig is running on barebones RISC-V (rv{})!", .{@bitSizeOf(usize)});
}
