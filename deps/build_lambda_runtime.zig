const std = @import("std");
const Builder = std.build.Builder;
const Pkg = std.build.Pkg;
const Version = std.builtin.Version;
const Os = std.Target.Os;

const aws_lambda_zig_version = Version{ .major = 0, .minor = 0, .patch = 0 };

pub fn getBuildPkg(b: *Builder) Pkg {
    return Pkg{
        .name = "aws",
        .source = .{ .path = thisDir() ++ "/src/aws.zig" },
        .dependencies = b.allocator.dupe(Pkg, &[_]Pkg{getBuildOptionsPkg(b)}) catch null,
    };
}

fn getBuildOptionsPkg(b: *Builder) Pkg {
    const build_options_step = std.build.OptionsStep.create(b);
    build_options_step.addOption(Version, "aws_lambda_zig_version", aws_lambda_zig_version);
    return build_options_step.getPackage("build_options");
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
