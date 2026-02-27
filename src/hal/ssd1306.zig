const i2c = @import("i2c.zig");
const font = @import("font8x8.zig");

pub const width: u8 = 128;
pub const height: u8 = 64;
const width_us: usize = width;
const height_us: usize = height;
const packet_size: usize = 32;
const i2c_addr: u7 = 0x3c;

pub const Error = i2c.Error;

pub const DrawMode = enum {
    normal,
    invert,
    and_mode,
    or_mode,
    or_invert,
    and_invert,
};

pub const FontSize = enum(u8) {
    x1 = 1,
    x2 = 2,
    x4 = 4,
    x8 = 8,
};

pub var buffer: [width_us * height_us / 8]u8 = [_]u8{0} ** (width_us * height_us / 8);

const init_commands = [_]u8{
    0xAE,
    0xD5,
    0x80,
    0xA8,
    0x3F,
    0xD3,
    0x00,
    0x40,
    0x8D,
    0x14,
    0x20,
    0x00,
    0xA1,
    0xC8,
    0xDA,
    0x12,
    0x81,
    0xCF,
    0xD9,
    0xF1,
    0xDB,
    0x40,
    0xA4,
    0xA6,
    0xAF,
};

fn cmd(command: u8) Error!void {
    var pkt = [_]u8{ 0x00, command };
    try i2c.writeBlocking7bit(i2c_addr, pkt[0..]);
}

fn data(chunk: []const u8) Error!void {
    var pkt: [packet_size + 1]u8 = undefined;
    pkt[0] = 0x40;
    @memcpy(pkt[1 .. 1 + chunk.len], chunk);
    try i2c.writeBlocking7bit(i2c_addr, pkt[0 .. 1 + chunk.len]);
}

pub fn initI2c() !void {
    i2c.initI2c1FastMode();
}

pub fn initPanel() !void {
    for (init_commands) |c| {
        try cmd(c);
    }
    setbuf(false);
    try refresh();
}

pub fn setbuf(color: bool) void {
    @memset(&buffer, if (color) 0xFF else 0x00);
}

pub fn refresh() !void {
    try cmd(0x21);
    try cmd(0);
    try cmd(width - 1);

    try cmd(0x22);
    try cmd(0);
    try cmd(7);

    var i: usize = 0;
    while (i < buffer.len) : (i += packet_size) {
        const end = @min(i + packet_size, buffer.len);
        try data(buffer[i..end]);
    }
}

pub fn drawPixel(x: i16, y: i16, color: bool) void {
    if (x < 0 or y < 0) return;
    if (x >= width or y >= height) return;

    const xu: usize = @intCast(x);
    const yu: usize = @intCast(y);
    const addr = xu + @as(usize, width) * (yu / 8);
    const mask: u8 = @as(u8, 1) << @as(u3, @intCast(yu & 7));

    if (color) {
        buffer[addr] |= mask;
    } else {
        buffer[addr] &= ~mask;
    }
}

pub fn drawImage(x: i16, y: i16, input: []const u8, w: u8, h: u8, mode: DrawMode) void {
    if (w < 8) return;
    const bytes_per_row: usize = @intCast(w / 8);

    var line: usize = 0;
    while (line < h) : (line += 1) {
        const y_abs = y + @as(i16, @intCast(line));
        if (y_abs < 0) continue;
        if (y_abs >= height) break;

        const yu: usize = @intCast(y_abs);
        const vmask: u8 = @as(u8, 1) << @as(u3, @intCast(yu & 7));

        var byte: usize = 0;
        while (byte < bytes_per_row) : (byte += 1) {
            const input_byte = input[byte + line * bytes_per_row];

            var pixel: usize = 0;
            while (pixel < 8) : (pixel += 1) {
                const x_abs = x + @as(i16, @intCast(8 * (bytes_per_row - byte) + pixel));
                if (x_abs < 0) continue;
                if (x_abs >= width) break;

                const xu: usize = @intCast(x_abs);
                const addr = xu + @as(usize, width) * (yu / 8);
                const src_on = (input_byte & (@as(u8, 1) << @as(u3, @intCast(pixel)))) != 0;
                const dst_on = (buffer[addr] & vmask) != 0;

                const out_on = switch (mode) {
                    .normal => src_on,
                    .invert => !src_on,
                    .and_mode => dst_on and src_on,
                    .or_mode => dst_on or src_on,
                    .or_invert => dst_on or !src_on,
                    .and_invert => dst_on and !src_on,
                };

                if (out_on) {
                    buffer[addr] |= vmask;
                } else {
                    buffer[addr] &= ~vmask;
                }
            }
        }
    }
}

pub fn drawCharSz(x: i16, y: i16, chr: u8, color: bool, font_size: FontSize) void {
    const scale: u8 = @intFromEnum(font_size);

    var row: usize = 0;
    while (row < 8) : (row += 1) {
        const glyph_base = (@as(usize, chr) << 3);
        var d: u8 = font.fontdata[glyph_base + row];

        var col: usize = 0;
        while (col < 8) : (col += 1) {
            const pixel_on = if ((d & 0x80) != 0) color else !color;

            var k: u8 = 0;
            while (k < scale) : (k += 1) {
                var l: u8 = 0;
                while (l < scale) : (l += 1) {
                    drawPixel(
                        x + @as(i16, @intCast(col * scale + k)),
                        y + @as(i16, @intCast(row * scale + l)),
                        pixel_on,
                    );
                }
            }

            d <<= 1;
        }
    }
}

pub fn drawStrSz(x_start: i16, y: i16, text: []const u8, color: bool, font_size: FontSize) void {
    var x = x_start;
    const step: i16 = @as(i16, 8) * @as(i16, @intCast(@intFromEnum(font_size)));

    for (text) |c| {
        drawCharSz(x, y, c, color, font_size);
        x += step;
        if (x > @as(i16, width) - step) break;
    }
}
