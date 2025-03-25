//! Root module for kiwiRTOS
//!
//! This library provides a simple RTOS for barebones RISC-V systems
//!
//! ## Modules
//! - `drivers`: Handles drivers for peripherals
//! - `lib`: Handles utility functions
//! - `arch`: Handles architecture-specific code
//! - `kernel`: Handles the kernel's main loop and initialization
//! - `services`: Handles services for the RTOS
//! - `syscalls`: Handles system calls for the RTOS

pub const vga = @import("drivers/vga.zig");
pub const uart = @import("drivers/uart.zig");
pub const utils = @import("lib/utils.zig");

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
    uart.UartDriver.init(&uart_driver, uart.UART_BASE, 9600);
    // Who knows, maybe in the future we'll have rv128...
    uart_driver.println("Zig is running on barebones RISC-V (rv{})!", .{@bitSizeOf(usize)});
    var vga_text_driver: vga.VgaTextDriver = undefined;
    vga.VgaTextDriver.init(&vga_text_driver, vga.VGA_TEXT_BUFFER);
    vga_text_driver.println("Zig is running on barebones RISC-V (rv{})!", .{@bitSizeOf(usize)});
    uart_driver.println("Zig is running on barebones RISC-V (rv{})!", .{@bitSizeOf(usize)});
}
