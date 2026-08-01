/// Host-test root for the 128-byte SSD1306 page renderer.
pub const ch32fun_ssd1306_buffer_mode = .page;
pub const ch32fun_ssd1306_basic_ascii_font = true;

const ssd1306 = @import("hal/ssd1306.zig");

test {
    _ = &ssd1306.buffer;
}
