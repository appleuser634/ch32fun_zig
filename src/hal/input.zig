const gpio = @import("gpio.zig");
const time = @import("time.zig");

pub const Pull = enum {
    floating,
    up,
    down,
};

pub const Active = enum {
    high,
    low,
};

pub const ButtonConfig = struct {
    pin: gpio.Pin,
    pull: Pull = .up,
    active: Active = .low,
};

pub const Button = struct {
    pin: gpio.Pin,
    active: Active,

    pub fn init(config: ButtonConfig) Button {
        gpio.enablePortClock(config.pin.port);

        switch (config.pull) {
            .floating => config.pin.configure(.input_floating),
            .up => {
                config.pin.configure(.input_pull);
                config.pin.write(true);
            },
            .down => {
                config.pin.configure(.input_pull);
                config.pin.write(false);
            },
        }

        return .{
            .pin = config.pin,
            .active = config.active,
        };
    }

    pub fn isPressed(self: Button) bool {
        const level = self.pin.read();
        return switch (self.active) {
            .high => level,
            .low => !level,
        };
    }

    pub fn isReleased(self: Button) bool {
        return !self.isPressed();
    }
};

/// Non-blocking switch debouncer. A raw state must remain unchanged for
/// `debounce_us` before it becomes the stable state returned by `update`.
pub const Debouncer = struct {
    stable: bool = false,
    candidate: bool = false,
    candidate_since: u32 = 0,
    initialized: bool = false,
    debounce_us: u32 = 20_000,

    pub fn update(self: *Debouncer, raw: bool) bool {
        const now = time.nowCycles();
        if (!self.initialized) {
            self.stable = raw;
            self.candidate = raw;
            self.candidate_since = now;
            self.initialized = true;
            return self.stable;
        }

        if (raw != self.candidate) {
            self.candidate = raw;
            self.candidate_since = now;
        } else if (self.candidate != self.stable and
            time.elapsedUsSince(self.candidate_since) >= self.debounce_us)
        {
            self.stable = self.candidate;
        }
        return self.stable;
    }
};

pub fn button(config: ButtonConfig) Button {
    return Button.init(config);
}

const default_button = Button{
    .pin = gpio.pin(.D, 1),
    .active = .low,
};

pub fn initButtonPd1Pullup() void {
    _ = Button.init(.{
        .pin = default_button.pin,
        .pull = .up,
        .active = default_button.active,
    });
}

pub fn isButtonPressed() bool {
    return default_button.isPressed();
}
