const app = @import("app");

pub const ch32fun_ssd1306_basic_ascii_font = if (@hasDecl(app, "ch32fun_ssd1306_basic_ascii_font"))
    app.ch32fun_ssd1306_basic_ascii_font
else
    false;
pub const ch32fun_ssd1306_buffer_mode = if (@hasDecl(app, "ch32fun_ssd1306_buffer_mode"))
    app.ch32fun_ssd1306_buffer_mode
else
    .full;

const startup = @import("runtime/startup_exti.zig");
comptime {
    _ = &startup._start;
}

pub fn main() noreturn {
    app.main();
    while (true) asm volatile ("wfi");
}
