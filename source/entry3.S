/*
 * Copyright (c) 2019 Ash Wilding. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 *
 * EL3 firmware entry point.
 * We perform minimal setup before dropping to the hypervisor at EL2.
 */

#include "asm.h"

globalfunc entry3
    // ! Install dummy vector table; each entry branches-to-self
    ADRP    x0, dummy_vectors
    MSR     VBAR_EL3, x0
    // @ adrp shift left 12 bits, lower 12 bits are masked. 
    // @ but "RES0" only 11 bits, not sure what will be happened if masked the "11" bit
    /* 63 62 61 60 59 58 57 56 55 54 53 52 51 50 49 48 47 46 45 44 43 42 41 40 39 38 37 36 35 34 33 32
                                        Vector Base Address
                         Vector Base Address                                     RES0
       31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 | 10 9 8 7 6 5 4 3 2 1 0          */

    //
    // Configure SCR_EL3 // ! configuration of the current Security state
    //
    //   10:10 RW       x1      make EL2 be 64-bit
    //   08:08 HCE      x1      enable HVC instructions (hypervisor call)
    //   05:04 RES1     x3      reserved
    //   00:00 NS       x1      switch to Normal world (lower than EL3 are in Non-secure state)
    //
    //  010100110001 
    // ! w0 : 32 bits register ; x0 : 64 bits register
    MOV     w0, #0x531
    MSR     SCR_EL3, x0

    //
    // Configure SCTLR_EL2
    //
    //   29:28 RES1     x3      reserved    // @ Bit[28] : memory accesses by A32 and T32 load store multiple are marked at stage 1 are not trapped.  Bit[29] : ordering and interrupt behavior of A32 and T32 load store multiple at EL0 is as defined for ARMv8.0
    //   23:22 RES1     x3      reserved    // @ Bit[23] : value of PSTATE.PAN is left unchanged on taking an exception to EL2.  Bit[22] : taking of an exception to EL2 is a context sychronization event.
    //   18:18 RES1     x1      reserved    // @ Set "traps execution of WFE instructions at EL0 to EL2" to not cause any instructions to be trapped. 
    //   16:16 RES1     x1      reserved    // @ not cause any instructions to be trapped by WFI instructions at EL0 to EL2
    //   12:12 I        x0      disable allocation of instrs into unified $s
    //   11:11 RES1     x1      reserved    // @ an exception return from EL2 is a context synchronization event.
    //   05:04 RES1     x3      reserved    // @ EL0 execution of the CP15DMB, CP15DSB, CP15ISB instructions is enabled.
    //   02:02 C        x0      disable allocation of data into data/unified $s
    //   00:00 M        x0      disable MMU
    //
    LDR     w0, =0x30C50830
    MSR     SCTLR_EL2, x0

    //
    // Prepare to drop to EL2h with all asynchronous exceptions masked
    //
    //   09:09 D        x1      Mask debug exceptions
    //   08:08 A        x1      Mask SErrors
    //   07:07 I        x1      Mask IRQs
    //   06:06 F        x1      Mask FIQs
    //   04:04 M[4]     x0      Bits 03:00 define an AArch64 state
    //   03:00 M[3:0]   x9      EL2h
    //
    MOV     w0, #0x3C9
    MSR     SPSR_EL3, x0

    // Drop to hypervisor code
    ADR     x0, entry2
    MSR     ELR_EL3, x0
    ERET
endfunc entry3
