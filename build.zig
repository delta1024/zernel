const std = @import("std");
const kconfig = @import("build/kconfig.zig");

const NasmStep = kconfig.NasmStep;
const GccStep = kconfig.GccStep;
const LdStep = kconfig.LdStep;
const CatStep = kconfig.CatStep;
const addFolderObjs = kconfig.addFolderObjs;
pub fn build(b: *std.Build) void {
    const build_options = kconfig.Arch.x86;
    const arch_dir = b.pathJoin(&.{ "src/arch", build_options.genericName() });
    const boot_dir = b.pathJoin(&.{ arch_dir, "boot" });

    const mbr = NasmStep.create(b, .{
        .name = "mbr",
        .source_file = .{ .path = b.pathJoin(&.{ boot_dir, "boot.s" }) },
        .format = .bin,
        .include_dirs = &.{boot_dir},
    });

    const k_objs = getKernelObjs(b, .x86, arch_dir);

    const link_step = LdStep.create(b, .{
        .name = "os-image",
        .arch = .x86,
        .link_text_at = "0x1000",
        .link_objs = k_objs.items,
    });
    const cat_step = CatStep.create(b, .{
        .name = "os-image",
        .inputs = .{
            mbr.getGeneratedObj(),
            link_step.getEmmitedBin(),
        },
    });
    const install_step = b.addInstallFile(cat_step.getEmittedBin(), "os-image");
    b.getInstallStep().dependOn(&install_step.step);

    if (b.findProgram(&.{b.fmt("qemu-system-{s}", .{build_options.genericName()})}, &.{}) catch null) |path| {
        const run_step = b.step("run", "run os");
        const qemu_step = b.addSystemCommand(&.{
            path,
            "-hda",
            "zig-out/os-image",
        });
        qemu_step.step.dependOn(b.getInstallStep());
        run_step.dependOn(&qemu_step.step);
    }

    const clean_step = b.step("clean", "clean build dir");
    for ([_][]const u8{
        "zig-out",
        "zig-cache",
    }) |dir| {
        const rm_step = b.addRemoveDirTree(dir);
        clean_step.dependOn(&rm_step.step);
    }
}

fn getKernelObjs(b: *std.Build, arch: kconfig.Arch, arch_dir: []const u8) std.ArrayList(std.Build.FileSource) {
    _ = arch;
    const kernel_stub = NasmStep.create(b, .{
        .name = "kernel_stub",
        .source_file = .{ .path = b.pathJoin(&.{ arch_dir, "entry.s" }) },
        .format = .elf,
    });
    const kernel_obj = GccStep.create(b, .{
        .name = "kernel",
        .arch = .x86,
        .file_path = .{ .path = "src/main.c" },
        .include_dir = "interface",
    });
    var k_objs = std.ArrayList(std.Build.LazyPath).init(b.allocator);

    k_objs.appendSlice(&.{
        kernel_stub.getGeneratedObj(),
        kernel_obj.getEmmitedObj(),
    }) catch @panic("OOM");

    const k_lib_objs = addFolderObjs(b, b.pathJoin(&.{ arch_dir, "lib" }), .x86);
    k_objs.appendSlice(k_lib_objs.items) catch @panic("OOM");
    const k_driver_objs = addFolderObjs(b, "src/drivers", .x86);
    k_objs.appendSlice(k_driver_objs.items) catch @panic("OOM");
    return k_objs;
}
