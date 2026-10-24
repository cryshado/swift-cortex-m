// CCortexMRuntime.h

#ifndef SCMR_C_CORTEX_M_RUNTIME_H
#define SCMR_C_CORTEX_M_RUNTIME_H

#if !(defined(__ARM_ARCH_6M__) || defined(__ARM_ARCH_7M__) ||                  \
      defined(__ARM_ARCH_7EM__) || defined(__ARM_ARCH_8M_BASE__) ||            \
      defined(__ARM_ARCH_8M_MAIN__) || defined(__ARM_ARCH_8_1M_MAIN__))
#error "CortexMRuntime only builds for Cortex-M"
#endif

#include <stdint.h>

#include "memory_layout.h"

typedef struct {
    uint32_t r0;
    uint32_t r1;
    uint32_t r2;
    uint32_t r3;
    uint32_t r12;
    uint32_t lr;
    uint32_t pc;
    uint32_t xpsr;
} SCMRExceptionFrame;

#endif // SCMR_C_CORTEX_M_RUNTIME_H
