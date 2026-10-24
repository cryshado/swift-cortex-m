// memory_layout.h

#ifndef SCMR_MEMORY_LAYOUT_H
#define SCMR_MEMORY_LAYOUT_H

static inline void *scmr_heap_start(void) {
    extern char __heap_start[];
    return __heap_start;
}

static inline void *scmr_heap_end(void) {
    extern char __heap_end[];
    return __heap_end;
}

static inline void *scmr_stack_start(void) {
    extern char _stack_start[];
    return _stack_start;
}

static inline void *scmr_stack_end(void) {
    extern char _stack_end[];
    return _stack_end;
}

#endif // SCMR_MEMORY_LAYOUT_H
