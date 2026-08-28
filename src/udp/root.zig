const std = @import("std");

const Props = struct {
    io: *std.Io,
    port: u16 = 8080,
    address: []const u8 = "127.0.0.1",
};

pub const UdpServer = struct {
    port: u16,
    io: *std.Io,
    address: []const u8,

    pub fn deinit(self: *UdpServer) void {
        _ = self;
    }

    pub fn init(props: Props) UdpServer {
        return UdpServer{ .io = props.io, .port = props.port, .address = props.address };
    }

    pub fn run(self: *UdpServer) void {
        std.debug.print("UDP server running on {s}:{d}\n", .{ self.address, self.port });
    }
};
