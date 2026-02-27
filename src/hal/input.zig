const gpio = @import("gpio.zig");

pub fn initButtonPd1Pullup() void {
    gpio.enablePortClock(.D);

    const button = gpio.pin(.D, 1);
    button.configure(.input_pull);
    button.write(true);
}

pub fn isButtonPressed() bool {
    return !gpio.pin(.D, 1).read();
}
