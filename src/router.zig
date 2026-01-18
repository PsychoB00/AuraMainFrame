/// Aura
const core = @import("core");

const RouterType = core.routing.Router;

const ClaimsSet = core.jwt.ClaimsSet;
const JWTAuthorizationProcessor = core.jwt.JWTAuthorizationProcessor;
const LoggingOnRequestProcessor = core.routing.LoggingOnRequestProcessor;

const ResourceTree = @import("resource_tree.zig").ResourceTree;
const Context = @import("context.zig").Context;
const AuthorizationProcessor = JWTAuthorizationProcessor(ClaimsSet);
const OnRequestProcessor = LoggingOnRequestProcessor(Context);

pub const Router = RouterType(
    ResourceTree,
    Context,
    AuthorizationProcessor,
    OnRequestProcessor,
);
