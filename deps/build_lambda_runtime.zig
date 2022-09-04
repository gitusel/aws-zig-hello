const std = @import("std");
const Builder = std.build.Builder;
const Pkg = std.build.Pkg;
const Version = std.builtin.Version;
const Os = std.Target.Os;

const aws_lambda_zig_version = Version{ .major = 0, .minor = 0, .patch = 0 };

pub fn getBuildPkg(b: *Builder) Pkg {
    return Pkg{
        .name = "aws",
        .source = .{ .path = getFullPath("/src/aws.zig") },
        .dependencies = b.allocator.dupe(Pkg, &[_]Pkg{getBuildOptionsPkg(b)}) catch null,
    };
}

fn getBuildOptionsPkg(b: *Builder) Pkg {
    const build_options_step = std.build.OptionsStep.create(b);
    build_options_step.addOption(Version, "aws_lambda_zig_version", aws_lambda_zig_version);
    return build_options_step.getPackage("build_options");
}

// from https://zig.news/xq/cool-zig-patterns-paths-in-build-scripts-4p59
fn getFullPath(comptime path: [:0]const u8) [:0]const u8 {
    return comptime (std.fs.path.dirname(@src().file) orelse ".") ++ path;
}
