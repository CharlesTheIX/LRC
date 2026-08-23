const std = @import("std");
const FeedingTime = @import("lib/data/feeding-time.zig").FeedingTime;

const LrcProps = struct {
    io: *std.Io,
    reader: *std.Io.Reader,
    writer: *std.Io.Writer,
    allocator: std.mem.Allocator,
    args_it: *std.process.Args.Iterator,
};

pub const LRC = struct {
    io: *std.Io,
    reader: *std.Io.Reader,
    writer: *std.Io.Writer,
    allocator: std.mem.Allocator,

    pub fn init(props: LrcProps) LRC {
        var args_it = props.args_it.*;
        while (args_it.next()) |arg| std.debug.print("arg: {s}\n", .{arg});
        return LRC{ .io = props.io, .reader = props.reader, .writer = props.writer, .allocator = props.allocator };
    }

    pub fn deinit(self: *LRC) void {
        // Cleanup resources if needed
        self.writer.flush() catch {};
    }

    pub fn run(self: *LRC) void {
        self.writer.writeAll("Running LRC...\n") catch {};
        self.writer.flush() catch {};

        var feeding_time = FeedingTime.init();
        defer feeding_time.deinit();
        feeding_time.readAll(self.io);
    }
};
