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
//*     PURPOSE:   Target Dependent Low-Level Stuff
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


    .set SYS_MODE,  0x1f
    .set SVC_MODE,  0x13
    .set IRQ_MODE,  0x12

    .syntax unified
    .text
    .align 2

    .extern os_context_switch_hook
    .global os_start
    .global context_switch_isr


//------------------------------------------------------------------------------
os_start:

    mov     sp, r0
#if FPU_ENABLE
    pop     {r1}
    vpop    {d16-d31}
    vpop    {d0-d15}
    vmsr    fpscr, r1
#endif
    pop     {r0-r12, r14}
    rfeia   sp!

os_start.end:
//------------------------------------------------------------------------------
context_switch_isr:

    //cpsid   i                            // lock interrupts (if nesting interrupts enabled)
    srsdb   sp!, #SYS_MODE               // save the lr and spsr onto the system mode stack
    cps     #SYS_MODE                    // switch to system mode
    push    {r0-r12, r14}                // save system mode registers

#if FPU_ENABLE                           // floating point context
    fmrx    r1,  fpscr
    vpush   {d0-d15}
    vpush   {d16-d31}
    push    {r1}
#endif

    // switch process stack pointers
    mov     r0, sp                       // pass sp of current process as argument
    ldr     r1, =os_context_switch_hook
    blx     r1

    mov     sp, r0                       // load sp of new (current for now) process

#if FPU_ENABLE                           // floating point context
    pop     {r1}
    vpop    {d16-d31}
    vpop    {d0-d15}
    vmsr    fpscr, r1
#endif

    pop     {r0-r12, r14}                // restore system mode registers

    //cpsie   i                            // unlock ...
    rfeia   sp!                          // return to the process code pointed by lr restoring CPSR

context_switch_isr.end:
//------------------------------------------------------------------------------

