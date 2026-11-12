const std = @import("std");
const zon = @import("build.zig.zon");

const name = @tagName(zon.name);
const version = std.SemanticVersion.parse(zon.version) catch unreachable;

pub fn build(b: *std.Build) void {
    const config = b.addOptions();
    setup(config) catch @panic("Failed to setup config");
    config.addOption(std.SemanticVersion, "version", version);

    const mod = b.addModule("math", .{
        .target = b.standardTargetOptions(.{}),
        .root_source_file = b.path("src/root.zig"),
        .imports = &.{
            .{ .name = "config", .module = config.createModule() },
        },
    });

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}

fn setup(config: *std.Build.Step.Options) !void {
    try config.contents.print(
        config.step.owner.allocator,
        "pub const {f} = {};\n",
        .{ std.zig.fmtId("name"), zon.name },
    );
}
