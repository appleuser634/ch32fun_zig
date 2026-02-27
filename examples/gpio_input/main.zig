const fun = @import("ch32fun");

pub export fn _start() noreturn {
    main();
}

pub fn main() noreturn {
    fun.system.init(.{});
    fun.gpio.enableAllClocks();

    const led = fun.gpio.pin(.D, 0);
    const button = fun.gpio.pin(.D, 3);

    led.configure(.output_pp_10mhz);
    button.configure(.input_pull);
    button.write(true); // pull-up

    while (true) {
        // Active-low button behavior.
        led.write(!button.read());
    }
}
