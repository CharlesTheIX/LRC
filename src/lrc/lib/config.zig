const std = @import("std");
const createFile = @import("utils.zig").createFile;

const Props = struct {
    io: *std.Io,
    env_map: *std.process.Environ.Map,
};

pub const Config = struct {
    io: *std.Io,
    env_map: *std.process.Environ.Map,
    file_path: *const [11:0]u8 = ".lrc_config",

    pub fn deinit(self: *Config) void {
        // No resources to free in this example, but if there were, they would be freed here.
        _ = self;
    }

    pub fn init(props: Props) Config {
        const config = Config{ .env_map = props.env_map, .io = props.io };
        createFile(config.io, config.env_map, config.file_path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => @panic("Failed to create config file"),
        };
        return config;
    }
};
