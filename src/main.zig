const std = @import("std");
const kernel = @import("kernel/scheduler.zig");

pub fn main() !void {
    try kernel.initialize();
    try kernel.startScheduler();
}
