// boot.c

#include "boot.h"

#include <stddef.h>
#include <stdint.h>

extern char __vector_table[];
extern char __sbss[], __ebss[];
extern char __sdata[], __edata[], __sidata[];

extern int main(void);

__attribute__((noreturn)) void scmr_boot(void) {
    // Point the core at our vector table using SCB->VTOR
    CORTEX_M_SCB_VTOR = (uintptr_t)__vector_table;

#if defined(__ARM_ARCH_7M__) || defined(__ARM_ARCH_7EM__)
    // 8-byte align the stack on exception entry, as AAPCS handlers assume,
    // only Cortex-M3 r1 resets this to off and elsewhere it is already set
    CORTEX_M_SCB_CCR |= CORTEX_M_CCR_STKALIGN;
#endif

#if defined(__ARM_FP)
    // Enable the FPU, it is off at reset
    CORTEX_M_SCB_CPACR |= CORTEX_M_CPACR_FPU_FULL_ACCESS;

    __asm__ volatile("dsb" ::: "memory");
    __asm__ volatile("isb" ::: "memory");
#endif

    PreInit();

    // Zero .bss, copy .data's initial values from flash into RAM
    __builtin_memset(__sbss, 0, (size_t)(__ebss - __sbss));
    __builtin_memcpy(__sdata, __sidata, (size_t)(__edata - __sdata));

    main();
    __builtin_trap();
}
