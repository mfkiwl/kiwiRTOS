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
// // pub const uart = @import("drivers/uart.zig");
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
    vga.init();
    vga.setColors(.WHITE, .BLUE);
    vga.clear();
    vga.putString("Hello, world");
    vga.setForegroundColor(.LIGHT_RED);
    vga.putChar('!');

    // // Initialize console
    // var vga_text_driver: vga.VgaTextDriver = undefined;
    // vga.VgaTextDriver.init(&vga_text_driver, vga.VGA_TEXT_BUFFER);
    // vga_text_driver.clear();
    // vga_text_driver.println("Hello, world!\n", .{});
}
