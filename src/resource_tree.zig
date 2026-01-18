const HelloWorld = @import("static_resources/hello_world.zig").HelloWorld;

pub const ResourceTree = struct {
    pub const pages = struct {
        pub const hello_world = HelloWorld;
    };
};
