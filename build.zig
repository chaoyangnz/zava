const std = @import("std");
const Target = std.Target;
const Zig = std.zig;
const FileSource = std.build.FileSource;
const Builder = std.build.Builder;
const FeatureSet = std.Target.Cpu.Feature.Set;

pub fn build(b: *Builder) void {
    const exe = b.addExecutable(.{
        .name = "jaza",
        .root_source_file = .{ .path = "src/main.zig" },
    });
    // exe.setVerboseCC(true);
    b.installArtifact(exe);

    b.default_step.dependOn(&exe.step);
}
