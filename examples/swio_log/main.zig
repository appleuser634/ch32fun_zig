//! Debug-only formatted output through SWIO and `minichlink -T`.

const fun = @import("ch32fun");

// Keep SWIO logging while optimizing the firmware to fit in 16 KiB.
pub const ch32fun_swio_log_enabled = true;

pub export fn _start() noreturn {
    main();
}

pub fn main() noreturn {
    fun.system.init(.{});
    fun.swio_log.init();
    fun.swio_log.waitForTerminal();

    fun.swio_log.info("CH32V003 started", .{});
    var counter: u32 = 0;
    while (true) : (counter +%= 1) {
        fun.swio_log.info("counter={d} hex=0x{x}", .{ counter, counter });
        fun.time.delayMs(1000);
    }
}
