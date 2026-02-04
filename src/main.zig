const std = @import("std");

const Peripheral = struct {
    const RCC_AHB1ENR: *volatile u32 = @ptrFromInt(0x40023830);
    const RCC_APB2ENR: *volatile u32 = @ptrFromInt(0x40023844);
    const GPIOA_MODER: *volatile u32 = @ptrFromInt(0x40020000);
    const GPIOA_OSPEEDR: *volatile u32 = @ptrFromInt(0x40020008);
    const GPIOA_AFRH: *volatile u32 = @ptrFromInt(0x40020024);
    const GPIOE_MODER: *volatile u32 = @ptrFromInt(0x40021000);
    const GPIOE_ODR: *volatile u32 = @ptrFromInt(0x40021014);
    const USART1_SR: *volatile u32 = @ptrFromInt(0x40011000);
    const USART1_DR: *volatile u32 = @ptrFromInt(0x40011004);
    const USART1_BRR: *volatile u32 = @ptrFromInt(0x40011008);
    const USART1_CR1: *volatile u32 = @ptrFromInt(0x4001100C);
};

var period_ms: u32 = 2000;
var rx_buf: [64]u8 = undefined;
var rx_len: usize = 0;
var duty: u8 = 0;
var rising: bool = true;

fn delay(cycles: u32) void {
    var i: u32 = 0;
    while (i < cycles) : (i += 1) {
        asm volatile ("nop");
    }
}

fn delay_ms(ms: u32) void {
    var i: u32 = 0;
    while (i < ms) : (i += 1) {
        delay(4000);
    }
}

fn uart_init() void {
    // Enable GPIOA and USART1 clocks
    Peripheral.RCC_AHB1ENR.* |= (1 << 0);
    Peripheral.RCC_APB2ENR.* |= (1 << 4);

    // PA9 (TX) and PA10 (RX) -> AF7
    const moder = Peripheral.GPIOA_MODER.*;
    const clear_mask: u32 = ~((@as(u32, 0b11) << (9 * 2)) | (@as(u32, 0b11) << (10 * 2)));
    const set_mask: u32 = (@as(u32, 0b10) << (9 * 2)) | (@as(u32, 0b10) << (10 * 2));
    Peripheral.GPIOA_MODER.* = (moder & clear_mask) | set_mask;

    const ospeed = Peripheral.GPIOA_OSPEEDR.*;
    const ospeed_mask: u32 = (@as(u32, 0b11) << (9 * 2)) | (@as(u32, 0b11) << (10 * 2));
    Peripheral.GPIOA_OSPEEDR.* = ospeed | ospeed_mask;

    const afrh = Peripheral.GPIOA_AFRH.*;
    const afrh_clear: u32 = ~((@as(u32, 0xF) << ((9 - 8) * 4)) | (@as(u32, 0xF) << ((10 - 8) * 4)));
    const afrh_set: u32 = (@as(u32, 7) << ((9 - 8) * 4)) | (@as(u32, 7) << ((10 - 8) * 4));
    Peripheral.GPIOA_AFRH.* = (afrh & afrh_clear) | afrh_set;

    // USART1 baud (assumes APB2 = 16MHz after reset). Adjust if you change clocks.
    const PCLK2_HZ: u32 = 16_000_000;
    const BAUD: u32 = 115_200;
    const usartdiv_x16: u32 = (PCLK2_HZ + (BAUD / 2)) / BAUD;
    const mantissa: u32 = usartdiv_x16 / 16;
    const fraction: u32 = usartdiv_x16 % 16;
    Peripheral.USART1_BRR.* = (mantissa << 4) | fraction;
    Peripheral.USART1_CR1.* = (1 << 13) | (1 << 3) | (1 << 2);
}

fn uart_write_byte(byte: u8) void {
    while ((Peripheral.USART1_SR.* & (1 << 7)) == 0) {}
    Peripheral.USART1_DR.* = byte;
}

fn uart_write_str(s: []const u8) void {
    for (s) |ch| {
        uart_write_byte(ch);
    }
}

fn uart_try_read_byte() ?u8 {
    if ((Peripheral.USART1_SR.* & (1 << 5)) == 0) return null;
    return @truncate(Peripheral.USART1_DR.*);
}

fn parse_period(line: []const u8) ?u32 {
    if (line.len < 10) return null;
    if (!std.mem.startsWith(u8, line, "led period")) return null;

    var i: usize = 10;
    while (i < line.len and (line[i] == ' ' or line[i] == '=' or line[i] == ':')) : (i += 1) {}
    if (i >= line.len) return null;

    var value: u32 = 0;
    var found = false;
    while (i < line.len) : (i += 1) {
        const c = line[i];
        if (c < '0' or c > '9') break;
        found = true;
        value = value * 10 + @as(u32, c - '0');
    }

    if (!found or value == 0) return null;
    return value;
}

fn pwm_cycle(duty_val: u8) void {
    var i: u16 = 0;
    while (i < 255) : (i += 1) {
        if (i < duty_val) {
            Peripheral.GPIOE_ODR.* |= (1 << 5);
        } else {
            Peripheral.GPIOE_ODR.* &= ~(@as(u32, 1) << 5);
        }
        delay(25);
    }
}

fn led_init() void {
    Peripheral.RCC_AHB1ENR.* |= (1 << 4);
    const moder = Peripheral.GPIOE_MODER.*;
    const clear_mask: u32 = ~(@as(u32, 0b11) << (5 * 2));
    const set_mask: u32 = @as(u32, 0b01) << (5 * 2);
    Peripheral.GPIOE_MODER.* = (moder & clear_mask) | set_mask;
}

export fn zig_blink_init() void {
    led_init();
    uart_init();
    uart_write_str("STM32F407 Zig Breathing LED\r\n");
    uart_write_str("LED: PE5\r\n");
    uart_write_str("USART1: 115200 8N1 (PA9/PA10)\r\n");
    uart_write_str("Cmd: led period <ms>\r\n");
}

export fn zig_blink_set_period(ms: u32) void {
    if (ms > 0) period_ms = ms;
}

fn blink_loop() noreturn {
    while (true) {
        const step_ms = @max(1, period_ms / 512);

        var t: u32 = 0;
        while (t < step_ms) : (t += 1) {
            pwm_cycle(duty);

            if (uart_try_read_byte()) |ch| {
                if (ch == '\r' or ch == '\n') {
                    uart_write_str("\r\n");
                    if (rx_len > 0) {
                        const line = rx_buf[0..rx_len];
                        if (parse_period(line)) |val| {
                            period_ms = val;
                            uart_write_str("OK\r\n");
                        } else {
                            uart_write_str("ERR\r\n");
                        }
                        rx_len = 0;
                    }
                } else if (rx_len < rx_buf.len) {
                    uart_write_byte(ch);
                    rx_buf[rx_len] = ch;
                    rx_len += 1;
                } else {
                    rx_len = 0;
                }
            }
        }

        if (rising) {
            if (duty < 255) {
                duty += 1;
            } else {
                rising = false;
            }
        } else {
            if (duty > 0) {
                duty -= 1;
            } else {
                rising = true;
            }
        }
    }
}

export fn zig_blink_run() noreturn {
    zig_blink_init();
    blink_loop();
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = msg;
    _ = error_return_trace;
    _ = ret_addr;
    while (true) {}
}
