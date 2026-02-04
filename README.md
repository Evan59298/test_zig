
# STM32F407 Zig Blink (Static Library + C Main)

## Project Structure

```
build.zig               # Build Zig static library
src/main.zig            # Zig library implementation
include/zig_blink.h     # C API header
c_src/startup.c         # C startup + vector table
c_src/main.c            # C main calling Zig library
stm32f407.ld            # Linker script
scripts/build_c.ps1     # C build script (uses Zig lib)
```

## Build (C firmware)

> Requires Zig (0.15+).

```powershell
scripts\build_c.ps1
```

Outputs:
- Static library: `zig-out\lib\libzig_blink.a`
- Header: `zig-out\include\zig_blink.h`
- Firmware: `firmware.elf`, `firmware.bin`

## C Integration

The C entry calls Zig:

```c
#include "zig_blink.h"

int main(void) {
		zig_blink_run();
		while (1) {}
}
```

## Notes

- LED pin: PE5
- USART1: 115200 8N1 on PA9/PA10
- Command: `led period <ms>`
- If your board uses another pin or clock, update GPIO/clock settings in `src/main.zig`.
