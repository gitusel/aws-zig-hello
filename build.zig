const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;
const RunStep = std.build.RunStep;
const Step = std.build.Step;
const Mode = std.builtin.Mode;
const allocPrint = std.fmt.allocPrint;
const CrossTarget = std.zig.CrossTarget;
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // adding aws_lambda_runtime
    const aws_pkg = @import("deps/build_lambda_runtime.zig").getBuildPkg(b);
    defer b.allocator.free(aws_pkg.dependencies.?);

    if (target.cpu_arch != null) {
        const exe = b.addExecutable("aws-zig-hello", "src/main.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.addPackage(aws_pkg);
        exe.linkLibC();
        exe.addIncludePath(thisDir() ++ "/deps/include/");
        addStaticLib(exe, "libbrotlicommon.a");
        addStaticLib(exe, "libbrotlidec.a");
        addStaticLib(exe, "libcrypto.a");
        addStaticLib(exe, "libssl.a");
        addStaticLib(exe, "libz.a");
        addStaticLib(exe, "libnghttp2.a");
        addStaticLib(exe, "libcurl.a");

        if (mode == .ReleaseSmall) {
            exe.strip = true;
        }

        exe.install();

        const pack_exe = packageBinary(b, "aws-zig-hello");
        pack_exe.step.dependOn(&exe.step);
        b.default_step.dependOn(&pack_exe.step);
    }

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);
    exe_tests.addPackage(aws_pkg);
    exe_tests.linkLibC();
    exe_tests.linkSystemLibrary("curl");

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

fn addStaticLib(libExeObjStep: *LibExeObjStep, staticLibName: [:0]const u8) void {
    if (libExeObjStep.target.cpu_arch.?.isAARCH64()) {
        libExeObjStep.addObjectFile(allocPrint(libExeObjStep.builder.allocator, "{s}/deps/{s}/{s}", .{ thisDir(), "lib_aarch64", staticLibName }) catch unreachable);
    } else {
        libExeObjStep.addObjectFile(allocPrint(libExeObjStep.builder.allocator, "{s}/deps/{s}/{s}", .{ thisDir(), "lib_x86_64", staticLibName }) catch unreachable);
    }
}

fn addIncludePath(libExeObjStep: *LibExeObjStep) void {
    if (libExeObjStep.target.cpu_arch.?.isAARCH64()) {
        libExeObjStep.addIncludePath(thisDir() ++ "/deps/include_aarch64/");
    } else {
        libExeObjStep.addIncludePath(thisDir() ++ "/deps/include_x86_64/");
    }
}

fn dirExists(path: [:0]const u8) bool {
    var dir = std.fs.openDirAbsolute(path, .{}) catch return false;
    dir.close();
    return true;
}

fn packageBinary(b: *Builder, package_name: [:0]const u8) *RunStep {
    if (!dirExists(thisDir() ++ "/runtime")) {
        std.fs.makeDirAbsolute(thisDir() ++ "/runtime") catch unreachable;
    }
    const package_path = allocPrint(b.allocator, "{s}/zig-out/bin/{s}", .{ thisDir(), package_name }) catch unreachable;
    var run_pakager: *RunStep = undefined;

    if (builtin.os.tag != .windows) {
        const packager_script = thisDir() ++ "/packaging/packager";
        run_pakager = b.addSystemCommand(&[_][]const u8{ packager_script, package_path });
    } else {
        const packager_script = thisDir() ++ "/packaging/packager.ps1";
        run_pakager = b.addSystemCommand(&[_][]const u8{ "powershell", packager_script, package_path });
    }
    run_pakager.cwd = thisDir() ++ "/runtime";
    return run_pakager;
}
