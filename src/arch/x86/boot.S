/* Multiboot header definitions */
#define MULTIBOOT_ALIGN 1<<0
#define MULTIBOOT_MEMINFO 1<<1
#define MULTIBOOT_MAGIC 0x1BADB002
#define MULTIBOOT_FLAGS (MULTIBOOT_ALIGN | MULTIBOOT_MEMINFO)

/* Create a simple boot stack */
.section .bss
.align 16
stack_bottom:
.skip 16384 /* 16 KiB */
stack_top:

/* Multiboot header section */
.section .text
.global _start
.type _start, @function

_start:
 /* Set up the stack */
    movl $stack_top, %esp

    /* Reset EFLAGS */
    pushl $0
    popf

    /* Push multiboot info and magic value onto the stack */
    pushl %ebx    /* Multiboot info structure pointer */
    pushl %eax    /* Should contain MULTIBOOT_MAGIC */

    /* Call the kernel main function */
    call kmain

    /* Halt if main returns */
hang:
    cli
    hlt
    jmp hang

/* Set the size of _start */
.size _start, . - _start
