const app = @import("app");

// HAL modules use declarations on the executable root for compile-time
// configuration. Forward the supported settings from the application module.
pub const ch32fun_ssd1306_basic_ascii_font = if (@hasDecl(app, "ch32fun_ssd1306_basic_ascii_font"))
    app.ch32fun_ssd1306_basic_ascii_font
else
    false;

// Importing this module emits _start, the vector table and IRQ entries.
const startup = @import("runtime/startup.zig");
comptime {
    _ = &startup._start;
    _ = &startup.vector_table;
}

pub fn main() noreturn {
    app.main();
    while (true) asm volatile ("wfi");
}
