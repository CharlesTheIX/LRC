const std = @import("std");
const UI = @import("lib/ui/root.zig").UI;
const Config = @import("lib/config.zig").Config;
const Database = @import("lib/database.zig").Database;
const DateTime = @import("lib/date-time.zig").DateTime;
const Feeding = @import("lib/data/feeding.zig").Feeding;

const Props = struct {
    io: *std.Io,
    reader: *std.Io.Reader,
    writer: *std.Io.Writer,
    allocator: *std.mem.Allocator,
    env_map: *std.process.Environ.Map,
    args_it: *std.process.Args.Iterator,
};

pub const LRC = struct {
    /// Application core properties
    io: *std.Io,
    reader: *std.Io.Reader,
    writer: *std.Io.Writer,
    allocator: *std.mem.Allocator,
    env_map: *std.process.Environ.Map,
    // Application components
    ui: UI,
    config: Config,
    feeding: Feeding,
    database: Database,

    pub fn deinit(self: *LRC) void {
        self.ui.deinit();
        self.config.deinit();
        self.feeding.deinit();
        self.database.deinit();
        self.writer.flush() catch {};
    }

    pub fn init(props: Props) LRC {
        var args_it = props.args_it.*;
        _ = args_it.next(); // skip program name
        const database = Database.init(.{ .env_map = props.env_map, .io = props.io });
        const config = Config.init(.{ .env_map = props.env_map, .io = props.io });
        return LRC{
            .io = props.io,
            .env_map = props.env_map,
            .reader = props.reader,
            .writer = props.writer,
            .allocator = props.allocator,
            .config = config,
            .database = database,
            .ui = UI.init(.{ .allocator = props.allocator }),
            .feeding = Feeding.init(.{ .io = props.io, .env_map = props.env_map }),
        };
    }

    pub fn run(self: *LRC) void {
        self.ui.run();
    }
};
