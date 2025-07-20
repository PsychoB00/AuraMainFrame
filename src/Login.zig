/// STD
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

/// Aura
const core = @import("core");
const Context = @import("MainFrame.zig").MainFrame.Context;
const login_page = @embedFile("pages/login.html");

/// Third Party
const zap = @import("zap");
const jwt = @import("jwt");

pub const LoginEndpoint = struct {
    path: []const u8,
    error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

    pub fn init(self: *LoginEndpoint, path: []const u8) void {
        self.path = path;
    }

    pub fn get(_: *LoginEndpoint, _: Allocator, _: *Context, r: zap.Request) !void {
        if (r.path) |path| {
            if (mem.eql(u8, path, "/login")) { // Login page
                try r.sendBody(login_page);
                r.setStatus(.ok);
            } else if (mem.eql(u8, path, "/login/aura_dome.svg")) { // Aura dome image
                try r.setHeader("content-type", "image/svg+xml");
                try r.sendBody(core.dome);
                r.setStatus(.ok);
            } else r.setStatus(.not_found);
        } else r.setStatus(.not_found);
    }

    pub fn post(_: *LoginEndpoint, a: Allocator, context: *Context, r: zap.Request) !void {
        if (r.path) |path| {
            if (mem.eql(u8, path, "/login")) { // Login information check and JWT bearer generation
                context.logger
                    .log(.info)
                    .time()
                    .scope("[POST] @ /login")
                    .print("Beginning login...")
                    .commit();

                if (r.body) |body| {
                    var it = mem.splitScalar(u8, body, '&');

                    // Pull username and password from request body
                    var name_pass: [2][]const u8 = .{ "", "" };
                    while (it.next()) |login_info| {
                        const eql_index = mem.indexOfScalar(u8, login_info, '=') orelse {
                            context.logger
                                .log(.err)
                                .time()
                                .scope("[POST] @ /login")
                                .print("Login information doesn't contain '='")
                                .commit();

                            r.setStatus(.bad_request);
                            return;
                        };

                        const key = login_info[0..eql_index];
                        const value = login_info[(eql_index + 1)..];

                        if (mem.eql(u8, key, "username")) name_pass[0] = value else if (mem.eql(u8, key, "password")) name_pass[1] = value;
                    }
                    if (name_pass[0].len == 0 or name_pass[1].len == 0) {
                        context.logger
                            .log(.err)
                            .time()
                            .scope("[POST] @ /login")
                            .print("Request body doesn't contain either \"username\" or \"password\"")
                            .commit();

                        r.setStatus(.bad_request);
                        return;
                    }

                    // Check if login informations are correct
                    const password = context.users.get(name_pass[0]);
                    if (password == null or !mem.eql(u8, name_pass[1], password.?)) {
                        // TODO add "invalid login informations"
                        const log = context.logger.log(.warn);
                        _ = log.time().scope("[POST] @ /login");
                        _ = log.printTryFmt("Invalid attempt to login with: {{ \"username\": \"{s}\", \"password\": \"{s}\" }}", .{ name_pass[0], name_pass[1] }) catch
                            log.print("Attempt to login with invalid login informations");
                        log.commit();

                        r.setStatus(.internal_server_error);
                        return;
                    }

                    // Generate JWT bearer
                    const payload: core.JWTPayload = .{
                        .sub = "1234567890",
                        .iat = std.time.timestamp(),
                        .exp = std.time.timestamp() + context.jwt_exp,
                    };
                    const jwt_token = try jwt.encode(a, .HS256, payload, .{
                        .key = context.jwt_key,
                    });
                    defer a.free(jwt_token);
                    const jwt_bearer = try std.fmt.allocPrint(a, "Bearer%{s}", .{jwt_token});
                    defer a.free(jwt_bearer);

                    try r.setCookie(.{
                        .name = zap.Auth.AuthScheme.Bearer.headerFieldStrFio(),
                        .value = jwt_bearer,
                        .max_age_s = @as(c_int, @intCast(context.jwt_exp)),
                        .path = "/",
                        .secure = true,
                        .http_only = true,
                    });
                    // NOTE: Make sure that usernames and passwords are max 256 byte long
                    context.logger
                        .log(.info)
                        .time()
                        .scope("[POST] @ /login")
                        .printFmt("Succesful login with: \"username\": \"{s}\"", .{name_pass[0]})
                        .commit();

                    try r.redirectTo("/dashboard", .permanent_redirect);
                } else r.setStatus(.bad_request);
            } else {
                const log = context.logger.log(.warn);
                _ = log.time().scope("[POST] @ /login");
                _ = log.printTryFmt("Path \"{s}\" NOT_FOUND", .{path}) catch
                    log.print("Path NOT_FOUND");
                log.commit();
                r.setStatus(.not_found);
            }
        } else r.setStatus(.bad_request);
    }
    pub fn put(_: *LoginEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
    pub fn delete(_: *LoginEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
    pub fn patch(_: *LoginEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
    pub fn options(_: *LoginEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
    pub fn head(_: *LoginEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
};
