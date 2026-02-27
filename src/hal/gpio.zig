const regs = @import("../periph/registers.zig");

pub const Port = enum {
    A,
    C,
    D,
};

pub const Mode = enum(u4) {
    input_analog = 0,
    input_floating = 4,
    input_pull = 8,
    output_pp_10mhz = 1,
    output_pp_2mhz = 2,
    output_pp_30mhz = 3,
    output_od_10mhz = 5,
    output_od_2mhz = 6,
    output_od_30mhz = 7,
    output_af_pp_10mhz = 9,
    output_af_pp_2mhz = 10,
    output_af_pp_30mhz = 11,
    output_af_od_10mhz = 13,
    output_af_od_2mhz = 14,
    output_af_od_30mhz = 15,
};

pub const Pin = struct {
    port: Port,
    index: u4,

    pub fn configure(self: Pin, mode: Mode) void {
        const g = self.gpio();
        const shift: u5 = @as(u5, self.index) * 4;
        const mask: u32 = @as(u32, 0xF) << shift;
        const value: u32 = @as(u32, @intFromEnum(mode)) << shift;

        g.CFGLR = (g.CFGLR & ~mask) | value;
    }

    pub fn write(self: Pin, value: bool) void {
        const g = self.gpio();
        const bit: u32 = @as(u32, 1) << self.index;

        if (value) {
            g.BSHR = bit;
        } else {
            g.BSHR = bit << 16;
        }
    }

    pub fn toggle(self: Pin) void {
        self.write(!self.readOut());
    }

    pub fn read(self: Pin) bool {
        const g = self.gpio();
        return ((g.INDR >> self.index) & 0x1) != 0;
    }

    pub fn readOut(self: Pin) bool {
        const g = self.gpio();
        return ((g.OUTDR >> self.index) & 0x1) != 0;
    }

    fn gpio(self: Pin) *volatile regs.GpioRegs {
        return switch (self.port) {
            .A => regs.gpioA(),
            .C => regs.gpioC(),
            .D => regs.gpioD(),
        };
    }
};

pub fn pin(comptime port: Port, comptime n: u4) Pin {
    return .{ .port = port, .index = n };
}

pub fn enablePortClock(port: Port) void {
    const rcc = regs.rcc();
    switch (port) {
        .A => rcc.APB2PCENR |= regs.RCC_APB2_GPIOA,
        .C => rcc.APB2PCENR |= regs.RCC_APB2_GPIOC,
        .D => rcc.APB2PCENR |= regs.RCC_APB2_GPIOD,
    }
}

pub fn enableAllClocks() void {
    const rcc = regs.rcc();
    rcc.APB2PCENR |= regs.RCC_APB2_AFIO | regs.RCC_APB2_GPIOA | regs.RCC_APB2_GPIOC | regs.RCC_APB2_GPIOD;
}
