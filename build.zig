const std = @import("std");
const Build = if (@hasDecl(std, "Build")) std.Build else std.build.Builder;
const OptimizeMode = if (@hasDecl(Build, "standardOptimizeOption")) std.builtin.OptimizeMode else std.builtin.Mode;
const CompileStep = if (@hasDecl(Build, "standardOptimizeOption")) std.build.CompileStep else std.build.LibExeObjStep;
const RunStep = std.build.RunStep;
const allocPrint = std.fmt.allocPrint;
const CrossTarget = std.zig.CrossTarget;
const builtin = @import("builtin");

pub fn build(b: *Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimize options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = if (@hasDecl(Build, "standardOptimizeOption")) b.standardOptimizeOption(.{}) else b.standardReleaseOptions();

    // adding aws_lambda_runtime
    const aws_module = @import("deps/build_lambda_runtime.zig").getBuildModule(b);
    defer if (!@hasDecl(std, "Build")) {
        b.allocator.free(aws_module.dependencies.?);
    };

    var exe: *CompileStep = undefined;

    if (target.cpu_arch != null) {
        if (@hasDecl(Build, "standardOptimizeOption")) {
            exe = b.addExecutable(.{
                .name = "aws-zig-hello",
                .root_source_file = .{ .path = "src/main.zig" },
                .optimize = optimize,
                .target = target,
            });
            exe.addModule("aws", aws_module);
        } else {
            exe = b.addExecutable("aws-zig-hello", "src/main.zig");
            exe.setBuildMode(optimize);
            exe.setTarget(target);
            exe.addPackage(aws_module);
        }

        if (optimize == .ReleaseSmall) {
            exe.strip = true;
        }

        exe.linkLibC();
        exe.addIncludePath(getPath("/deps/include/"));
        addStaticLib(exe, "libbrotlicommon.a");
        addStaticLib(exe, "libbrotlidec.a");
        addStaticLib(exe, "libcrypto.a");
        addStaticLib(exe, "libssl.a");
        addStaticLib(exe, "libz.a");
        addStaticLib(exe, "libnghttp2.a");
        addStaticLib(exe, "libcurl.a");

        exe.install();

        const pack_exe = packageBinary(b, "aws-zig-hello");
        pack_exe.step.dependOn(&exe.step);
        b.default_step.dependOn(&pack_exe.step);
    }

    var exe_tests: *CompileStep = undefined;
    if (@hasDecl(Build, "standardOptimizeOption")) {
        exe_tests = b.addTest(.{
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.addModule("aws", aws_module);
    } else {
        exe_tests = b.addTest("src/main.zig");
        exe_tests.setBuildMode(optimize);
        exe_tests.setTarget(target);
        exe_tests.addPackage(aws_module);
    }
    exe_tests.linkLibC();
    exe_tests.linkSystemLibrary("curl");

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

fn thisDir() []const u8 {
    return comptime blk: {
        const src = @src();
        const root_dir = std.fs.path.dirname(src.file) orelse ".";
        break :blk root_dir;
    };
}

// from https://zig.news/xq/cool-zig-patterns-paths-in-build-scripts-4p59
fn getPath(comptime path: [:0]const u8) [:0]const u8 {
    return comptime blk: {
        break :blk thisDir() ++ path;
    };
}

fn addStaticLib(compileStep: *CompileStep, staticLibName: [:0]const u8) void {
    if (compileStep.target.cpu_arch.?.isAARCH64()) {
        compileStep.addObjectFile(allocPrint(compileStep.builder.allocator, "{s}/deps/{s}/{s}", .{ thisDir(), "lib_aarch64", staticLibName }) catch unreachable);
    } else {
        compileStep.addObjectFile(allocPrint(compileStep.builder.allocator, "{s}/deps/{s}/{s}", .{ thisDir(), "lib_x86_64", staticLibName }) catch unreachable);
    }
}

fn dirExists(path: [:0]const u8) bool {
    var dir = std.fs.cwd().openDir(path, .{}) catch return false;
    dir.close();
    return true;
}

fn packageBinary(b: *Build, package_name: []const u8) *RunStep {
    if (!dirExists(getPath("/runtime"))) {
        std.fs.cwd().makeDir(getPath("/runtime")) catch unreachable;
    }
    const package_path = allocPrint(b.allocator, "../zig-out/bin/{s}", .{package_name}) catch unreachable;
    var run_pakager: *RunStep = undefined;

    if (builtin.os.tag != .windows) {
        const packager_script = "../packaging/packager";
        run_pakager = b.addSystemCommand(&[_][]const u8{ packager_script, package_path });
    } else {
        const packager_script = "../packaging/packager.ps1";
        run_pakager = b.addSystemCommand(&[_][]const u8{ "powershell", packager_script, package_path });
    }
    run_pakager.cwd = getPath("/runtime");
    return run_pakager;
}
