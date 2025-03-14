const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    inline for (APPS) |app| {
        const exe = b.addExecutable(.{
            .name = app,
            .root_source_file = b.path(app ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.addIncludePath(b.path("."));
        exe.addCSourceFiles(.{
            .files = &.{"coroutine.c"},
        });
        exe.linkLibC();
        // // use the new x86 Backend
        // // https://ziglang.org/download/0.14.0/release-notes.html#x86-Backend
        // exe.use_llvm = false;
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        const run_step = b.step(app, "");
        run_step.dependOn(&run_cmd.step);
    }
}

const APPS = [_][]const u8{ "echo_server", "counter" };
