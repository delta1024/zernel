const std = @import("std");
const common = @import("kconfig.zig");
const ArrayList = std.ArrayList;
const Build = std.Build;
const Step = Build.Step;
const LazyFile = Build.FileSource;
const GeneratedFile = Build.GeneratedFile;
const Arch = common.Arch;
const Self = @This();
pub const Options = struct {
    name: []const u8,
    file_path: LazyFile,
    include_dir: ?[]const u8 = null,
    arch: Arch,
};

name: []const u8,
step: Step,
file_path: LazyFile,
include_dir: ?[]const u8 = null,
arch: Arch,
output_file: GeneratedFile = undefined,

pub fn create(b: *Build, options: Options) *Self {
    const name = b.dupe(options.name);
    const file_path = options.file_path.dupe(b);
    const include_dir = if (options.include_dir) |d| b.dupePath(d) else null;

    const self = b.allocator.create(Self) catch @panic("OOM");
    self.* = .{
        .step = Step.init(.{
            .id = .compile,
            .name = common.makeStepName(b, "compile-gcc", name),
            .owner = b,
            .makeFn = make,
        }),
        .file_path = file_path,
        .name = name,
        .include_dir = include_dir,
        .arch = options.arch,
    };
    self.output_file = .{ .step = &self.step };
    options.file_path.addStepDependencies(&self.step);
    return self;
}
fn make(s: *Step, _: *std.Progress.Node) !void {
    const b = s.owner;
    const self = @fieldParentPtr(Self, "step", s);
    const arena = b.allocator;

    const full_input_path = self.file_path.getPath(b);
    var man = b.cache.obtain();
    defer man.deinit();
    const gcc_str = std.fmt.allocPrint(arena, "{s}-elf-gcc", .{self.arch.binaryName()}) catch @panic("OOM");
    const gcc_path = b.findProgram(&.{gcc_str}, &.{}) catch @panic("appropreate gcc binary not found");

    var argv = ArrayList([]const u8).init(arena);
    try argv.append(gcc_path);
    common.createFlag(&argv, 'f', "freestanding", arena);
    if (self.include_dir) |d| {
        const full_include_path = try b.build_root.join(b.allocator, &.{d});
        common.createFlag(&argv, 'I', "", arena);
        try argv.append(full_include_path);
    }
    try argv.appendSlice(&.{
        "-c",
        full_input_path,
    });
    _ = try man.addFile(full_input_path, null);
    man.hash.addListOfBytes(argv.items);

    if (try s.cacheHit(&man)) {
        const digest = man.final();
        self.output_file.path = try b.cache_root.join(arena, &.{
            "o", &digest, self.name,
        });
        return;
    }

    const digest = man.final();

    const cache_dir = "o" ++ std.fs.path.sep_str ++ digest;
    const full_output_path = try b.cache_root.join(arena, &.{ cache_dir, self.name });
    b.cache_root.handle.makePath(cache_dir) catch |err| {
        return s.fail("unable to make {s}: {s}", .{ cache_dir, @errorName(err) });
    };

    try argv.appendSlice(&.{
        "-o",
        full_output_path,
    });
    try s.evalChildProcess(argv.items);

    self.output_file.path = full_output_path;
    try man.writeManifest();
}

pub fn getEmmitedObj(self: *Self) LazyFile {
    return .{ .generated = &self.output_file };
}
