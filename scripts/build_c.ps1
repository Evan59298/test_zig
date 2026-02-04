$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

if (!(Test-Path build)) { New-Item -ItemType Directory build | Out-Null }
if (!(Test-Path build\c_src)) { New-Item -ItemType Directory build\c_src | Out-Null }

zig build

$zig = "zig"

$common = @(
	"cc",
	"-target",
	"thumb-freestanding-eabi",
	"-mcpu=cortex_m4",
	"-O2",
	"-ffreestanding",
	"-fno-builtin",
	"-nostdlib",
	"-Wall",
	"-Wextra",
	"-Izig-out\\include",
	"-Iinclude",
	"-Ic_src"
)

& $zig @common "-c" "c_src\\startup.c" "-o" "build\\c_src\\startup.o"
& $zig @common "-c" "c_src\\main.c" "-o" "build\\c_src\\main.o"

$link_args = @(
	"cc",
	"-target",
	"thumb-freestanding-eabi",
	"-mcpu=cortex_m4",
	"-O2",
	"-ffreestanding",
	"-fno-builtin",
	"-nostdlib",
	"-Wall",
	"-Wextra",
	"build\\c_src\\startup.o",
	"build\\c_src\\main.o",
	"zig-out\\lib\\libzig_blink.a",
	"-T",
	"stm32f407.ld",
	"-nostdlib",
	"-Wl,--gc-sections",
	"-Wl,-e,Reset_Handler",
	"-o",
	"firmware.elf"
)

& $zig @link_args

& $zig "objcopy" "-O" "binary" "firmware.elf" "firmware.bin"
