const std = @import("std");
const CpuArch = std.Target.Cpu.Arch;
const CrossTarget = std.zig.CrossTarget;
pub const NasmStep = @import("NasmStep.zig");
pub const GccStep = @import("GccStep.zig");
pub const LdStep = @import("LdStep.zig");
pub const CatStep = @import("CatStep.zig");

pub const Arch = enum {
    x86,
    pub fn binaryName(self: Arch) []const u8 {
        return switch (self) {
            .x86 => "i686",
        };
    }
    pub fn genericName(self: Arch) []const u8 {
        return switch (self) {
            .x86 => "i386",
        };
    }
};

const ArrayList = std.ArrayList;

pub inline fn createFlag(
    array: *ArrayList([]const u8),
    flag: u8,
    value: []const u8,
    allocator: std.mem.Allocator,
) void {
    const flag_str = std.fmt.allocPrint(
        allocator,
        "-{c}{s}",
        .{ flag, value },
    ) catch @panic("OOM");
    array.append(flag_str) catch @panic("OOM");
}
pub fn makeStepName(b: *std.Build, step: []const u8, target_name: []const u8) []u8 {
    return b.fmt("{s} {s} step", .{ step, target_name });
}
pub fn addFolderObjs(b: *std.Build, lib_dir: []const u8, arch: Arch) std.ArrayList(std.Build.LazyPath) {
    var output_paths = std.ArrayList(std.Build.LazyPath).init(b.allocator);

    var dir = b.build_root.handle.openIterableDir(lib_dir, .{}) catch @panic("could not open lib dir.");
    defer dir.close();
    var iter = dir.iterate();

    while (iter.next() catch @panic("dir read error")) |v| {
        if (std.mem.indexOf(u8, v.name, "~") != null) continue;

        const full_path = b.pathJoin(&.{ lib_dir, v.name });
        const b_step = GccStep.create(b, .{
            .arch = arch,
            .file_path = .{ .path = full_path },
            .include_dir = "interface",
            .name = v.name,
        });
        output_paths.append(b_step.getEmmitedObj()) catch @panic("OOM");
    }
    return output_paths;
}
