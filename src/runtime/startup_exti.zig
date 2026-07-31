//! Compact CH32V003 reset and direct EXTI runtime.
//!
//! This keeps complete C-style memory initialization but uses unified/direct
//! mtvec for firmware whose only enabled interrupt is EXTI7_0. It deliberately
//! does not enable QingKe HPE because the entry uses software stacking.

const root = @import("root");
const fun = @import("ch32fun");

extern var _sbss: u32;
extern var _ebss: u32;
extern var _sdata: u32;
extern var _edata: u32;
extern var _sidata: u32;
extern var _stack_top: u32;

pub export fn _start() callconv(.naked) noreturn {
    asm volatile (
        \\.option push
        \\.option norelax
        \\la gp, __global_pointer$
        \\.option pop
        \\la sp, _stack_top
        \\la a0, _sbss
        \\la a1, _ebss
        \\1:
        \\bgeu a0, a1, 2f
        \\sw zero, 0(a0)
        \\addi a0, a0, 4
        \\j 1b
        \\2:
        \\la a0, _sidata
        \\la a1, _sdata
        \\la a2, _edata
        \\3:
        \\bgeu a1, a2, 4f
        \\lw a3, 0(a0)
        \\sw a3, 0(a1)
        \\addi a0, a0, 4
        \\addi a1, a1, 4
        \\j 3b
        \\4:
        \\csrw 0x804, zero
        \\li t0, 0x1880
        \\csrw mstatus, t0
        \\la t0, _exti7_0_irq_entry
        \\andi t0, t0, -4
        \\csrw mtvec, t0
        \\j _start_c
    );
}

export fn _start_c() callconv(.c) noreturn {
    root.main();
}

pub export fn _exti7_0_irq_entry() align(4) callconv(.naked) void {
    asm volatile (
        \\addi sp, sp, -64
        \\sw ra, 60(sp)
        \\sw gp, 56(sp)
        \\sw tp, 52(sp)
        \\sw t0, 48(sp)
        \\sw t1, 44(sp)
        \\sw t2, 40(sp)
        \\sw s0, 36(sp)
        \\sw s1, 32(sp)
        \\sw a0, 28(sp)
        \\sw a1, 24(sp)
        \\sw a2, 20(sp)
        \\sw a3, 16(sp)
        \\sw a4, 12(sp)
        \\sw a5, 8(sp)
        \\call _exti7_0_irq_body
        \\lw ra, 60(sp)
        \\lw gp, 56(sp)
        \\lw tp, 52(sp)
        \\lw t0, 48(sp)
        \\lw t1, 44(sp)
        \\lw t2, 40(sp)
        \\lw s0, 36(sp)
        \\lw s1, 32(sp)
        \\lw a0, 28(sp)
        \\lw a1, 24(sp)
        \\lw a2, 20(sp)
        \\lw a3, 16(sp)
        \\lw a4, 12(sp)
        \\lw a5, 8(sp)
        \\addi sp, sp, 64
        \\mret
    );
}

export fn _exti7_0_irq_body() callconv(.c) void {
    fun.exti.handleInterrupt();
}
