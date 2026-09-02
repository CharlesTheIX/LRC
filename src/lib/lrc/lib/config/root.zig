const std = @import("std");
const createFile = @import("../../utils.zig").createFile;
const readFile = @import("../../utils.zig").readFile;
const writeFile = @import("../../utils.zig").writeFile;

const Props = struct { io: *std.Io, env_map: *std.process.Environ.Map, allocator: *std.mem.Allocator, args_it: *std.process.Args.Iterator };

pub const Config = struct {
    io: *std.Io,
    data: ConfigData = .{},
    env_map: *std.process.Environ.Map,
    file_path: *const [11:0]u8 = ".lrc_config",

    pub fn deinit(self: *Config) void {
        _ = self;
    }

    pub fn init(props: Props) Config {
        var args_it = props.args_it.*;
        _ = args_it.next(); // skip program name
        var file_exists = false;
        var config = Config{ .env_map = props.env_map, .io = props.io };
        createFile(config.io, config.env_map, config.file_path) catch |err| switch (err) {
            error.PathAlreadyExists => file_exists = true,
            else => @panic("Failed to create config file"),
        };
        if (!file_exists) {
            const example_content = "";
            writeFile(props.io, props.env_map, config.file_path, example_content) catch @panic("Failed to write initial config file");
        }
        const content = readFile(props.io, props.env_map, props.allocator, config.file_path) catch @panic("Failed to read config file");
        defer props.allocator.free(content);
        config.extractDataFromFile(content) catch @panic("Failed to parse config file");
        return config;
    }

    fn extractDataFromFile(self: *Config, content: []const u8) !void {
        _ = self;
        _ = content;
    }
};

const ConfigData = struct {
    time_diff_from_utc: i32 = 0,
};
