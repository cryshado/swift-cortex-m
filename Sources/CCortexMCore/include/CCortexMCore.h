#ifndef SWIFT_CORTEX_M_CORE_H
#define SWIFT_CORTEX_M_CORE_H

#include <stdint.h>

static inline void cortex_m_enable_interrupts(void) {
    __asm__ volatile("cpsie i" ::: "memory");
}

static inline void cortex_m_disable_interrupts(void) {
    __asm__ volatile("cpsid i" ::: "memory");
}

static inline uint32_t cortex_m_primask(void) {
    uint32_t primask;
    __asm__ volatile("mrs %0, primask" : "=r"(primask));
    return primask;
}

static inline void cortex_m_restore_primask(uint32_t primask) {
    if (!(primask & 1u)) {
        __asm__ volatile("cpsie i" ::: "memory");
    }
}

static inline void cortex_m_dsb(void) { __asm__ volatile("dsb" ::: "memory"); }

static inline void cortex_m_isb(void) { __asm__ volatile("isb" ::: "memory"); }

static inline void cortex_m_wfi(void) { __asm__ volatile("wfi" ::: "memory"); }

#endif // SWIFT_CORTEX_M_CORE_H
