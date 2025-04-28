// Interrupt Service Routines (ISR) entry points

.section .text
.code32

// Import the generic C interrupt handler
.extern handle_interrupt

// Common ISR stub that saves registers, calls the C handler, and restores registers
.macro ISR_COMMON_STUB
  // Save registers
  pusha
  push %ds
  push %es
  push %fs
  push %gs

  // Load kernel data segment descriptor
  mov $0x10, %ax // kernel data segment
  mov %ax, %ds
  mov %ax, %es
  mov %ax, %fs
  mov %ax, %gs

  // Call the C handler
  // Current stack: [gs, fs, es, ds, edi, esi, ebp, esp, ebx, edx, ecx, eax, <irq>, <error_code>]
  call handle_interrupt

  // Restore registers
  pop %gs
  pop %fs
  pop %es
  pop %ds
  popa

  // Clean up error code and IRQ number
  add $8, %esp

  // Return from interrupt
  iret
.endm

// Macro for ISRs that don't push an error code
.macro ISR_NOERRCODE index
.global isr_stub_\index
isr_stub_\index:
  push $0 // Push dummy error code
  push $\index // Push interrupt number
  jmp isr_common_stub
.endm

// Macro for ISRs that push an error code
.macro ISR_ERRCODE index
.global isr_stub_\index
isr_stub_\index:
  // Error code already pushed by the CPU
  push $\index // Push interrupt number
  jmp isr_common_stub
.endm

// Common ISR stub implementation
isr_common_stub:
  ISR_COMMON_STUB

// Define ISRs for CPU exceptions (0-31)
ISR_NOERRCODE 0 // Divide by zero
ISR_NOERRCODE 1 // Debug
ISR_NOERRCODE 2 // Non-maskable interrupt
ISR_NOERRCODE 3 // Breakpoint
ISR_NOERRCODE 4 // Overflow
ISR_NOERRCODE 5 // Bound range exceeded
ISR_NOERRCODE 6 // Invalid opcode
ISR_NOERRCODE 7 // Device not available
ISR_ERRCODE   8  // Double fault
ISR_NOERRCODE 9  // Coprocessor segment overrun
ISR_ERRCODE   10   // Invalid TSS
ISR_ERRCODE   11   // Segment not present
ISR_ERRCODE   12   // Stack-segment fault
ISR_ERRCODE   13   // General protection fault
ISR_ERRCODE   14   // Page fault
ISR_NOERRCODE 15   // Reserved
ISR_NOERRCODE 16   // x87 floating-point exception
ISR_ERRCODE   17   // Alignment check
ISR_NOERRCODE 18   // Machine check
ISR_NOERRCODE 19   // SIMD floating-point exception
ISR_NOERRCODE 20   // Virtualization exception
ISR_NOERRCODE 21   // Reserved
ISR_NOERRCODE 22   // Reserved
ISR_NOERRCODE 23   // Reserved
ISR_NOERRCODE 24   // Reserved
ISR_NOERRCODE 25   // Reserved
ISR_NOERRCODE 26   // Reserved
ISR_NOERRCODE 27   // Reserved
ISR_NOERRCODE 28   // Reserved
ISR_NOERRCODE 29   // Reserved
ISR_NOERRCODE 30   // Reserved
ISR_NOERRCODE 31   // Reserved

// Define ISRs for IRQs (32-47)
ISR_NOERRCODE 32   // PIT timer
ISR_NOERRCODE 33   // Keyboard
ISR_NOERRCODE 34   // Cascade for 8259 PIC
ISR_NOERRCODE 35   // COM2
ISR_NOERRCODE 36   // COM1
ISR_NOERRCODE 37   // LPT2
ISR_NOERRCODE 38   // Floppy disk
ISR_NOERRCODE 39   // LPT1 / spurious interrupt
ISR_NOERRCODE 40   // CMOS real-time clock
ISR_NOERRCODE 41   // Peripherals
ISR_NOERRCODE 42   // Peripherals
ISR_NOERRCODE 43   // Peripherals
ISR_NOERRCODE 44   // PS/2 mouse
ISR_NOERRCODE 45   // FPU / coprocessor
ISR_NOERRCODE 46   // Primary ATA hard disk
ISR_NOERRCODE 47   // Secondary ATA hard disk

// Generate additional ISRs (48-255) for other interrupts
.set i, 48
.rept 208
  ISR_NOERRCODE %i
  .set i, i+1
.endr
