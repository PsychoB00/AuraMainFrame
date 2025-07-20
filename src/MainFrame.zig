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

const raw_jwt_key = @embedFile("secret/jwt_key.txt");

const LoggerOptions = core.log.LoggerOptions{
    .log_pool_size = 64,
};
const LogOptions = core.log.LogOptions{};
const LogFmtOptions = core.log.LogFmtOptions{};

const Log = core.log.Log(LogOptions);
const LogProcessor = core.log.ConsoleLogProcessor(Log, LogFmtOptions);
const Logger = core.log.Logger(LoggerOptions, Log, LogProcessor);

/// Third Party
const zeit = @import("zeit");
const zap = @import("zap");

/// Main server of Aura eco-system
pub const MainFrame = struct {
    pub const Context = struct {
        jwt_key: []const u8,
        jwt_exp: i64,

        logger: *Logger,

        users: std.StringHashMap([]const u8),

        /// Initialize MainFrame.Context
        ///
        /// MUST CALL `deinit` to deinitialize
        pub fn init(jwt_key: []const u8, jwt_exp: i64, logger: *Logger, allocator: Allocator) !Context {
            return .{
                .jwt_key = jwt_key,
                .jwt_exp = jwt_exp,
                .logger = logger,
                .users = std.StringHashMap([]const u8).init(allocator),
            };
        }

        /// Deinitialize MainFrame.Context
        pub fn deinit(self: *Context) void {
            self.users.deinit();
        }

        /// Any unhandeled request will end up here
        pub fn unhandledRequest(context: *Context, _: Allocator, r: zap.Request) anyerror!void {
            if (r.path) |path| {
                if (path.len == 1) {
                    // redirect to login
                    try r.redirectTo("/login", null);
                    return;
                } else {
                    const log = context.logger.log(.warn);
                    _ = log.time().scope("Context.unhandledRequest");
                    _ = log.printTryFmt("Path \"{s}\" NOT_FOUND", .{path}) catch
                        log.print("Path NOT_FOUND");
                    log.commit();
                }
            }
            r.setStatus(.not_found);
        }
    };

    const App = zap.App.Create(Context);

    allocator: Allocator,
    env: std.process.EnvMap,
    timezone: zeit.TimeZone,

    logger: Logger,
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
        self.env = std.process.EnvMap.init(self.allocator);
        self.timezone = try zeit.local(self.allocator, &self.env);

        // Logger
        self.logger = Logger.init(&self.timezone);
        try self.logger.spawn();

        // Context
        self.context = try Context.init(
            raw_jwt_key,
            3600,
            &self.logger,
            self.allocator,
        );
        try self.context.users.put("mr_admin", "VeryUnsafe");
        try self.context.users.put("joe", "average_dude");

        // Application
        self.app = try App.init(
            self.allocator,
            &self.context,
            .{},
        );

        // JWT Authenticator
        self.jwt_authenticator = try core.JWTAuthenticator.init(
            self.allocator,
            self.context.jwt_key,
            null,
        );

        // Register endpoints
        self.login_ep.init("/login");
        try self.app.register(&self.login_ep);

        self.dashboard_ep.init("/dashboard", &self.jwt_authenticator);
        try self.app.register(&self.dashboard_ep.auth_ep);

        self.logger
            .log(.info)
            .time()
            .scope("init")
            .print("MainFrame initialized...")
            .commit();
    }

    /// Listens and starts `zap` Application
    pub fn run(self: *MainFrame) !void {
        // Listen
        try self.app.listen(.{
            .interface = "127.0.0.1",
            .port = 4443,
        });

        // Start
        self.logger
            .log(.info)
            .time()
            .scope("run")
            .print("MainFrame starting...")
            .commit();

        zap.start(.{
            .threads = 2,
            .workers = 1,
        });

        self.logger
            .log(.info)
            .time()
            .scope("run")
            .print("MainFrame shutting down...")
            .commit();
    }

    /// Deinitialize MainFrame
    pub fn deinit(self: *MainFrame) void {
        self.logger
            .log(.info)
            .time()
            .scope("deinit")
            .print("MainFrame deinitializing...")
            .commit();

        self.jwt_authenticator.deinit();
        self.app.deinit();
        self.context.deinit();
        self.logger.join();
        self.timezone.deinit();
        self.env.deinit();
    }
};
