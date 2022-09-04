const std = @import("std");
const Allocator = std.mem.Allocator;

const aws = @import("aws");
const lambda_runtime = aws.lambda_runtime;
const Runtime = lambda_runtime.Runtime;
const InvocationRequest = lambda_runtime.InvocationRequest;
const InvocationResponse = lambda_runtime.InvocationResponse;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

pub fn myHandler(ir: InvocationRequest) !InvocationResponse {
    _ = ir;
    return InvocationResponse.success(allocator, "{\"Hello\":\", World!\"}", "application/json");
}

pub fn main() !void {
    defer arena.deinit();
 
    var runtime = Runtime.init(allocator);
    defer runtime.deinit();
    try runtime.runHandler(myHandler);
}

test "aws-zig-hello simple test" {
    const expect = std.testing.expect;
    const version = lambda_runtime.getVersion();
    try expect(version.len >= 0);
}
