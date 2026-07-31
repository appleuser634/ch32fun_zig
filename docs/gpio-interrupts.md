# GPIO interrupts on CH32V003

`ch32fun_zig` can own reset initialization and the interrupt entry points, so
applications do not need to export `_start` or write `mtvec` themselves.

## Build configuration

The normal configuration installs the complete CH32V003 vector table:

```zig
const fw = ch32.addFirmware(b, dep, .{
    .name = "button_irq",
    .root_source_file = b.path("src/main.zig"),
    .runtime = .ch32fun,
});
```

`.ch32fun` is the default and may be omitted. Firmware whose only enabled IRQ
is the shared `EXTI7_0` source can save 156 bytes of vector-table Flash by
selecting the compact runtime:

```zig
.runtime = .ch32fun_exti,
```

The legacy `.application` mode is available when an application intentionally
owns `_start`, memory initialization, machine state and all trap entries. It is
not sufficient to export `_start` as a normal Zig function that only calls
`main`.

## Application code

```zig
const fun = @import("ch32fun");

fn onButton(line: u8) callconv(.c) void {
    _ = line;
    fun.gpio.pin(.D, 0).toggle();
}

pub fn main() noreturn {
    fun.system.init(.{});
    fun.gpio.pin(.D, 0).configure(.output_pp_10mhz);
    fun.input.initButtonPd1Pullup();

    fun.exti.config(.{
        .port = .D,
        .line = 1,
        .trigger = .falling,
        .handler = onButton,
    });
    fun.exti.enable(1);
    fun.system.enableInterrupts();

    while (true) fun.system.wfi();
}
```

The handler uses `callconv(.c)` because the HAL dispatcher calls it as a normal
function after the IRQ entry has saved the interrupted RV32E register set.
Handlers must remain short and non-blocking.

## Runtime contract

Both managed runtimes perform the reset work required by Zig firmware:

- initialize `gp` and `sp`;
- zero `.bss` and copy `.data` from Flash to RAM;
- configure machine-mode `mstatus` with global interrupts still disabled;
- explicitly disable QingKe HPE and use the software-stacked interrupt ABI;
- install either the complete vector table or the compact direct EXTI entry.

EXTI configuration clears a flag latched while routing and trigger polarity
were incomplete. Since lines 0 through 7 share one PFIC source, disabling one
line leaves PFIC enabled until the final active EXTI line is disabled.

## Verification

Build both runtime variants whenever startup or interrupt assembly changes:

```sh
zig build -Dexample=exti_button -Druntime=ch32fun
zig build -Dexample=exti_button -Druntime=ch32fun_exti
zig build -Dexample=blinky -Druntime=application
```

For the complete runtime, the ELF must contain a 156-byte `.vector_table` at
`0x08000000`. The compact runtime intentionally has an empty vector-table
section and writes the aligned EXTI entry directly to `mtvec`.

Target builds verify the RV32E instruction/register set and linker layout, but
they do not replace a physical edge test. Verify rising, falling and both-edge
modes on hardware, including repeated enable/disable and button bounce.
