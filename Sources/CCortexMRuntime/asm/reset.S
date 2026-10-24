// reset.S

.syntax unified
.cfi_sections .debug_frame

.section .scmr_reset, "ax", %progbits
.global scmr_reset
.type scmr_reset, %function
.thumb_func
.balign 2

scmr_reset:
    .cfi_startproc
    .cfi_undefined lr

    ldr   r0, =_stack_start
    msr   msp, r0

    ldr   r1, =scmr_boot
    bx    r1

    .cfi_endproc
    .size scmr_reset, . - scmr_reset
