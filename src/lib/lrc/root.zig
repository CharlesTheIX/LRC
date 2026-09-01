const std = @import("std");
const UI = @import("lib/ui/root.zig").UI;
const Feeding = @import("lib/feeding/root.zig").Feeding;
const DateTime = @import("lib/date_time/root.zig").DateTime;

const Props = struct { io: *std.Io, reader: *std.Io.Reader, writer: *std.Io.Writer, allocator: *std.mem.Allocator, env_map: *std.process.Environ.Map, args_it: *std.process.Args.Iterator };

pub const LRC = struct {
    ui: UI,
    io: *std.Io,
    feeding: Feeding,
    reader: *std.Io.Reader,
    writer: *std.Io.Writer,
    allocator: *std.mem.Allocator,
    env_map: *std.process.Environ.Map,

    pub fn deinit(self: *LRC) void {
        self.ui.deinit();
        self.feeding.deinit();
        self.writer.flush() catch {};
    }

    pub fn init(self: *LRC, props: Props) void {
        var args_it = props.args_it.*;
        _ = args_it.next(); // skip program name
        const feeding = Feeding.init(.{ .env_map = props.env_map, .io = props.io, .allocator = props.allocator });
        self.* = LRC{
            .ui = undefined,
            .io = props.io,
            .feeding = feeding,
            .env_map = props.env_map,
            .reader = props.reader,
            .writer = props.writer,
            .allocator = props.allocator,
        };
        UI.init(&self.ui, .{ .allocator = props.allocator, .feeding = &self.feeding });
    }

    fn load(self: *LRC) void {
        _ = self;
    }

    pub fn run(self: *LRC) void {
        self.ui.run();
    }
};
