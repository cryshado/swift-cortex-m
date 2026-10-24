// vector_interrupts.S

#ifndef SCMR_IRQ_COUNT
#error "SCMR_IRQ_COUNT is not defined."
#endif

.syntax unified
.altmacro

.macro scmr_irq_vector n
    .word IRQ\n\()_Handler
.endm

.section .vector_table.interrupts, "a", %progbits
.balign 4
.global __INTERRUPTS
.type __INTERRUPTS, %object

__INTERRUPTS:
    .set scmr_irq, 0

    .rept SCMR_IRQ_COUNT
        scmr_irq_vector %scmr_irq
        .set scmr_irq, scmr_irq + 1
    .endr

    .size __INTERRUPTS, . - __INTERRUPTS
