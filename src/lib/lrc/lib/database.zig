const std = @import("std");
const createDirectory = @import("utils.zig").createDirectory;

const Props = struct { io: *std.Io, env_map: *std.process.Environ.Map };

pub const Database = struct {
    io: *std.Io,
    env_map: *std.process.Environ.Map,
    directory_path: *const [13:0]u8 = ".lrc_database",

    pub fn deinit(self: *Database) void {
        // No resources to free in this example, but if there were, they would be freed here.
        _ = self;
    }

    pub fn init(props: Props) Database {
        const database = Database{ .env_map = props.env_map, .io = props.io };
        createDirectory(database.io, database.env_map, database.directory_path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => @panic("Failed to create database directory"),
        };
        return database;
    }
};
