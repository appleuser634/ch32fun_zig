const std = @import("std");

const Example = struct {
    name: []const u8,
    path: []const u8,
};

const examples = [_]Example{
    .{ .name = "blinky", .path = "examples/blinky/main.zig" },
    .{ .name = "gpio_input", .path = "examples/gpio_input/main.zig" },
    .{ .name = "timer_irq", .path = "examples/timer_irq/main.zig" },
    .{ .name = "oled", .path = "examples/oled/main.zig" },
};

fn resolveExample(name: []const u8) ?Example {
    inline for (examples) |example| {
        if (std.mem.eql(u8, name, example.name)) return example;
    }
    return null;
}

pub fn build(b: *std.Build) void {
    const optimize = b.option(std.builtin.OptimizeMode, "optimize", "Optimization mode") orelse .ReleaseSmall;
    const example_name = b.option([]const u8, "example", "Example to build") orelse "blinky";
    const selected = resolveExample(example_name) orelse {
        std.debug.print("Unknown example '{s}'. Available: blinky, gpio_input, timer_irq, oled\n", .{example_name});
        @panic("invalid example");
    };

    const mkdir_step = b.addSystemCommand(&.{ "mkdir", "-p", "zig-out/firmware" });

    const query = std.Target.Query{
        .cpu_arch = .riscv32,
        .cpu_model = .{ .explicit = &std.Target.riscv.cpu.generic_rv32 },
        .cpu_features_add = std.Target.riscv.featureSet(&.{
            std.Target.riscv.Feature.c,
            std.Target.riscv.Feature.e,
        }),
        .cpu_features_sub = std.Target.riscv.featureSet(&.{
            std.Target.riscv.Feature.i,
        }),
        .os_tag = .freestanding,
        .abi = .eabi,
    };

    const target = b.resolveTargetQuery(query);

    const root_module = b.createModule(.{
        .root_source_file = b.path(selected.path),
        .target = target,
        .optimize = optimize,
        .link_libc = false,
    });

    const exe = b.addExecutable(.{
        .name = selected.name,
        .root_module = root_module,
        .linkage = .static,
    });

    exe.step.dependOn(&mkdir_step.step);
    exe.bundle_compiler_rt = true;
    exe.link_gc_sections = true;
    exe.link_function_sections = true;
    exe.link_data_sections = true;
    exe.setLinkerScript(b.path("src/runtime/linker.ld"));

    const ch32fun_mod = b.createModule(.{
        .root_source_file = b.path("src/ch32fun.zig"),
    });
    root_module.addImport("ch32fun", ch32fun_mod);

    b.installArtifact(exe);

    const elf_install = b.addInstallFileWithDir(exe.getEmittedBin(), .{ .custom = "firmware" }, b.fmt("{s}.elf", .{selected.name}));
    b.getInstallStep().dependOn(&elf_install.step);

    const bin = exe.addObjCopy(.{
        .format = .bin,
        .basename = b.fmt("{s}.bin", .{selected.name}),
    });
    const bin_install = b.addInstallFileWithDir(bin.getOutput(), .{ .custom = "firmware" }, b.fmt("{s}.bin", .{selected.name}));
    b.getInstallStep().dependOn(&bin_install.step);

    const hex = exe.addObjCopy(.{
        .format = .hex,
        .basename = b.fmt("{s}.hex", .{selected.name}),
    });
    const hex_install = b.addInstallFileWithDir(hex.getOutput(), .{ .custom = "firmware" }, b.fmt("{s}.hex", .{selected.name}));
    b.getInstallStep().dependOn(&hex_install.step);

    const lst_cmd = b.addSystemCommand(&.{
        "sh",
        "-c",
        "if command -v llvm-objdump >/dev/null 2>&1; then llvm-objdump -d \"$1\" > \"$2\"; else riscv-none-elf-objdump -d \"$1\" > \"$2\"; fi",
        "sh",
    });
    lst_cmd.addFileArg(exe.getEmittedBin());
    const lst_file = lst_cmd.addOutputFileArg(b.fmt("{s}.lst", .{selected.name}));
    const lst_install = b.addInstallFileWithDir(lst_file, .{ .custom = "firmware" }, b.fmt("{s}.lst", .{selected.name}));
    lst_install.step.dependOn(&lst_cmd.step);
    b.getInstallStep().dependOn(&lst_install.step);

    const map_cmd = b.addSystemCommand(&.{
        "sh",
        "-c",
        "if command -v llvm-nm >/dev/null 2>&1; then llvm-nm -n \"$1\" > \"$2\"; else riscv-none-elf-nm -n \"$1\" > \"$2\"; fi",
        "sh",
    });
    map_cmd.addFileArg(exe.getEmittedBin());
    const map_file = map_cmd.addOutputFileArg(b.fmt("{s}.map", .{selected.name}));
    const map_install = b.addInstallFileWithDir(map_file, .{ .custom = "firmware" }, b.fmt("{s}.map", .{selected.name}));
    map_install.step.dependOn(&map_cmd.step);
    b.getInstallStep().dependOn(&map_install.step);

    const flash = b.step("flash", "Flash selected example using minichlink");
    flash.dependOn(b.getInstallStep());

    const flash_cmd = b.addSystemCommand(&.{ "sh", "tools/flash.sh" });
    flash_cmd.addArg(selected.name);
    flash_cmd.step.dependOn(b.getInstallStep());
    flash.dependOn(&flash_cmd.step);

    const disasm = b.step("disasm", "Generate disassembly (.lst)");
    disasm.dependOn(&lst_install.step);

    const size_cmd = b.addSystemCommand(&.{
        "sh",
        "-c",
        "if command -v llvm-size >/dev/null 2>&1; then llvm-size \"$1\"; else riscv-none-elf-size \"$1\"; fi",
        "sh",
    });
    size_cmd.addFileArg(exe.getEmittedBin());
    size_cmd.step.dependOn(b.getInstallStep());
    const size = b.step("size", "Show firmware size");
    size.dependOn(&size_cmd.step);
}
