const std = @import("std");

export fn _start() void {
    @call(.{}, main, .{});
}

pub fn main() void {
    std.debug.print("Hello, world!\n", .{});
}
