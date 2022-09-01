# Intro

Hello World example. Builds tested on MacOS, Linux Ubuntu and Windows 10 using v0.10.0-dev.

Currently forcing stage1 due to https://github.com/ziglang/zig/issues/12706

# x86_64

zig build -Dtarget=x86_64-linux-musl -Drelease-small=true -fstage1

# ARM64

zig build -Dtarget=aarch64-linux-musl -Drelease-small=true -fstage1
