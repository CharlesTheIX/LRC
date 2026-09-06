const std = @import("std");
const utils = @import("../../utils.zig");
const Game = @import("../../root.zig").Game;

const save_file_path = ".game_save_data";
const Props = struct { allocator: *std.mem.Allocator, io: *std.Io, env_map: *std.process.Environ.Map };

pub const SaveData = struct {
    io: *std.Io,
    time: f64 = 0,
    name: []const u8 = "Player",
    allocator: *std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    env_map: *std.process.Environ.Map,

    // Base methods
    pub fn deinit(self: *SaveData) void {
        self.arena.deinit();
    }

    pub fn init(props: Props) SaveData {
        return SaveData{
            .io = props.io,
            .env_map = props.env_map,
            .allocator = props.allocator,
            .arena = std.heap.ArenaAllocator.init(props.allocator.*),
        };
    }

    pub fn load(self: *SaveData) void {
        var save_file_exists = false;
        utils.createFile(self.io, self.env_map, save_file_path) catch |err| switch (err) {
            error.PathAlreadyExists => save_file_exists = true,
            else => @panic("Failed to create save file"),
        };
        if (!save_file_exists) {
            const example_content = "time:0\nname:Player\n";
            utils.writeFile(self.io, self.env_map, save_file_path, example_content) catch @panic("Failed to write initial body items data file");
        }
        var arena_allocator = self.arena.allocator();
        const content = utils.readFile(self.io, self.env_map, &arena_allocator, save_file_path) catch @panic("Failed to read save file");
        extractSaveContent(self, content);
    }

    // Helper methods
    fn extractSaveContent(self: *SaveData, content: []const u8) void {
        var lines = std.mem.splitSequence(u8, content, "\n");
        while (lines.next()) |line| {
            var parts = std.mem.splitSequence(u8, line, ":");
            const key = parts.next() orelse continue;
            const value = parts.next() orelse continue;
            if (std.mem.eql(u8, key, "name")) self.name = value;
            if (std.mem.eql(u8, key, "time")) self.time = std.fmt.parseFloat(f64, value) catch @panic("Failed to parse time from save file");
        }
    }

    pub fn reset(self: *SaveData) void {
        utils.deleteFile(self.io, self.env_map, save_file_path) catch @panic("Failed to delete save file");
        self.time = 0;
        self.name = "Player";
        _ = self.arena.reset(.retain_capacity);
        self.load();
    }

    pub fn tempSave(self: *SaveData, game: *Game) void {
        self.name = "Player";
        self.time = game.game_timer.current_time;
    }

    pub fn save(self: *SaveData) void {
        var buffer: [1024]u8 = undefined;
        const content = std.fmt.bufPrint(
            &buffer,
            "time:{d}\nname:{s}\n",
            .{ self.time, self.name },
        ) catch @panic("Failed to format save data");
        utils.writeFile(self.io, self.env_map, save_file_path, content) catch @panic("Failed to write save file");
    }
};
