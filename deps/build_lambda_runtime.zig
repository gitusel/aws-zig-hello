const std = @import("std");
const Build = if (@hasDecl(std, "Build")) std.Build else std.build.Builder;
const Module = if (@hasDecl(std, "Build")) Build.Module else std.build.Pkg;
const Version = std.builtin.Version;
const Os = std.Target.Os;

const aws_lambda_zig_version = Version{ .major = 0, .minor = 0, .patch = 0 };

pub fn getBuildModule(b: *Build) if (@hasDecl(std, "Build")) *Module else Module {
    if (@hasDecl(std, "Build")) {
        return b.createModule(.{
            .source_file = .{ .path = getPath("/src/aws.zig") },
            .dependencies = &.{
                .{ .name = "build_options", .module = getBuildOptionsModule(b) },
            },
        });
    } else {
        return Module{
            .name = "aws",
            .source = .{ .path = getPath("/src/aws.zig") },
            .dependencies = b.allocator.dupe(Module, &[1]Module{getBuildOptionsModule(b)}) catch null,
        };
    }
}

fn getBuildOptionsModule(b: *Build) if (@hasDecl(std, "Build")) *Module else Module {
    const build_options_step = if (@hasDecl(std, "Build")) Build.OptionsStep.create(b) else std.build.OptionsStep.create(b);
    build_options_step.addOption(Version, "aws_lambda_zig_version", aws_lambda_zig_version);
    return if (@hasDecl(std, "Build")) build_options_step.createModule() else build_options_step.getPackage("build_options");
}

// from https://zig.news/xq/cool-zig-patterns-paths-in-build-scripts-4p59
fn getPath(comptime path: [:0]const u8) [:0]const u8 {
    return comptime blk: {
        const src = @src();
        const root_dir = std.fs.path.dirname(src.file) orelse ".";
        break :blk root_dir ++ path;
    };
}
