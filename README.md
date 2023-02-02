# Intro

Hello World example. Builds tested on MacOS, Linux Ubuntu and Windows 10 using v0.11.0-dev.

# x86_64

Before zig commit #efa25e7:

zig build -Dtarget=x86_64-linux-musl -Drelease-small=true

After zig commit #efa25e7:

zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseSmall

# ARM64

Before zig commit #efa25e7:

zig build -Dtarget=aarch64-linux-musl -Drelease-small=true

After zig commit #efa25e7:

zig build -Dtarget=aarch64-linux-musl -Doptimize=ReleaseSmall
