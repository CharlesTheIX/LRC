const std = @import("std");

const Props = struct { io: *std.Io, port: u16 = 8080, address: []const u8 = "127.0.0.1" };

pub const HttpServer = struct {
    port: u16,
    io: *std.Io,
    address: []const u8,

    pub fn deinit(self: *HttpServer) void {
        _ = self;
    }

    pub fn init(props: Props) HttpServer {
        return HttpServer{ .io = props.io, .port = props.port, .address = props.address };
    }

    pub fn run(self: *HttpServer) void {
        std.debug.print("Starting HTTP server on {s}:{d}\n", .{ self.address, self.port });
    }
};
