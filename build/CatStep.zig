const std = @import("std");
const Build = std.Build;
const Step = Build.Step;
const LazyFile = Build.FileSource;
const GeneratedFile = Build.GeneratedFile;

const Self = @This();
const Options = struct {
    name: []const u8,
    inputs: [2]LazyFile,
};

name: []const u8,
step: Step,
inputs: [2]LazyFile,
output_file: GeneratedFile = undefined,

pub fn create(b: *Build, options: Options) *Self {
    const name = b.dupe(options.name);
    const inputs = [2]LazyFile{
        options.inputs[0].dupe(b),
        options.inputs[1].dupe(b),
    };

    const self = b.allocator.create(Self) catch @panic("OOM");
    self.* = .{
        .name = name,
        .inputs = inputs,
        .step = Step.init(.{
            .owner = b,
            .makeFn = make,
            .id = .custom,
            .name = name,
        }),
    };
    self.output_file = .{ .step = &self.step };
    for (self.inputs) |f|
        f.addStepDependencies(&self.step);
    return self;
}
fn make(s: *Step, _: *std.Progress.Node) !void {
    const b = s.owner;
    const self = @fieldParentPtr(Self, "step", s);

    var man = b.cache.obtain();
    defer man.deinit();

    const input_real_paths: [2][]const u8 = .{
        self.inputs[0].getPath(b),
        self.inputs[1].getPath(b),
    };
    for (input_real_paths) |path|
        _ = try man.addFile(path, null);

    _ = try s.cacheHit(&man);
    const digest = man.final();

    const cache_dir = "o" ++ std.fs.path.sep_str ++ digest;
    const full_output_path = try b.cache_root.join(b.allocator, &.{ cache_dir, self.name });
    b.cache_root.handle.makePath(cache_dir) catch |err| {
        return s.fail("could not create {s}: {s}", .{ cache_dir, @errorName(err) });
    };

    const cat_script = try std.fs.realpathAlloc(b.allocator, b.pathJoin(&.{ "build", "cat_step.sh" }));
    var argv = std.ArrayList([]const u8).init(b.allocator);
    try argv.append(cat_script);
    try argv.appendSlice(&input_real_paths);
    try argv.append(full_output_path);

    try s.evalChildProcess(argv.items);
    self.output_file.path = full_output_path;
}

pub fn getEmittedBin(self: *Self) LazyFile {
    return .{ .generated = &self.output_file };
}
