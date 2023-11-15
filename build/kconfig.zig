const std = @import("std");
const CpuArch = std.Target.Cpu.Arch;
const CrossTarget = std.zig.CrossTarget;
pub const Arch = enum {
    x86,
    pub fn genericName(self: Arch) []const u8 {
        return switch (self) {
            .x86 => "i686",
        };
    }
};
const FeatureMod = struct {
    add: std.Target.Cpu.Feature.Set = std.Target.Cpu.Feature.Set.empty,
    sub: std.Target.Cpu.Feature.Set = std.Target.Cpu.Feature.Set.empty,
    arch: CpuArch,
    fn x86() FeatureMod {
        var mod = FeatureMod{ .arch = .x86 };
        const Features = std.Target.x86.Feature;
        mod.add.addFeature(@intFromEnum(Features.soft_float));
        mod.sub.addFeature(@intFromEnum(Features.mmx));
        mod.sub.addFeature(@intFromEnum(Features.sse));
        mod.sub.addFeature(@intFromEnum(Features.sse2));
        mod.sub.addFeature(@intFromEnum(Features.avx));
        mod.sub.addFeature(@intFromEnum(Features.avx2));
        return mod;
    }
    fn x86_64() FeatureMod {
        var mod = .{ .arch = .x86_64 };
        const Features = std.Target.x86.Feature;
        mod.add.addFeature(@intFromEnum(Features.soft_float));
        mod.sub.addFeature(@intFromEnum(Features.mmx));
        mod.sub.addFeature(@intFromEnum(Features.sse));
        mod.sub.addFeature(@intFromEnum(Features.sse2));
        mod.sub.addFeature(@intFromEnum(Features.avx));
        mod.sub.addFeature(@intFromEnum(Features.avx2));
        return mod;
    }
    pub fn genTarget(self: *const FeatureMod) CrossTarget {
        return .{
            .abi = .none,
            .cpu_arch = self.arch,
            .cpu_features_add = self.add,
            .cpu_features_sub = self.sub,
            .os_tag = .freestanding,
        };
    }
    pub fn genericName(self: *const FeatureMod) []const u8 {
        return switch (self.arch) {
            .x86 => "i386",
            else => unreachable, //"x86_64",

        };
    }
};

pub fn getFeatureMod(comptime arch: std.Target.Cpu.Arch) FeatureMod {
    return switch (arch) {
        .x86 => FeatureMod.x86(),
        else => @compileError("Unsuported archtecture"),
    };
}
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
