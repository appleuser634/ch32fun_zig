# ch32fun_zig (CH32V003)

Pure Zig port scaffold of ch32fun for CH32V003.

## Requirements

- Zig 0.15.x
- `../ch32fun/minichlink/minichlink` for flashing

## Build

```sh
zig build -Dexample=blinky
zig build -Dexample=gpio_input
zig build -Dexample=timer_irq
```

Output files are placed in `zig-out/firmware/`:

- `<example>.elf`
- `<example>.bin`
- `<example>.hex`
- `<example>.lst`
- `<example>.map`

## Flash

```sh
zig build flash -Dexample=blinky
```

## Current scope

- CH32V003 only
- System clock init (HSI+PLL)
- GPIO input/output API
- SysTick-based delay and SysTick IRQ tick source
