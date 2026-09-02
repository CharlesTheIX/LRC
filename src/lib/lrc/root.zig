const std = @import("std");
const UI = @import("lib/ui/root.zig").UI;
const BabyData = @import("lib/baby_data/root.zig").BabyData;
const DateTime = @import("lib/date_time/root.zig").DateTime;

const Props = struct {
    io: *std.Io,
    reader: *std.Io.Reader,
    writer: *std.Io.Writer,
    allocator: *std.mem.Allocator,
    env_map: *std.process.Environ.Map,
    args_it: *std.process.Args.Iterator,
};

pub const LRC = struct {
    ui: UI,
    io: *std.Io,
    baby_data: BabyData,
    reader: *std.Io.Reader,
    writer: *std.Io.Writer,
    allocator: *std.mem.Allocator,
    env_map: *std.process.Environ.Map,

    pub fn deinit(self: *LRC) void {
        self.ui.deinit();
        self.baby_data.deinit();
    }

    pub fn init(self: *LRC, props: Props) void {
        self.loadArgs(props.args_it);
        self.* = LRC{
            .ui = undefined,
            .io = props.io,
            .env_map = props.env_map,
            .reader = props.reader,
            .writer = props.writer,
            .allocator = props.allocator,
            .baby_data = BabyData.init(.{ .env_map = props.env_map, .io = props.io, .allocator = props.allocator }),
        };
        UI.init(&self.ui, .{ .allocator = props.allocator, .baby_data = &self.baby_data });
    }

    fn load(self: *LRC) void {
        _ = self;
    }

    fn loadArgs(self: *LRC, args_it: *std.process.Args.Iterator) void {
        _ = self;
        var args = args_it.*;
        while (args.next()) |arg| {
            _ = arg;
            // Process each argument as needed
        }
    }

    pub fn run(self: *LRC) void {
        self.ui.run();
    }
};
