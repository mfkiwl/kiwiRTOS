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

const std = @import("std");
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
            vga_text_driver.println("Hello, {s} world!", .{"red"});
        } else {
            vga_text_driver.setColor(drivers.vga.VgaTextColor.new(.LIGHT_GREEN, .BLACK));
            vga_text_driver.println("Hello, {s} world!", .{"green"});
        }
        i += 1;
    }
    vga_text_driver.scroll();
    vga_text_driver.println("{c}", .{'a'}); // a
    vga_text_driver.println("{c}", .{'Q'}); // Q
    vga_text_driver.println("{c}", .{@as(u8, @truncate(256 + '9'))}); // 9
    vga_text_driver.println("{s}", .{"test string"}); // test string
    vga_text_driver.println("foo{s}bar", .{"blah"}); // fooblahbar
    vga_text_driver.println("{d}", .{@as(i32, std.math.minInt(i32))}); // -2147483648
    vga_text_driver.println("{d}", .{std.math.maxInt(i32)}); // 2147483647
    // vga_text_driver.println("{u}", .{@as(u32, 0)}); // 0
    // vga_text_driver.println("{d}", .{std.math.maxInt(u32)}); // 4294967295
    // vga_text_driver.println("{x}", .{0xDEADbeef}); // deadbeef
    // vga_text_driver.println("{p}", .{@as([*]u8, @ptrFromInt(std.math.maxInt(usize)))}); // 0xFFFFFFFFFFFFFFFF on x86_64
    // vga_text_driver.println("{hd}", .{@as(i16, -32768)}); // -32768
    // vga_text_driver.println("{hd}", .{@as(i16, 32767)}); // 32767
    // vga_text_driver.println("{hu}", .{@as(u16, 65535)}); // 65535
    // vga_text_driver.println("{ld}", .{std.math.minInt(isize)}); // -9223372036854775808 on x86_64
    // vga_text_driver.println("{ld}", .{std.math.maxInt(isize)}); // 9223372036854775807
    // vga_text_driver.println("{lu}", .{std.math.maxInt(usize)}); // 18446744073709551615
    // // %qd and %qu are treated like long long in C; Zig ignores the 'q' modifier:
    // vga_text_driver.println("{qd}", .{std.math.minInt(i64)}); // -9223372036854775808
    // vga_text_driver.println("{qd}", .{std.math.maxInt(i64)}); // 9223372036854775807
    // vga_text_driver.println("{qu}", .{std.math.maxInt(u64)}); // 18446744073709551615
}
