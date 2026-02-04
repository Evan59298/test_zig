#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void zig_blink_init(void);
void zig_blink_run(void); /* never returns */
void zig_blink_set_period(uint32_t ms);

#ifdef __cplusplus
}
#endif
