const std = @import("std");

fn generate_handle(comptime num: u8) fn () callconv(.Naked) void {
    const error_code_list = [_]u8{ 8, 10, 11, 12, 13, 14, 17, 21, 29, 30 };
    const public = std.fmt.comptimePrint(
        \\     push ${}
        \\     push %rax
        \\     push %rbx
        \\     push %rcx
        \\     push %rdx
        \\     push %rsp
        \\     push %rbp
        \\     push %rsi
        \\     push %rdi
        \\     push %r8
        \\     push %r9
        \\     push %r10
        \\     push %r11
        \\     push %r12
        \\     push %r13
        \\     push %r14
        \\     push %r15
        \\     mov %rsp, context
    , .{num});
    const save_status = if (for (error_code_list) |value| {
        if (value == num) {
            break true;
        }
    } else false)
        public
    else
        \\     push $0b10000000000000000
        \\
        // Note: the Line breaks are very important
    ++
        public;
    const restore_status =
        \\     mov context, %rsp
        \\     pop %r15
        \\     pop %r14
        \\     pop %r13
        \\     pop %r12
        \\     pop %r11
        \\     pop %r10
        \\     pop %r9
        \\     pop %r8
        \\     pop %rdi
        \\     pop %rsi
        \\     pop %rbp
        \\     pop %rsp
        \\     pop %rdx
        \\     pop %rcx
        \\     pop %rbx
        \\     pop %rax
        \\     add $16, %rsp
        \\     iretq
    ;
    return struct {
        fn handle() callconv(.Naked) void {
            asm volatile (save_status ::: "memory");
            // interruptDispatch just is a higher level interrupt handling function
            asm volatile ("call interruptDispatch");
            asm volatile (restore_status ::: "memory");
        }
    }.handle;
}
