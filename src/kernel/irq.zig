//! This file provides an architecture-independent IRQ handler abstraction.

const arch = @import("../arch/arch.zig");
const std = @import("std");

/// IRQ handler function type
pub const IrqHandlerFn = *const fn (irq_num: u32) void;

/// IRQ controller interface
pub const IrqController = struct {
    /// Enable a specific IRQ
    enableFn: IrqHandlerFn,
    /// Disable a specific IRQ
    disableFn: IrqHandlerFn,
    /// Acknowledge an IRQ (mark it as handled)
    acknowledgeFn: IrqHandlerFn,
    /// Check if an IRQ is pending
    isPendingFn: IrqHandlerFn,

    /// Enable a specific IRQ
    pub fn enable(self: *const IrqController, irq_num: u32) void {
        self.enableFn(irq_num);
    }

    /// Disable a specific IRQ
    pub fn disable(self: *const IrqController, irq_num: u32) void {
        self.disableFn(irq_num);
    }

    /// Acknowledge an IRQ (mark it as handled)
    pub fn acknowledge(self: *const IrqController, irq_num: u32) void {
        self.acknowledgeFn(irq_num);
    }

    /// Check if an IRQ is pending
    pub fn isPending(self: *const IrqController, irq_num: u32) bool {
        return self.isPendingFn(irq_num);
    }
};

/// IRQ handler registry
pub const IrqRegistry = struct {
    /// Maximum number of IRQs supported
    const MAX_IRQS = 256;

    /// IRQ handlers array
    handlers: [MAX_IRQS]?IrqHandlerFn = [_]?IrqHandlerFn{null} ** MAX_IRQS,
    /// IRQ controller
    controller: *const IrqController,

    /// Initialize the IRQ registry
    pub fn init(controller: *const IrqController) IrqRegistry {
        return IrqRegistry{
            .controller = controller,
        };
    }

    /// Register an IRQ handler
    pub fn register(self: *IrqRegistry, irq_num: u32, handler: IrqHandlerFn) bool {
        if (irq_num >= MAX_IRQS) {
            return false;
        }

        self.handlers[irq_num] = handler;
        self.controller.enable(irq_num);
        return true;
    }

    /// Unregister an IRQ handler
    pub fn unregister(self: *IrqRegistry, irq_num: u32) bool {
        if (irq_num >= MAX_IRQS) {
            return false;
        }

        self.handlers[irq_num] = null;
        self.controller.disable(irq_num);
        return true;
    }

    /// Dispatch an IRQ to its handler
    pub fn dispatch(self: *IrqRegistry, irq_num: u32) void {
        if (irq_num < MAX_IRQS) {
            if (self.handlers[irq_num]) |handler| {
                handler(irq_num);
                self.controller.acknowledge(irq_num);
            }
        }
    }
};

/// Global IRQ registry
var global_irq_registry: ?IrqRegistry = null;

/// Initialize the global IRQ registry
pub fn initGlobalRegistry(controller: *const IrqController) void {
    global_irq_registry = IrqRegistry.init(controller);
}

/// Get the global IRQ registry
pub fn getGlobalRegistry() ?*IrqRegistry {
    if (global_irq_registry != null) {
        return &global_irq_registry.?;
    }
    return null;
}

/// Register an IRQ handler in the global registry
pub fn registerHandler(irq_num: u32, handler: IrqHandlerFn) bool {
    if (getGlobalRegistry()) |registry| {
        return registry.register(irq_num, handler);
    }
    return false;
}

/// Unregister an IRQ handler from the global registry
pub fn unregisterHandler(irq_num: u32) bool {
    if (getGlobalRegistry()) |registry| {
        return registry.unregister(irq_num);
    }
    return false;
}

/// Dispatch an IRQ to its handler in the global registry
pub fn dispatchIrq(irq_num: u32) void {
    if (getGlobalRegistry()) |registry| {
        registry.dispatch(irq_num);
    }
}
