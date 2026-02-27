const regs = @import("../periph/registers.zig");

pub const default_core_clock_hz: u32 = 48_000_000;

pub const Config = struct {
    core_clock_hz: u32 = default_core_clock_hz,
};

pub var core_clock_hz: u32 = default_core_clock_hz;

pub fn init(config: Config) void {
    core_clock_hz = config.core_clock_hz;

    const rcc = regs.rcc();
    const flash = regs.flash();

    // Load factory HSI trim value when available.
    const trim: *volatile u8 = @ptrFromInt(regs.CFG0_PLL_TRIM);
    if (trim.* != 0xFF) {
        const old = rcc.CTLR;
        rcc.CTLR = (old & ~(@as(u32, 0x1F) << 3)) | (@as(u32, trim.* & 0x1F) << 3);
    }

    flash.ACTLR = (flash.ACTLR & ~regs.FLASH_ACTLR_LATENCY_MASK) | regs.FLASH_ACTLR_LATENCY_1;

    // HCLK = SYSCLK, PLL source = HSI, switch SYSCLK to PLL.
    rcc.CFGR0 &= ~(@as(u32, 0x3) | (@as(u32, 0xF) << 4) | (@as(u32, 1) << 16));

    rcc.CTLR |= @as(u32, 1) << 24; // PLLON
    while ((rcc.CTLR & (@as(u32, 1) << 25)) == 0) {}

    rcc.CFGR0 = (rcc.CFGR0 & ~@as(u32, 0x3)) | 0x2; // SW = PLL
    while (((rcc.CFGR0 >> 2) & 0x3) != 0x2) {}
}

pub fn enableInterrupts() void {
    asm volatile ("csrsi mstatus, 0x8");
}

pub fn disableInterrupts() void {
    asm volatile ("csrci mstatus, 0x8");
}

pub fn wfi() void {
    asm volatile ("wfi");
}
