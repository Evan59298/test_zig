$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

$paths = @(
    ".zig-cache",
    "zig-out",
    "build",
    "firmware.elf",
    "firmware.bin"
)

foreach ($p in $paths) {
    if (Test-Path $p) {
        Remove-Item -Force -Recurse $p
    }
}
