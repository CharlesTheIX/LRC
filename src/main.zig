const std = @import("std");
const lrc = @import("lrc");

pub fn main(init: std.process.Init) void {
    // Initialize the I/O system
    var io = init.io;
    var args_it = init.minimal.args.iterate();
    const arena: std.mem.Allocator = init.arena.allocator();

    // Set up stdout writer
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    // Set up stdin reader
    var stdin_buffer: [1024]u8 = undefined;
    var stdin_file_reader: std.Io.File.Reader = .init(.stdin(), io, &stdin_buffer);
    const stdin_reader = &stdin_file_reader.interface;

    // Init and run the application
    var app = lrc.LRC.init(.{
        .io = &io,
        .allocator = arena,
        .args_it = &args_it,
        .reader = stdin_reader,
        .writer = stdout_writer,
    });
    defer app.deinit();
    app.run();
}
