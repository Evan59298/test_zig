#include <stdint.h>

extern int main(void);
extern void zig_blink_run(void);

void Reset_Handler(void);
void Default_Handler(void);

extern uint32_t _sidata;
extern uint32_t _sdata;
extern uint32_t _edata;
extern uint32_t _sbss;
extern uint32_t _ebss;

__attribute__((section(".vector_table")))
void (* const g_pfnVectors[])(void) = {
    (void (*)(void))0x20020000,
    Reset_Handler,
    Default_Handler,
    Default_Handler,
    Default_Handler,
    Default_Handler,
    Default_Handler,
    0,
    0,
    0,
    0,
    Default_Handler,
    Default_Handler,
    0,
    Default_Handler,
    Default_Handler,
};

void Default_Handler(void) {
    while (1) {}
}

void __aeabi_unwind_cpp_pr0(void) {}
void __aeabi_unwind_cpp_pr1(void) {}

void Reset_Handler(void) {
    uint32_t *src = &_sidata;
    uint32_t *dst = &_sdata;
    while (dst < &_edata) {
        *dst++ = *src++;
    }
    dst = &_sbss;
    while (dst < &_ebss) {
        *dst++ = 0;
    }

    (void)main();
    zig_blink_run();
    while (1) {}
}
