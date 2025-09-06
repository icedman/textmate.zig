const std = @import("std");
const res = @import("src/resources/resources.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // generate embedded.zig
    const generate_embedded = b.allocator.create(std.Build.Step) catch unreachable;
    generate_embedded.* = std.Build.Step.init(.{
        .id = .custom,
        .name = "generate_embedded",
        .owner = b,
        .makeFn = struct {
            fn make(step: *std.Build.Step, opts: std.Build.Step.MakeOptions) !void {
                const bb = step.owner;
                _ = opts;

                var assets_buffer = try std.ArrayList(u8).initCapacity(bb.allocator, 2048);
                defer assets_buffer.deinit(bb.allocator);

                const themes_path = try bb.build_root.join(bb.allocator, &.{"src/resources/themes"});
                try res.generateEmbeddedThemesFile(bb.allocator, assets_buffer.writer(bb.allocator), "theme_", themes_path);

                const grammars_path = try bb.build_root.join(bb.allocator, &.{"src/resources/grammars"});
                try res.generateEmbeddedGrammarsFile(bb.allocator, assets_buffer.writer(bb.allocator), "grammar_", grammars_path);

                const embed_path = try bb.cache_root.join(bb.allocator, &.{"embedded.zig"});
                std.debug.print("{s}\n", .{embed_path});

                const embed_file = try std.fs.cwd().createFile(embed_path, .{ .truncate = true });
                defer embed_file.close();
                try embed_file.writeAll(assets_buffer.items);
            }
        }.make,
    });

    // copy over to src/embedded.zig
    var update_embedded = b.addUpdateSourceFiles();
    update_embedded.addCopyFileToSource(
        b.path(".zig-cache/embedded.zig"),
        "src/resources/embedded.zig",
    );
    update_embedded.step.dependOn(generate_embedded);

    // the build command
    const update_step = b.step("generate", "Read themes and grammars folders and generate embedded.zig");
    update_step.dependOn(&update_embedded.step);

    // textmate Module - this produces a Zig importable module
    const lib_mod = b.addModule("textmate", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // cat example (tmcat)
    const cat_exe_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/cat.zig"),
        .target = target,
        .optimize = optimize,
    });
    cat_exe_mod.addImport("textmate_lib", lib_mod);

    // less example (tmless)
    const less_exe_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/less.zig"),
        .target = target,
        .optimize = optimize,
    });
    less_exe_mod.addImport("textmate_lib", lib_mod);

    // textmate lib - this produces the static library
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "textmate",
        .root_module = lib_mod,
    });
    b.installArtifact(lib);

    // build the examples
    const cat_exe = b.addExecutable(.{
        .name = "catx",
        .root_module = cat_exe_mod,
    });
    b.installArtifact(cat_exe);
    const run_cat_cmd = b.addRunArtifact(cat_exe);

    const less_exe = b.addExecutable(.{
        .name = "lessx",
        .root_module = less_exe_mod,
    });
    b.installArtifact(less_exe);
    const run_less_cmd = b.addRunArtifact(less_exe);

    // oniguruma
    if (b.lazyDependency("oniguruma", .{
        .target = target,
        .optimize = optimize,
    })) |oniguruma_dep| {
        lib.root_module.addImport(
            "oniguruma",
            oniguruma_dep.module("oniguruma"),
        );
        lib_mod.linkLibrary(oniguruma_dep.artifact("oniguruma"));
    }

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cat_cmd.step.dependOn(b.getInstallStep());
    run_less_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cat_cmd.addArgs(args);
        run_less_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_cat_step = b.step("run", "Run cat");
    run_cat_step.dependOn(&run_cat_cmd.step);

    const run_less_step = b.step("less", "Run less");
    run_less_step.dependOn(&run_less_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_module = cat_exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
