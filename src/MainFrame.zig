/// STD
const std = @import("std");
const GeneralPurpouseAllocator = std.heap.GeneralPurposeAllocator(.{
    .thread_safe = true,
});
const Allocator = std.mem.Allocator;

/// Aura
const core = @import("core");
const LoginEndpoint = @import("Login.zig").LoginEndpoint;
const DashboardEndpoint = @import("Dashboard.zig").DashboardEndpoint;

const jwt_key = @embedFile("secret/jwt_key.txt");

/// Third Party
const zap = @import("zap");

/// Main server of Aura eco-system
pub const MainFrame = struct {
    pub const Context = struct {
        jwt_key: []const u8,
        jwt_exp: i64,

        users: std.StringHashMap([]const u8),

        /// Any unhandeled request will end up here
        pub fn unhandledRequest(_: *Context, _: Allocator, r: zap.Request) anyerror!void {
            if (r.path) |path| {
                if (path.len == 1) {
                    // redirect to login
                    try r.redirectTo("/login", null);
                    return;
                }
            }
            r.setStatus(.not_found);
        }
    };

    const App = zap.App.Create(Context);

    allocator: Allocator,

    context: Context,
    app: App,
    jwt_authenticator: core.JWTAuthenticator,

    login_ep: LoginEndpoint,
    dashboard_ep: core.JWTAuthEndpoint(DashboardEndpoint, App),

    /// Initialize MainFrame
    ///
    /// MUST CALL `deinit` to deinitialize
    pub fn init(self: *MainFrame, gpa: *GeneralPurpouseAllocator) !void {
        self.allocator = gpa.allocator();

        // Context
        self.context = .{
            .jwt_key = jwt_key,
            .jwt_exp = 3600,
            .users = std.StringHashMap([]const u8).init(self.allocator),
        };
        try self.context.users.put("mr_admin", "VeryUnsafe");
        try self.context.users.put("joe", "average_dude");

        // Application
        self.app = try App.init(
            self.allocator,
            &self.context,
            .{},
        );

        // JWT Authenticator
        self.jwt_authenticator = try core.JWTAuthenticator.init(self.allocator, self.context.jwt_key, null);

        // Register endpoints
        self.login_ep.init("/login");
        try self.app.register(&self.login_ep);

        self.dashboard_ep.init("/dashboard", &self.jwt_authenticator);
        try self.app.register(&self.dashboard_ep.auth_ep);
    }

    /// Listens and starts `zap` Application
    pub fn run(self: *MainFrame) !void {
        // Listen
        try self.app.listen(.{
            .interface = "127.0.0.1",
            .port = 4443,
        });

        // Start
        zap.start(.{
            .threads = 2,
            .workers = 1,
        });
    }

    /// Deinitialize MainFrame
    pub fn deinit(self: *MainFrame) void {
        self.jwt_authenticator.deinit();
        self.app.deinit();
        self.context.users.deinit();
    }
};
