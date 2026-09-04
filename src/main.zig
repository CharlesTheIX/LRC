const std = @import("std");
const app = @import("app");
const lrc = @import("lrc");
const udp = @import("udp");
const http = @import("http");

pub fn main(init: std.process.Init) void {
    // Initialize the I/O system
    var io = init.io;
    const env_map = init.environ_map;
    var args_it = init.minimal.args.iterate();
    var arena: std.mem.Allocator = init.arena.allocator();

    // Set up stdout writer
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;
    defer stdout_file_writer.flush() catch @panic("Failed to flush stdout");

    // Set up stdin reader
    var stdin_buffer: [1024]u8 = undefined;
    var stdin_file_reader: std.Io.File.Reader = .init(.stdin(), io, &stdin_buffer);
    const stdin_reader = &stdin_file_reader.interface;

    _ = args_it.next(); // Skip the program name
    const init_command_slice = args_it.next() orelse "invalid";
    const init_command = app.Command.fromSlice(init_command_slice);
    switch (init_command) {
        .HTTP_SERVER => {
            var http_server = http.HttpServer.init(.{ .io = &io });
            defer http_server.deinit();
            return http_server.run() catch |err| std.debug.print("HTTP server error: {}\n", .{err});
        },
        .LRC => {
            // Init and run the application
            var lrc_app: lrc.LRC = undefined;
            lrc_app.init(.{ .io = &io, .env_map = env_map, .args_it = &args_it, .allocator = &arena, .reader = stdin_reader, .writer = stdout_writer });
            defer lrc_app.deinit();
            return lrc_app.run();
        },
        .UDP_SERVER => {
            var udp_server = udp.UdpServer.init(.{ .io = &io, .writer = stdout_writer, .args_it = &args_it });
            defer udp_server.deinit();
            return udp_server.run();
        },
        .Invalid => return app.showHelp(stdout_writer),
    }
}
