pub const FLASH_BASE: usize = 0x08000000;
pub const SRAM_BASE: usize = 0x20000000;
pub const PERIPH_BASE: usize = 0x40000000;
pub const CORE_PERIPH_BASE: usize = 0xE0000000;

pub const APB2PERIPH_BASE: usize = PERIPH_BASE + 0x10000;
pub const APB1PERIPH_BASE: usize = PERIPH_BASE;
pub const AHBPERIPH_BASE: usize = PERIPH_BASE + 0x20000;

pub const GPIOA_BASE: usize = APB2PERIPH_BASE + 0x0800;
pub const GPIOC_BASE: usize = APB2PERIPH_BASE + 0x1000;
pub const GPIOD_BASE: usize = APB2PERIPH_BASE + 0x1400;
pub const I2C1_BASE: usize = APB1PERIPH_BASE + 0x5400;

pub const RCC_BASE: usize = AHBPERIPH_BASE + 0x1000;
pub const FLASH_R_BASE: usize = AHBPERIPH_BASE + 0x2000;

pub const PFIC_BASE: usize = CORE_PERIPH_BASE + 0xE000;
pub const SYSTICK_BASE: usize = CORE_PERIPH_BASE + 0xF000;

pub const CFG0_PLL_TRIM: usize = 0x1FFFF7D4;

pub const SYSTICK_CTLR_STE: u32 = 1 << 0;
pub const SYSTICK_CTLR_STIE: u32 = 1 << 1;
pub const SYSTICK_CTLR_STCLK: u32 = 1 << 2;

pub const RCC_APB2_AFIO: u32 = 0x00000001;
pub const RCC_APB2_GPIOA: u32 = 0x00000004;
pub const RCC_APB2_GPIOC: u32 = 0x00000010;
pub const RCC_APB2_GPIOD: u32 = 0x00000020;
pub const RCC_APB1_I2C1: u32 = 0x00200000;

pub const I2C_CTLR1_PE: u16 = 0x0001;
pub const I2C_CTLR1_START: u16 = 0x0100;
pub const I2C_CTLR1_STOP: u16 = 0x0200;
pub const I2C_CTLR1_ACK: u16 = 0x0400;

pub const I2C_CTLR2_FREQ: u16 = 0x003F;

pub const I2C_STAR1_TXE: u16 = 0x0080;
pub const I2C_STAR2_BUSY: u16 = 0x0002;

pub const I2C_CKCFGR_CCR: u16 = 0x0FFF;
pub const I2C_CKCFGR_DUTY: u16 = 0x4000;
pub const I2C_CKCFGR_FS: u16 = 0x8000;

pub const FLASH_ACTLR_LATENCY_MASK: u32 = 0x3;
pub const FLASH_ACTLR_LATENCY_1: u32 = 0x1;

pub const RccRegs = extern struct {
    CTLR: u32,
    CFGR0: u32,
    INTR: u32,
    APB2PRSTR: u32,
    APB1PRSTR: u32,
    AHBPCENR: u32,
    APB2PCENR: u32,
    APB1PCENR: u32,
    RESERVED0: u32,
    RSTSCKR: u32,
};

pub const FlashRegs = extern struct {
    ACTLR: u32,
    KEYR: u32,
    OBKEYR: u32,
    STATR: u32,
    CTLR: u32,
    ADDR: u32,
    RESERVED0: u32,
    OBR: u32,
    WPR: u32,
    MODEKEYR: u32,
    BOOT_MODEKEYR: u32,
};

pub const GpioRegs = extern struct {
    CFGLR: u32,
    CFGHR: u32,
    INDR: u32,
    OUTDR: u32,
    BSHR: u32,
    BCR: u32,
    LCKR: u32,
};

pub const SysTickRegs = extern struct {
    CTLR: u32,
    SR: u32,
    CNT: u32,
    RESERVED0: u32,
    CMP: u32,
    RESERVED1: u32,
};

pub const I2cRegs = extern struct {
    CTLR1: u16,
    RESERVED0: u16,
    CTLR2: u16,
    RESERVED1: u16,
    OADDR1: u16,
    RESERVED2: u16,
    OADDR2: u16,
    RESERVED3: u16,
    DATAR: u16,
    RESERVED4: u16,
    STAR1: u16,
    RESERVED5: u16,
    STAR2: u16,
    RESERVED6: u16,
    CKCFGR: u16,
    RESERVED7: u16,
};

pub fn rcc() *volatile RccRegs {
    return @ptrFromInt(RCC_BASE);
}

pub fn flash() *volatile FlashRegs {
    return @ptrFromInt(FLASH_R_BASE);
}

pub fn gpioA() *volatile GpioRegs {
    return @ptrFromInt(GPIOA_BASE);
}

pub fn gpioC() *volatile GpioRegs {
    return @ptrFromInt(GPIOC_BASE);
}

pub fn gpioD() *volatile GpioRegs {
    return @ptrFromInt(GPIOD_BASE);
}

pub fn systick() *volatile SysTickRegs {
    return @ptrFromInt(SYSTICK_BASE);
}

pub fn i2c1() *volatile I2cRegs {
    return @ptrFromInt(I2C1_BASE);
}

pub fn pficEnableIrq(irqn: u8) void {
    const reg_index: usize = irqn / 32;
    const bit: u32 = @as(u32, 1) << @as(u5, @intCast(irqn % 32));
    const addr = PFIC_BASE + 0x100 + (reg_index * 4);
    const reg: *volatile u32 = @ptrFromInt(addr);
    reg.* = bit;
}
