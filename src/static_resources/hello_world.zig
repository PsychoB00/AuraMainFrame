/// Aura
const core = @import("core");

const StaticResource = core.routing.StaticResource;

pub const HelloWorld = StaticResource(
    "zig-out/resources/hello_world.html",
    .{},
    .{
        .authorize = null,
    },
);
