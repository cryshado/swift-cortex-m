// boot.h

#include <stdint.h>

#ifndef SCMR_BOOT_H
#define SCMR_BOOT_H

#define MMIO32(addr) (*(volatile uint32_t *)(addr))

#define CORTEX_M_SCS_BASE 0xE000E000u
#define CORTEX_M_SCB_BASE (CORTEX_M_SCS_BASE + 0xD00u)

// Vector Table Offset Register
#define CORTEX_M_SCB_VTOR MMIO32(CORTEX_M_SCB_BASE + 0x08u)

// Coprocessor Access Control Register
#define CORTEX_M_SCB_CPACR MMIO32(CORTEX_M_SCB_BASE + 0x88u)
#define CORTEX_M_CPACR_FPU_FULL_ACCESS (0xFu << 20)

// Configuration and Control Register
#define CORTEX_M_SCB_CCR MMIO32(CORTEX_M_SCB_BASE + 0x14u)
#define CORTEX_M_CCR_STKALIGN (1u << 9)

void PreInit(void);
__attribute__((noreturn)) void scmr_boot(void);

#endif // SCMR_BOOT_H
