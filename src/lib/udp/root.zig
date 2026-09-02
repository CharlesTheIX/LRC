const std = @import("std");
const utils = @import("./utils.zig");

const Props = struct { io: *std.Io, port: u16 = 8080, writer: *std.Io.Writer, address: []const u8 = "127.0.0.1", args_it: *std.process.Args.Iterator };

pub const UdpServer = struct {
    port: u16,
    io: *std.Io,
    address: []const u8,
    writer: *std.Io.Writer,

    pub fn deinit(self: *UdpServer) void {
        self.writer.flush() catch @panic("Failed to flush writer");
    }

    pub fn init(props: Props) UdpServer {
        var udp_server = UdpServer{ .io = props.io, .port = props.port, .address = props.address, .writer = props.writer };
        udp_server.loadArgs(props.args_it);
        utils.validatePort(udp_server.port);
        utils.validateAddress(udp_server.address);
        return udp_server;
    }

    fn getReply(self: *UdpServer, msg: []const u8) []const u8 {
        _ = self;
        if (std.mem.eql(u8, msg, "ping")) return "pong";
        if (std.mem.startsWith(u8, msg, "ECHO ")) return msg[5..];
        return "invalid";
    }

    fn loadArgs(self: *UdpServer, args_it: *std.process.Args.Iterator) void {
        var args = args_it.*;
        while (args.next()) |arg| {
            var key_value = std.mem.splitSequence(u8, arg, "=");
            const key = key_value.next() orelse continue;
            const value = key_value.next() orelse continue;
            if (std.mem.eql(u8, key, "address")) self.address = value;
            if (std.mem.eql(u8, key, "port")) self.port = std.fmt.parseInt(u16, value, 10) catch @panic("Invalid port number");
        }
    }

    pub fn run(self: *UdpServer) void {
        var buffer: [1024]u8 = undefined;
        const address = std.Io.net.IpAddress.parse(self.address, self.port) catch @panic("Failed to parse IP address");
        const socket = address.bind(self.io.*, .{ .mode = .dgram }) catch @panic("Failed to bind socket");
        defer socket.close();
        const start_up_msg = std.fmt.bufPrint(&buffer, "UDP server running on {s}:{d}\n", .{ self.address, self.port }) catch "UDP server running\n";
        self.writer.writeAll(start_up_msg) catch @panic("Failed to write startup message");
        self.writer.flush() catch @panic("Failed to flush writer");
        buffer = undefined;
        while (true) {
            const incoming_msg = socket.receive(self.io.*, &buffer) catch @panic("Failed to receive data");
            socket.send(self.io.*, &incoming_msg.from, self.getReply(incoming_msg.data)) catch @panic("Failed to send response");
            buffer = undefined;
        }
    }
};

pub const UdpClient = struct {};
