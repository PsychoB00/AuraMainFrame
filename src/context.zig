/// STD
const std = @import("std");

const Allocator = std.mem.Allocator;

/// Aura
const core = @import("core");

const Environment = core.context.Environment;

const Logger = @import("logging.zig").Logger;

pub const Context = struct {
    environment: Environment,
    jwt_key: []const u8,
    logger: Logger,

    pub fn init(self: *Context, allocator: Allocator) anyerror!void {
        try self.environment.initAll(allocator);
        self.jwt_key = "01234567890123456789012345678901";
        self.logger.init(&self.environment);

        try self.logger.spawn();
    }

    pub fn deinit(self: *Context, allocator: Allocator) void {
        _ = allocator;

        self.logger.join();

        self.environment.deinit();
    }
};
