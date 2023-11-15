const std = @import("std");
const Self = @This();
const ArrayList = std.ArrayList;

const Build = std.Build;
const Step = Build.Step;
const LazyPath = Build.FileSource;
const GeneratedFile = Build.GeneratedFile;

const createFlag = @import("kconfig.zig").createFlag;
const Format = enum { bin, elf };
const Options = struct {
    name: []const u8,
    source_file: LazyPath,
    format: Format,
    include_dirs: ?[]const []const u8 = null,
};
step: Step,
name: []const u8,
source_file: LazyPath,
format: Format,
include_dirs: ?ArrayList([]const u8) = null,
output_file: GeneratedFile = undefined,
pub fn create(b: *Build, options: Options) *Self {
    const name = b.dupe(options.name);
    const source_file = options.source_file.dupe(b);
    const include_dir = if (options.include_dirs) |dirs| bk: {
        var list = ArrayList([]const u8).init(b.allocator);
        for (dirs) |dir|
            list.append(b.dupe(dir)) catch @panic("OOM");
        break :bk list;
    } else null;
    const self = b.allocator.create(Self) catch @panic("OOM");
    self.* = .{
        .name = name,
        .source_file = source_file,
        .include_dirs = include_dir,
        .format = options.format,
        .step = Step.init(.{
            .id = .compile,
            .name = b.fmt("assemble {s}", .{name}),
            .owner = b,
            .makeFn = make,
        }),
    };
    self.output_file = .{ .step = &self.step };
    return self;
}

fn make(s: *Step, _: *std.Progress.Node) !void {
    const b = s.owner;
    const arena = b.allocator;
    const self = @fieldParentPtr(Self, "step", s);

    var man = b.cache.obtain();
    defer man.deinit();

    const source_path = self.source_file.getPath(b);
    _ = try man.addFile(source_path, null);
    if (self.include_dirs) |dirs| {
        for (dirs.items) |dir|
            man.hash.addBytes(dir);
    }

    if (try s.cacheHit(&man)) {
        const digest = man.final();
        self.output_file.path = try b.cache_root.join(b.allocator, &.{
            "o", &digest, self.name,
        });
        return;
    }

    const digest = man.final();

    const cache_dir = "o" ++ std.fs.path.sep_str ++ digest;
    const full_dest_path = try b.cache_root.join(arena, &.{ cache_dir, self.name });
    b.cache_root.handle.makePath(cache_dir) catch |err| {
        return s.fail("unable to create {s}: {s}", .{ cache_dir, @errorName(err) });
    };

    const nasm_path = b.findProgram(&.{"nasm"}, &.{}) catch @panic("unable to locate nasm binary in user path");
    var argv = ArrayList([]const u8).init(arena);

    try argv.appendSlice(&.{ nasm_path, source_path });

    if (self.include_dirs) |dirs| {
        for (dirs.items) |dir| {
            createFlag(&argv, 'I', dir, arena);
        }
    }

    try argv.appendSlice(&.{ "-f", @tagName(self.format) });

    try argv.appendSlice(&.{ "-o", full_dest_path });

    try s.evalChildProcess(argv.items);
    self.output_file.path = full_dest_path;
    try man.writeManifest();
}
pub fn getGeneratedObj(self: *Self) LazyPath {
    return .{ .generated = &self.output_file };
}
