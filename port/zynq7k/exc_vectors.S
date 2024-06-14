//******************************************************************************
//*
//*     FULLNAME:  Single-Chip Microcontroller Real-Time Operating System
//*
//*     NICKNAME:  scmRTOS
//*
//*     PROCESSOR: ARM Cortex-A9
//*
//*     TOOLKIT:   ARM GCC
//*
//*     PURPOSE:   Exception handlers
//*
//*     Version: v5.2.0
//*
//*
//*     Copyright (c) 2003-2021, scmRTOS Team
//*
//*     Permission is hereby granted, free of charge, to any person
//*     obtaining  a copy of this software and associated documentation
//*     files (the "Software"), to deal in the Software without restriction,
//*     including without limitation the rights to use, copy, modify, merge,
//*     publish, distribute, sublicense, and/or sell copies of the Software,
//*     and to permit persons to whom the Software is furnished to do so,
//*     subject to the following conditions:
//*
//*     The above copyright notice and this permission notice shall be included
//*     in all copies or substantial portions of the Software.
//*
//*     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//*     EXPRESS  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//*     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//*     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//*     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//*     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH
//*     THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//*
//*     =================================================================
//*     Project sources: https://github.com/scmrtos/scmrtos
//*     Documentation:   https://github.com/scmrtos/scmrtos/wiki/Documentation
//*     Wiki:            https://github.com/scmrtos/scmrtos/wiki
//*     Sample projects: https://github.com/scmrtos/scmrtos-sample-projects
//*     =================================================================
//*
//******************************************************************************
//*     Cortex-A9 GCC port by Harry E. Zhurov, Copyright (c) 2024

//------------------------------------------------------------------------------

    .extern irq_handler
    .extern context_switch_isr
    .global __vector_table

    .org 0
    .text

//------------------------------------------------------------------------------
.section .vectors
__vector_table:
    b       __start
    b       undefined
    b       context_switch_isr               // SVCHandler
    b       prefetch_abort
    b       data_abort
    nop                                      // Placeholder for address exception vector
    b       irq

.section .exhandlers
    // FIQ exception handler
    // do nothing for now
    nop
    subs    pc, lr, #4                   // return from FIQ

//------------------------------------------------------------------------------
irq:

    stmdb   sp!,{r0-r3,r12,lr}

#if FPU_ENABLE                        // save FPU context
    vpush   {d0-d7}
    vpush   {d16-d31}
    vmrs     r1, fpscr
    push    {r1}
    vmrs     r1, fpexc
    push    {r1}
#endif

    bl      irq_handler

#if FPU_ENABLE                        // restore FPU context
    pop     {r1}
    vmsr    fpexc, r1
    pop     {r1}
    vmsr    fpscr, r1
    vpop    {d16-d31}
    vpop    {d0-d7}
#endif

    ldmia   sp!,{r0-r3,r12,lr}

    subs    pc, lr, #4
//------------------------------------------------------------------------------
undefined:
    stmdb   sp!,{r0-r3,r12,lr}
    ldr     r0, =undefined_exception_addr
    sub     r1, lr, #4
    str     r1, [r0]                  // store address of instruction causing undefined exception

    bl      undefined_exception
    ldmia   sp!,{r0-r3,r12,lr}
    movs    pc, lr
//------------------------------------------------------------------------------
data_abort:
    dsb                               // ARM ERRATA 775420: data cache maintenance operation which aborts, might lead to deadlock

    stmdb   sp!,{r0-r3,r12,lr}
    ldr     r0, =data_abort_addr
    sub     r1, lr, #8
    str     r1, [r0]                  // stores instruction causing data abort

    bl      data_abort_exception

    ldmia   sp!,{r0-r3,r12,lr}

    subs    pc, lr, #8                // LR adjustment for Data Abort: points to the instruction that caused the exception
//------------------------------------------------------------------------------
prefetch_abort:
    dsb                               // ARM ERRATA 775420: data cache maintenance operation which aborts, might lead to deadlock

    stmdb   sp!,{r0-r3,r12,lr}
    ldr     r0, =prefetch_abort_addr
    sub     r1, lr, #4
    str     r1, [r0]                  // stores instruction causing prefetch abort

    bl      prefetch_abort_exception

    ldmia   sp!,{r0-r3,r12,lr}

    subs    pc, lr, #4                // LR adjustment for Prefetch Abort: points to the instruction that caused the exception
//------------------------------------------------------------------------------

.end
//------------------------------------------------------------------------------

