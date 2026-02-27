const fun = @import("ch32fun");
const assets = @import("assets.zig");

pub export fn _start() noreturn {
    main();
}

pub fn main() noreturn {
    fun.system.init(.{});
    fun.time.systick.init(1000);
    fun.input.initButtonPd1Pullup();

    fun.ssd1306.initI2c() catch unreachable;
    fun.ssd1306.initPanel() catch unreachable;

    var x: i16 = 0;
    var dx: i16 = 1;
    var fast_mode = false;
    var prev_button = false;

    while (true) {
        const pressed = fun.input.isButtonPressed();
        if (pressed and !prev_button) {
            fast_mode = !fast_mode;
        }
        prev_button = pressed;

        fun.ssd1306.setbuf(false);
        fun.ssd1306.drawStrSz(0, 0, "OLED DEMO", true, .x1);
        fun.ssd1306.drawStrSz(0, 10, if (fast_mode) "SPD:FAST" else "SPD:SLOW", true, .x1);
        fun.ssd1306.drawImage(x, 32, &assets.sprite_demo, 8, 8, .normal);
        fun.ssd1306.refresh() catch unreachable;

        x += dx;
        if (x <= 0) dx = 1;
        if (x >= 120) dx = -1; // 128 - sprite width (8)

        fun.time.delayMs(if (fast_mode) 12 else 35);
    }
}
