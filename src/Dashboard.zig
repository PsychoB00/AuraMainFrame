/// STD
const std = @import("std");
const log = std.log;
const Allocator = std.mem.Allocator;

/// Aura
const Context = @import("MainFrame.zig").MainFrame.Context;
const dashboard_page = @embedFile("pages/dashboard.html");

/// Third Party
const zap = @import("zap");

pub const DashboardEndpoint = struct {
    path: []const u8,
    error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

    pub fn init(self: *DashboardEndpoint, path: []const u8) void {
        self.path = path;
    }

    pub fn unauthorized(_: *DashboardEndpoint, _: Allocator, _: *Context, r: zap.Request) !void {
        const bearer = zap.Auth.extractAuthHeader(.Bearer, &r) orelse "none";
        log.err("Attempted unauthorized access to dashboard {s}", .{bearer});
        r.setStatus(.unauthorized);
    }

    pub fn get(_: *DashboardEndpoint, _: Allocator, _: *Context, r: zap.Request) !void {
        try r.sendBody(dashboard_page);
        r.setStatus(.ok);
    }
    pub fn post(_: *DashboardEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
    pub fn put(_: *DashboardEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
    pub fn delete(_: *DashboardEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
    pub fn patch(_: *DashboardEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
    pub fn options(_: *DashboardEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
    pub fn head(_: *DashboardEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
};
