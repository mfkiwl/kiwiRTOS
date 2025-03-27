//! Root module for kiwiRTOS
//!
//! A Real-Time Operating System (RTOS) designed for embedded applications with targets for x86, RISC-V (RV32I, RV64I) and ARM written in Zig
//!
//! ## Modules
//! - `arch`: Handles architecture-specific code
//! - `drivers`: Handles drivers for peripherals
//! - `kernel`: Handles the kernel's main loop and initialization
//! - `lib`: Handles utility functions
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

    // Test basic character output without using the vga driver
    uart_driver.putChar('A');
    uart_driver.putChar('B');
    uart_driver.putChar('C');
    uart_driver.putChar('D');
    uart_driver.putChar('E');
    uart_driver.putChar('F');

    // Test basic string output using the vga driver
    // First, we need to get a pointer to the VGA buffer
    const vga_buffer = @volatileCast(@as([*]u16, @ptrFromInt(vga.VGA_TEXT_BUFFER)));
    vga_buffer[0] = vga.VgaTextEntry.new('A', vga.VgaTextColor.new(.WHITE, .BLUE)).code;
    vga_buffer[1] = vga.VgaTextEntry.new('B', vga.VgaTextColor.new(.WHITE, .BLUE)).code;
    vga_buffer[2] = vga.VgaTextEntry.new('C', vga.VgaTextColor.new(.WHITE, .BLUE)).code;
    vga_buffer[3] = vga.VgaTextEntry.new('D', vga.VgaTextColor.new(.WHITE, .BLUE)).code;
    vga_buffer[4] = vga.VgaTextEntry.new('E', vga.VgaTextColor.new(.WHITE, .BLUE)).code;
    vga_buffer[5] = vga.VgaTextEntry.new('F', vga.VgaTextColor.new(.WHITE, .BLUE)).code;

    var vga_text_driver: vga.VgaTextDriver = undefined;
    vga.VgaTextDriver.init(&vga_text_driver, vga.VGA_TEXT_BUFFER);

    // Test basic character output
    vga_text_driver.putChar('X'); // Should show a single character
    vga_text_driver.putCharAt('O', 0, 1); // Should show character on second line

    // Test color
    vga_text_driver.color = vga.VgaTextColor.new(.WHITE, .BLUE); // Change color
    vga_text_driver.println("Color test", .{});

    uart_driver.println("Zig is running on barebones RISC-V (rv{})!", .{@bitSizeOf(usize)});
    uart_driver.println("Hello, world!", .{});
}
