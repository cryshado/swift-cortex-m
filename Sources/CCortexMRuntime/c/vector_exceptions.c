// vector_exceptions.c

#include "vector_exceptions.h"

__attribute__((section(".vector_table.exceptions"), used))
const SCMRVector __EXCEPTIONS[15] = {
    scmr_reset,            // 1.  Reset Handler
    NMI_Handler,           // 2.  NMI Handler
    scmr_hardfault_before, // 3.  (calls HardFault_Handler)
    MemManage_Handler,     // 4.  MPU Fault Handler
    BusFault_Handler,      // 5.  Bus Fault Handler
    UsageFault_Handler,    // 6.  Usage Fault Handler
    SecureFault_Handler,   // 7.  Secure Fault Handler
    0,                     // 8.  reserved
    0,                     // 9.  reserved
    0,                     // 10.  reserved
    SVC_Handler,           // 11. SVC Handler
    DebugMon_Handler,      // 12. Debug Monitor Handler
    0,                     // 13. reserved
    PendSV_Handler,        // 14. PendSV Handler
    SysTick_Handler,       // 15. SysTick Handler
};
