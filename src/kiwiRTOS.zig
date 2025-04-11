//! Root module for kiwiRTOS
//!
//! A minimal Real-Time Operating System (RTOS) designed for embedded applications with targets for x86_64, RISC-V (RV32I, RV64I) and ARM written in Zig
//!
//! ## Modules
//! - `arch`: Handles architecture-specific code
//! - `drivers`: Handles drivers for peripherals
//! - `kernel`: Handles the kernel's main loop and initialization
//! - `lib`: Handles utility functions
//! - `services`: Handles services for the RTOS
//! - `syscalls`: Handles system calls for the RTOS

pub const arch = @import("arch/arch.zig");
pub const drivers = @import("drivers/drivers.zig");
pub const kernel = @import("kernel/kernel.zig");
pub const lib = @import("lib/lib.zig");

// This the trap/exception entrypoint, this will be invoked any time
// we get an exception (e.g if something in the kernel goes wrong) or
// an interrupt gets delivered.
export fn trap() align(4) callconv(.C) noreturn {
    while (true) {}
}

// This is the kernel's entrypoint which will be invoked by the booting
// CPU (aka hart) after the boot code has executed.
export fn kmain() callconv(.C) noreturn {
    main();
    // Halt the CPU if we ever return from main
    while (true) {}
}

pub fn main() void {
    // Initialize VGA text driver
    var vga_text_driver: drivers.vga.VgaTextDriver = undefined;
    vga_text_driver = drivers.vga.VgaTextDriver.init(drivers.vga.VGA_TEXT_BUFFER);
    vga_text_driver.clear();

    // Print a welcome message
    vga_text_driver.setColor(drivers.vga.VgaTextColor.new(.WHITE, .BLACK));
    vga_text_driver.putStr("KiwiRTOS VGA Text Driver Demo\n");
    vga_text_driver.putStr("----------------------------\n\n");

    // Demonstrate alternating colors
    var i: usize = 0;
    while (i < 30) { // Intentionally print more than 25 lines to demonstrate scrolling
        if (i % 2 == 0) {
            vga_text_driver.setColor(drivers.vga.VgaTextColor.new(.LIGHT_RED, .BLACK));
            vga_text_driver.println("Hello, red world!", .{});
        } else {
            vga_text_driver.setColor(drivers.vga.VgaTextColor.new(.LIGHT_GREEN, .BLACK));
            vga_text_driver.println("Hello, green world!", .{});
        }
        i += 1;
    }
    vga_text_driver.scroll();
}
