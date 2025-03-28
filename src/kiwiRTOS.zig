//! Root module for kiwiRTOS
//!
//! A minimal Real-Time Operating System (RTOS) designed for embedded applications with targets for x86, RISC-V (RV32I, RV64I) and ARM written in Zig
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

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MB1_MAGIC: u32 = 0x1BADB002;
const FLAGS: u32 = ALIGN | MEMINFO;

const MultibootHeader = extern struct {
    magic: u32 = MB1_MAGIC,
    flags: u32,
    checksum: u32,
};

export var multiboot align(4) linksection(".multiboot") = MultibootHeader{
    .flags = FLAGS,
    .checksum = @as(u32, 0) -% (MB1_MAGIC + FLAGS),
};

// Stack for the kernel
var stack_buffer: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

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
    var vga_text_driver: vga.VgaTextDriver = undefined;
    vga_text_driver = vga.VgaTextDriver.init(vga.VGA_TEXT_BUFFER);
    vga_text_driver.clear();

    // Print a welcome message
    vga_text_driver.setColor(vga.VgaTextColor.new(.WHITE, .BLACK));
    vga_text_driver.putStr("KiwiRTOS VGA Text Driver Demo\n");
    vga_text_driver.putStr("----------------------------\n\n");

    // Demonstrate alternating colors
    var i: usize = 0;
    while (i < 30) { // Intentionally print more than 25 lines to demonstrate scrolling
        if (i % 2 == 0) {
            vga_text_driver.setColor(vga.VgaTextColor.new(.LIGHT_RED, .BLACK));
            // vga_text_driver.println("Hello, green world!", .{});
            vga_text_driver.putStr("Hello, red world!\n");
        } else {
            vga_text_driver.setColor(vga.VgaTextColor.new(.LIGHT_GREEN, .BLACK));
            vga_text_driver.putStr("Hello, green world!\n");
        }
        i += 1;
    }
    vga_text_driver.scroll();
}
