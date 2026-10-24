// hardfault_before.S

.syntax unified

#ifdef SCMR_DEBUG_HARDFAULT_UNWIND
.cfi_sections .eh_frame
#else
.cfi_sections .debug_frame
#endif

.section .scmr_hardfault_before, "ax", %progbits
.global scmr_hardfault_before
.type scmr_hardfault_before, %function
.thumb_func
.balign 2

scmr_hardfault_before:
    .cfi_startproc
#ifdef SCMR_DEBUG_HARDFAULT_UNWIND
    .cfi_signal_frame

    .cfi_escape 0x0f, 0x0c, 0x7d, 0x1c, 0x06, 0x39, 0x25, 0x31, 0x1a, 0x32, 0x24, 0x7d, 0x20, 0x22

    .cfi_escape 0x10, 0x00, 0x02, 0x7d, 0x00 // r0     at [sp+0]
    .cfi_escape 0x10, 0x01, 0x02, 0x7d, 0x04 // r1     at [sp+4]
    .cfi_escape 0x10, 0x02, 0x02, 0x7d, 0x08 // r2     at [sp+8]
    .cfi_escape 0x10, 0x03, 0x02, 0x7d, 0x0c // r3     at [sp+12]
    .cfi_escape 0x10, 0x0c, 0x02, 0x7d, 0x10 // r12    at [sp+16]
    .cfi_escape 0x10, 0x0e, 0x02, 0x7d, 0x18 // lr(RA) at [sp+24] = faulting pc
#else
    .cfi_undefined lr
#endif
    mov   r0, lr
    movs  r1, #4

    tst   r0, r1
    ldr   r1, =HardFault_Handler
    beq   0f

    mrs   r0, psp
    bx    r1
0:
    mrs   r0, msp
    bx    r1

    .cfi_endproc
    .size scmr_hardfault_before, . - scmr_hardfault_before
