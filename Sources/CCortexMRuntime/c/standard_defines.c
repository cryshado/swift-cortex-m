// standard_defines.c

__attribute__((used)) void scmr_pre_init_standard(void) {}

__attribute__((used, noreturn)) void scmr_default_handler_standard(void) {
    for (;;) {
        __asm__ volatile("wfi");
    }
}
