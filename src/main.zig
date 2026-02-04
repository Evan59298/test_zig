const std = @import("std");

const Peripheral = struct {
    const RCC_AHB1ENR: *volatile u32 = @ptrFromInt(0x40023830);
    const GPIOE_MODER: *volatile u32 = @ptrFromInt(0x40021000);
    const GPIOE_ODR: *volatile u32 = @ptrFromInt(0x40021014);
};

const ESTACK: u32 = 0x20000000 + 128 * 1024;
extern const _sidata: u32;
extern var _sdata: u32;
extern var _edata: u32;
extern var _sbss: u32;
extern var _ebss: u32;

export fn default_handler() callconv(.c) noreturn {
    while (true) {}
}

comptime {
    asm (
        \\.section .vector_table,"a",%progbits
        \\.word 0x20020000
        \\.word reset_handler
        \\.rept 105
        \\.word default_handler
        \\.endr
        \\.section .text
    );
}

export fn reset_handler() callconv(.c) noreturn {
    var src: *const u32 = &_sidata;
    var dst: *u32 = &_sdata;
    while (@intFromPtr(dst) < @intFromPtr(&_edata)) : (dst = @ptrFromInt(@intFromPtr(dst) + 4)) {
        dst.* = src.*;
        src = @ptrFromInt(@intFromPtr(src) + 4);
    }

    var bss: *u32 = &_sbss;
    while (@intFromPtr(bss) < @intFromPtr(&_ebss)) : (bss = @ptrFromInt(@intFromPtr(bss) + 4)) {
        bss.* = 0;
    }

    main();
}

fn delay(cycles: u32) void {
    var i: u32 = 0;
    while (i < cycles) : (i += 1) {
        asm volatile ("nop");
    }
}

fn main() noreturn {
    // Enable GPIOE clock
    Peripheral.RCC_AHB1ENR.* |= (1 << 4);

    // Set PE5 to output (MODER5 = 01)
    const moder = Peripheral.GPIOE_MODER.*;
    const clear_mask: u32 = ~(@as(u32, 0b11) << (5 * 2));
    const set_mask: u32 = @as(u32, 0b01) << (5 * 2);
    Peripheral.GPIOE_MODER.* = (moder & clear_mask) | set_mask;

    while (true) {
        Peripheral.GPIOE_ODR.* ^= (1 << 5);
        delay(1_000_000);
    }
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = msg;
    _ = error_return_trace;
    _ = ret_addr;
    default_handler();
    unreachable;
}
