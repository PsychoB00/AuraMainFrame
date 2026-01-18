/// STD
const std = @import("std");
const GeneralPurpouseAllocator = std.heap.GeneralPurposeAllocator(.{
    .thread_safe = true,
});

const assert = std.debug.assert;

/// Aura
const core = @import("core");

const Router = @import("router.zig").Router;

const Application = core.application.Application(
    .{
        .interface = "127.0.0.1",
        .port = 3000,
        .thread_count = 2,
        .worker_count = 1,
    },
    Router,
);

/// Aura
pub fn main() !void {
    var gpa: GeneralPurpouseAllocator = .{};
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var app: Application = undefined;
    try app.init(allocator);
    defer app.deinit(allocator);

    try app.run();
}
