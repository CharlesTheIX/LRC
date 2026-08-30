const std = @import("std");
const c = @cImport({
    @cInclude("sys/socket.h");
    @cInclude("netinet/in.h");
    @cInclude("arpa/inet.h");
    @cInclude("unistd.h");
    @cInclude("string.h");
});

const Props = struct { io: *std.Io, port: u16 = 8080, address: []const u8 = "0.0.0.0" };

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

    pub fn run(self: *HttpServer) !void {
        std.debug.print("Starting HTTP server on {s}:{d}\n", .{ self.address, self.port });

        const server_socket = c.socket(c.AF_INET, c.SOCK_STREAM, 0);
        if (server_socket < 0) {
            std.debug.print("Failed to create socket\n", .{});
            return error.SocketCreationFailed;
        }
        defer _ = c.close(server_socket);

        const opt: c_int = 1;
        _ = c.setsockopt(server_socket, c.SOL_SOCKET, c.SO_REUSEADDR, &opt, @sizeOf(c_int));

        var sockaddr: c.struct_sockaddr_in = undefined;
        sockaddr.sin_family = c.AF_INET;
        sockaddr.sin_port = c.htons(self.port);
        sockaddr.sin_addr.s_addr = c.htonl(c.INADDR_ANY);

        if (c.bind(server_socket, @ptrCast(&sockaddr), @sizeOf(c.struct_sockaddr_in)) < 0) {
            std.debug.print("Failed to bind socket\n", .{});
            return error.BindFailed;
        }

        if (c.listen(server_socket, 1) < 0) {
            std.debug.print("Failed to listen\n", .{});
            return error.ListenFailed;
        }

        std.debug.print("Server listening on port {d}\n", .{self.port});

        while (true) {
            var client_addr: c.struct_sockaddr_in = undefined;
            var client_addr_len: c_uint = @sizeOf(c.struct_sockaddr_in);

            const client_socket = c.accept(server_socket, @ptrCast(&client_addr), &client_addr_len);
            if (client_socket < 0) {
                std.debug.print("Failed to accept connection\n", .{});
                continue;
            }
            defer _ = c.close(client_socket);

            var buffer: [1024]u8 = undefined;
            const bytes_read = c.read(client_socket, &buffer, buffer.len);

            if (bytes_read <= 0) continue;

            const response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 13\r\n\r\nHello, World!";

            _ = c.write(client_socket, response, response.len);
        }
    }
};
