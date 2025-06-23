/// STD
const std = @import("std");
const debug = std.debug;
const log = std.log;
const GeneralPurpouseAllocator = std.heap.GeneralPurposeAllocator(.{
    .thread_safe = true,
});

/// Aura
const MainFrame = @import("MainFrame.zig").MainFrame;

pub const std_options: std.Options = .{
    .log_level = .info,
    .log_scope_levels = &[_]std.log.ScopeLevel{
        .{ .scope = .zap, .level = .debug },
    },
};

pub fn main() !void {
    var gpa: GeneralPurpouseAllocator = .{};
    defer debug.assert(gpa.deinit() == .ok);

    var mf: MainFrame = undefined;
    mf.init(&gpa) catch |err| {
        log.err("Error occured during MainFrame initialization. Cause -> {s}", .{@errorName(err)});
        return;
    };
    defer mf.deinit();

    mf.run() catch |err| {
        log.err("Error occured during MainFrame run. Cause -> {s}", .{@errorName(err)});
        return;
    };
}
