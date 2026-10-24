// vector_exceptions.h

#ifndef SCMR_VECTOR_EXCEPTIONS_H
#define SCMR_VECTOR_EXCEPTIONS_H

typedef void (*SCMRVector)(void);

void scmr_reset(void);            // 1
void NMI_Handler(void);           // 2
void scmr_hardfault_before(void); // 3
void MemManage_Handler(void);     // 4
void BusFault_Handler(void);      // 5
void UsageFault_Handler(void);    // 6
void SecureFault_Handler(void);   // 7
void SVC_Handler(void);           // 11
void DebugMon_Handler(void);      // 12
void PendSV_Handler(void);        // 14
void SysTick_Handler(void);       // 15

#endif // SCMR_VECTOR_EXCEPTIONS_H
