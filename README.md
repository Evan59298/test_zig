# STM32F407 Zig Blink

## Build

> Requires Zig (0.11+), arm-none-eabi GCC (for objcopy), and J-Link tools.

```powershell
zig build
```

Build also emits a BIN at `zig-out\bin\stm32f407-blink.bin`. If you need to regenerate it manually:

```powershell
arm-none-eabi-objcopy -O binary zig-out\bin\stm32f407-blink.elf zig-out\bin\stm32f407-blink.bin
```

## Flash with J-Link

### Option A: J-Link Commander

```powershell
JLink.exe -device STM32F407VG -if SWD -speed 4000 -autoconnect 1
```

In the J-Link console:

```
r
loadfile zig-out\bin\stm32f407-blink.elf
r
g
```

### Option B: J-Link command file

Create a file named `flash.jlink` with:

```
if SWD
speed 4000
device STM32F407VG
r
loadfile zig-out\bin\stm32f407-blink.elf
r
g
q
```

Then run:

```powershell
JLink.exe -CommandFile flash.jlink
```

## Notes

- Default LED pin: PD12 (GPIOD). On STM32F4-Discovery this is the green LED.
- If your board uses another pin, update the GPIO register addresses and pin number in `src/main.zig`.
