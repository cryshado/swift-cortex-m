INCLUDE memory.x

PROVIDE(_ram_start   = ORIGIN(RAM));
PROVIDE(_ram_end     = ORIGIN(RAM) + LENGTH(RAM));
PROVIDE(_stack_start = _ram_end);

EXTERN(scmr_reset)
EXTERN(__EXCEPTIONS)
EXTERN(__INTERRUPTS)
EXTERN(scmr_default_handler_standard)
EXTERN(scmr_pre_init_standard)

/* ---------- Entry. ----------- */

ENTRY(scmr_reset)

/* --- Overridable handlers. --- */

PROVIDE(Default_Handler     = scmr_default_handler_standard);
PROVIDE(PreInit             = scmr_pre_init_standard);

PROVIDE(NMI_Handler         = Default_Handler);
PROVIDE(HardFault_Handler   = Default_Handler);
PROVIDE(MemManage_Handler   = Default_Handler);
PROVIDE(BusFault_Handler    = Default_Handler);
PROVIDE(UsageFault_Handler  = Default_Handler);
PROVIDE(SecureFault_Handler = Default_Handler);
PROVIDE(SVC_Handler         = Default_Handler);
PROVIDE(DebugMon_Handler    = Default_Handler);
PROVIDE(PendSV_Handler      = Default_Handler);
PROVIDE(SysTick_Handler     = Default_Handler);

/* --------- Sections. --------- */

SECTIONS
{
    .vector_table ORIGIN(FLASH) :
    {
        __vector_table = .;
        LONG(_stack_start & 0xFFFFFFF8);

        __sexceptions = .;
        KEEP(*(.vector_table.exceptions));
        __eexceptions = .;

        __sinterrupts = .;
        KEEP(*(.vector_table.interrupts));
        __einterrupts = .;
    } >FLASH

    .text : ALIGN(4)
    {
        __stext = .;

        *(.scmr_reset);
        *(.scmr_hardfault_before);
        *(.text .text.*);

        . = ALIGN(4);
        __etext = .;
    } >FLASH

    .rodata : ALIGN(4)
    {
        __srodata = .;

        *(.rodata .rodata.*);

        . = ALIGN(4);
        __erodata = .;
    } >FLASH

    /* Debug only unwind info for the scmr_hardfault_before, kept only
       if SCMR_DEBUG_HARDFAULT_UNWIND is set, empty and free otherwise */
    .eh_frame : ALIGN(4)
    {
        KEEP(*(.eh_frame));
    } >FLASH

    .data : ALIGN(4)
    {
        __sdata = .;

        *(.data .data.*);

        . = ALIGN(4);
        __edata = .;
    } >RAM AT >FLASH

    __sidata = LOADADDR(.data);

    .bss (NOLOAD) : ALIGN(4)
        {
        __sbss = .;

        *(.bss .bss.*);
        *(COMMON);

        . = ALIGN(4);
        __ebss = .;
    } >RAM

    .uninit (NOLOAD) : ALIGN(4)
    {
        __suninit = .;

        *(.uninit .uninit.*);

        . = ALIGN(4);
        __euninit = .;
    } >RAM

    .heap (NOLOAD) : ALIGN(8)
    {
        __heap_start = .;

        . = . + _heap_size;

        . = ALIGN(8);
        __heap_end = .;
    } >RAM

    PROVIDE(_stack_end = __heap_end);

    .got (NOLOAD) :
    {
        KEEP(*(.got .got.*));
    } >RAM

    /* Unwind tables + Swift's module hash */
    /DISCARD/ :
    {
        *(.ARM.exidx .ARM.exidx.*);
        *(.ARM.extab .ARM.extab.*);
        *(.swift_modhash*);
    }
}

/* ---------- Checks. ---------- */

ASSERT(ORIGIN(FLASH) % 4 == 0, "
ERROR(cortex-m-runtime): ORIGIN(FLASH) is not 4-byte aligned");

ASSERT(ORIGIN(RAM) % 4 == 0, "
ERROR(cortex-m-runtime): ORIGIN(RAM) is not 4-byte aligned");

ASSERT(__eexceptions - __sexceptions == 15 * 4, "
BUG(cortex-m-runtime): the exception vectors are missing or duplicated");

ASSERT(__einterrupts > __sinterrupts, "
BUG(cortex-m-runtime): the interrupt vectors are missing");

ASSERT(ADDR(.vector_table) % MAX(128, 1 << LOG2CEIL(SIZEOF(.vector_table))) == 0, "
ERROR(cortex-m-runtime): the vector table is misaligned for VTOR, check ORIGIN(FLASH)");

ASSERT(__sdata % 4 == 0 && __edata % 4 == 0, "
BUG(cortex-m-runtime): .data is not 4-byte aligned");

ASSERT(__sidata % 4 == 0, "
BUG(cortex-m-runtime): the load address of .data is not 4-byte aligned");

ASSERT(__sbss % 4 == 0 && __ebss % 4 == 0, "
BUG(cortex-m-runtime): .bss is not 4-byte aligned");

ASSERT(__heap_start % 8 == 0 && __heap_end % 8 == 0, "
BUG(cortex-m-runtime): the heap is not 8-byte aligned");

ASSERT(_stack_start % 8 == 0, "
ERROR(cortex-m-runtime): _stack_start is not 8-byte aligned");

ASSERT(_stack_end % 8 == 0, "
ERROR(cortex-m-runtime): _stack_end is not 8-byte aligned");

ASSERT(_stack_start >= _stack_end, "
ERROR(cortex-m-runtime): no room for the stack; RAM is too small");

ASSERT(_stack_start - _stack_end >= _stack_size, "
ERROR(cortex-m-runtime): less than _stack_size bytes are left for the stack");

ASSERT(SIZEOF(.got) == 0, "
ERROR(cortex-m-runtime): position-independent code detected, compile with -fno-pic");

/* ---- Interrupt handlers. ---- */

INCLUDE device.x
