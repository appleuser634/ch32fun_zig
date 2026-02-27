const regs = @import("../periph/registers.zig");
const gpio = @import("gpio.zig");
const system = @import("../system/system.zig");

pub const Error = error{
    BusyTimeout,
    MasterModeTimeout,
    TxModeTimeout,
    TxEmptyTimeout,
    TxDoneTimeout,
};

const timeout_max: i32 = 100_000;
const bus_clock_hz: u32 = 1_000_000;
const logic_clock_hz: u32 = 2_000_000;

const evt_master_mode_select: u32 = 0x00030001;
const evt_master_tx_selected: u32 = 0x00070082;
const evt_master_byte_transmitted: u32 = 0x00070084;

fn checkEvent(mask: u32) bool {
    const i2c = regs.i2c1();
    const status: u32 = @as(u32, i2c.STAR1) | (@as(u32, i2c.STAR2) << 16);
    return (status & mask) == mask;
}

fn resetAndSetup() void {
    const rcc = regs.rcc();
    const i2c = regs.i2c1();

    rcc.APB1PRSTR |= regs.RCC_APB1_I2C1;
    rcc.APB1PRSTR &= ~regs.RCC_APB1_I2C1;

    var tmp = i2c.CTLR2;
    tmp &= ~regs.I2C_CTLR2_FREQ;
    tmp |= @as(u16, @intCast((system.core_clock_hz / logic_clock_hz) & regs.I2C_CTLR2_FREQ));
    i2c.CTLR2 = tmp;

    var ckcfgr: u16 = @as(u16, @intCast((system.core_clock_hz / (25 * bus_clock_hz)) & regs.I2C_CKCFGR_CCR));
    ckcfgr |= regs.I2C_CKCFGR_DUTY;
    ckcfgr |= regs.I2C_CKCFGR_FS;
    i2c.CKCFGR = ckcfgr;

    i2c.CTLR1 |= regs.I2C_CTLR1_PE;
    i2c.CTLR1 |= regs.I2C_CTLR1_ACK;
}

pub fn initI2c1FastMode() void {
    const rcc = regs.rcc();

    rcc.APB2PCENR |= regs.RCC_APB2_GPIOC;
    rcc.APB1PCENR |= regs.RCC_APB1_I2C1;

    gpio.pin(.C, 1).configure(.output_af_od_10mhz); // SDA
    gpio.pin(.C, 2).configure(.output_af_od_10mhz); // SCL

    resetAndSetup();
}

pub fn writeBlocking7bit(addr: u7, bytes: []const u8) Error!void {
    const i2c = regs.i2c1();

    var timeout: i32 = timeout_max;
    while ((i2c.STAR2 & regs.I2C_STAR2_BUSY) != 0 and timeout > 0) : (timeout -= 1) {}
    if (timeout <= 0) return Error.BusyTimeout;

    i2c.CTLR1 |= regs.I2C_CTLR1_START;

    timeout = timeout_max;
    while (!checkEvent(evt_master_mode_select) and timeout > 0) : (timeout -= 1) {}
    if (timeout <= 0) return Error.MasterModeTimeout;

    i2c.DATAR = @as(u16, addr) << 1;

    timeout = timeout_max;
    while (!checkEvent(evt_master_tx_selected) and timeout > 0) : (timeout -= 1) {}
    if (timeout <= 0) return Error.TxModeTimeout;

    for (bytes) |b| {
        timeout = timeout_max;
        while ((i2c.STAR1 & regs.I2C_STAR1_TXE) == 0 and timeout > 0) : (timeout -= 1) {}
        if (timeout <= 0) return Error.TxEmptyTimeout;

        i2c.DATAR = b;
    }

    timeout = timeout_max;
    while (!checkEvent(evt_master_byte_transmitted) and timeout > 0) : (timeout -= 1) {}
    if (timeout <= 0) return Error.TxDoneTimeout;

    i2c.CTLR1 |= regs.I2C_CTLR1_STOP;
}
