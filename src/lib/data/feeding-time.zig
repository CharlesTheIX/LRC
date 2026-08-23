const std = @import("std");

pub const FeedingTime = struct {
    file_path: *const [18:0]u8 = "data/feeding-times",

    pub fn init() FeedingTime {
        return FeedingTime{};
    }

    pub fn deinit(self: *FeedingTime) void {
        // Cleanup resources if needed
        _ = self;
    }

    pub fn readAll(self: *FeedingTime, io: *std.Io) void {
        const cwd = std.Io.Dir.cwd();
        const file = cwd.openFile(io.*, self.file_path, .{}) catch return;
        var buffer: [1024]u8 = undefined;
        const read_bytes = file.readPositionalAll(io.*, &buffer, 0) catch return;
        const content = buffer[0..read_bytes];
        var content_it = std.mem.splitSequence(u8, content, "\n");
        while (content_it.next()) |line| {
            if (line.len == 0) continue; // Skip empty lines
            if (line[0] == '#') continue; // Skip comment lines
            std.debug.print("{s}\n", .{line});
        }
    }
};
