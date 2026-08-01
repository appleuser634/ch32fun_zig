//! HC-SR04 超音波距離センサーの測定デモ。
//!
//! 配線:
//!   HC-SR04 TRIG -> PD0
//!   HC-SR04 ECHO -> PD1（5V信号なので抵抗分圧などで3.3V以下にする）
//!   HC-SR04 VCC  -> 5V
//!   HC-SR04 GND  -> GND
//!   UART TX      -> PD5 (115200bps, 8N1)

const fun = @import("ch32fun");

const trigger = fun.gpio.pin(.D, 0);
const echo = fun.gpio.pin(.D, 1);

const MeasureError = error{
    EchoStartTimeout,
    EchoEndTimeout,
};

pub export fn _start() noreturn {
    main();
}

fn waitForEcho(level: bool, timeout_us: u32) ?u32 {
    const started = fun.time.nowCycles();
    while (echo.read() != level) {
        if (fun.time.elapsedUsSince(started) >= timeout_us) return null;
    }
    return fun.time.nowCycles();
}

fn measureDistanceMm() MeasureError!u32 {
    // HC-SR04 requires a trigger pulse of at least 10 us.
    trigger.write(false);
    fun.time.delayUs(2);
    trigger.write(true);
    fun.time.delayUs(10);
    trigger.write(false);

    const pulse_start = waitForEcho(true, 30_000) orelse
        return error.EchoStartTimeout;
    _ = waitForEcho(false, 30_000) orelse
        return error.EchoEndTimeout;

    const pulse_us = fun.time.elapsedUsSince(pulse_start);

    // The round-trip echo duration is approximately 58 us per centimetre.
    return @intCast((@as(u64, pulse_us) * 10 + 29) / 58);
}

pub fn main() noreturn {
    fun.system.init(.{});
    fun.gpio.enableAllClocks();
    fun.log.init(115200);

    trigger.configure(.output_pp_10mhz);
    trigger.write(false);
    echo.configure(.input_floating);

    // Leave the sensor idle after power-up before the first trigger.
    fun.time.delayMs(100);

    while (true) {
        if (measureDistanceMm()) |distance_mm| {
            fun.log.info("distance={d} mm", .{distance_mm});
        } else |err| switch (err) {
            error.EchoStartTimeout => fun.log.warn("timeout waiting for echo", .{}),
            error.EchoEndTimeout => fun.log.warn("echo pulse too long", .{}),
        }

        // HC-SR04 should not be retriggered more often than about every 60 ms.
        fun.time.delayMs(100);
    }
}
