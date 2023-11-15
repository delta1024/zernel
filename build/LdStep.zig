const std = @import("std");
const ArrayList = std.ArrayList;
const common = @import("kconfig.zig");

const Build = std.Build;
const Step = Build.Step;
const LazyPath = Build.FileSource;
const GeneratedFile = Build.GeneratedFile;
const Arch = common.Arch;
const Self = @This();
pub const Format = enum {
    binary,
};

pub const Options = struct {
    name: []const u8,
    arch: Arch,
    format: Format = .binary,
    link_objs: []const LazyPath,
    link_text_at: ?[]const u8 = null,
};

name: []const u8,
step: Step,
arch: Arch,
format: Format = .binary,
link_objs: ArrayList(LazyPath),
link_text_at: ?[]const u8 = null,
output_file: GeneratedFile = undefined,
pub fn create(b: *Build, options: Options) *Self {
    const self = b.allocator.create(Self) catch @panic("OOM");
    self.* = .{
        .name = b.dupe(options.name),
        .arch = options.arch,
        .step = Step.init(.{
            .name = common.makeStepName(b, "link", options.name),
            .id = .custom,
            .makeFn = make,
            .owner = b,
        }),
        .format = options.format,
        .link_objs = bk: {
            var list = ArrayList(LazyPath).init(b.allocator);
            for (options.link_objs) |obj| {
                const path = obj.dupe(b);
                list.append(path) catch @panic("OOM");
            }
            break :bk list;
        },
        .link_text_at = if (options.link_text_at) |loc| b.dupe(loc) else null,
    };
    self.output_file = .{ .step = &self.step };
    for (options.link_objs) |o| {
        o.addStepDependencies(&self.step);
    }
    return self;
}
fn make(s: *Step, _: *std.Progress.Node) !void {
    const b = s.owner;
    const arena = b.allocator;
    const self = @fieldParentPtr(Self, "step", s);

    const full_source_paths = bk: {
        var list = ArrayList([]const u8).init(arena);
        for (self.link_objs.items) |path| {
            try list.append(path.getPath(b));
        }
        break :bk list;
    };
    const ld_args = bk: {
        var argv = ArrayList([]const u8).init(arena);
        common.createFlag(&argv, 'T', "text", arena);
        try argv.append("0x1000");
        try argv.appendSlice(full_source_paths.items);
        try argv.appendSlice(&.{ "--oformat", @tagName(self.format) });
        break :bk argv;
    };
    const ld_str = b.fmt("{s}-elf-ld", .{self.arch.binaryName()});
    const ld_path = b.findProgram(
        &.{ld_str},
        &.{},
    ) catch @panic("could not find apporopreate ld binary in path");

    var man = b.cache.obtain();
    defer man.deinit();

    try man.addListOfFiles(full_source_paths.items);
    man.hash.addBytes(ld_path);
    man.hash.addListOfBytes(ld_args.items);

    if (try s.cacheHit(&man)) {
        const digest = man.final();
        self.output_file.path = try b.cache_root.join(arena, &.{
            "o",
            &digest,
            self.name,
        });
        return;
    }

    const digest = man.final();

    const cache_dir = "o" ++ std.fs.path.sep_str ++ digest;
    const full_dest_path = try b.cache_root.join(arena, &.{ cache_dir, self.name });
    b.cache_root.handle.makePath(cache_dir) catch |err| {
        return s.fail("unable to create {s}: {s}", .{ cache_dir, @errorName(err) });
    };

    var argv = ArrayList([]const u8).init(arena);
    try argv.appendSlice(&.{ ld_path, "-o", full_dest_path });
    try argv.appendSlice(ld_args.items);

    try s.evalChildProcess(argv.items);
    self.output_file.path = full_dest_path;
    try man.writeManifest();
}

pub fn getEmmitedBin(self: *Self) LazyPath {
    return .{ .generated = &self.output_file };
}
