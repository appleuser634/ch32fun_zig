const fun = @import("ch32fun");

pub export fn _start() noreturn {
    main();
}

pub fn main() noreturn {
    fun.system.init(.{});
    fun.gpio.enableAllClocks();

    const led = fun.gpio.pin(.D, 0);
    led.configure(.output_pp_10mhz);

    fun.time.systick.init(1000); // 1ms tick basis

    var last: u64 = 0;
    while (true) {
        const now = fun.time.systick.nowTicks();
        if (now - last >= 500) {
            led.toggle();
            last = now;
        }
    }
}
