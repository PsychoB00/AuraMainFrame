/// Aura
const core = @import("core");

const LogOptions = core.log.LogOptions{};
const LogFmtOptions = core.log.LogFmtOptions{};
const LoggerOptions = core.log.LoggerOptions{};

const Log = core.log.Log(LogOptions);
const LogProcessor = core.log.ConsoleLogProcessor(Log, LogFmtOptions, null);
pub const Logger = core.log.Logger(Log, LogProcessor, LoggerOptions);
