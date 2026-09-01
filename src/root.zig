const std = @import("std");

pub const Command = enum {
    LRC,
    UDP_SERVER,
    HTTP_SERVER,
    Invalid,

    pub fn fromSlice(slice: []const u8) Command {
        if (std.mem.eql(u8, slice, "lrc")) return .LRC;
        if (std.mem.eql(u8, slice, "udp-server")) return .UDP_SERVER;
        if (std.mem.eql(u8, slice, "http-server")) return .HTTP_SERVER;
        return .Invalid;
    }

    pub fn toSlice(self: Command) []const u8 {
        switch (self) {
            .LRC => return "lrc",
            .UDP_SERVER => return "udp-server",
            .HTTP_SERVER => return "http-server",
            .Invalid => return "invalid",
        }
    }
};

pub fn showHelp(writer: *std.Io.Writer) void {
    writer.print("Usage: lrc <command>\n", .{}) catch {};
    writer.print("Commands:\n", .{}) catch {};
    writer.print("  udp-server   Run the UDP server\n", .{}) catch {};
    writer.print("  http-server  Run the HTTP server\n", .{}) catch {};
    writer.print("  lrc          Run the LRC application\n", .{}) catch {};
    writer.flush() catch {};
}
