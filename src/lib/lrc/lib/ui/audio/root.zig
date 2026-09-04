const std = @import("std");
const rl = @import("raylib");
const sliceToZSlice = @import("../../../utils.zig").sliceToZSlice;

const Props = struct {
    allocator: *std.mem.Allocator,
};

pub const Audio = struct {
    allocator: *std.mem.Allocator,
    sfxs: std.StringHashMap(rl.Sound),
    music: std.StringHashMap(rl.Music),

    // Base methods
    pub fn deinit(self: *Audio) void {
        var sfx_it = self.sfxs.iterator();
        while (sfx_it.next()) |entry| {
            rl.unloadSound(entry.value_ptr.*);
            self.allocator.free(entry.key_ptr.*);
        }
        self.sfxs.deinit();
        var music_it = self.music.iterator();
        while (music_it.next()) |entry| {
            rl.unloadMusicStream(entry.value_ptr.*);
            self.allocator.free(entry.key_ptr.*);
        }
        self.music.deinit();
    }

    pub fn init(props: Props) Audio {
        return Audio{
            .allocator = props.allocator,
            .sfxs = std.StringHashMap(rl.Sound).init(props.allocator.*),
            .music = std.StringHashMap(rl.Music).init(props.allocator.*),
        };
    }

    pub fn update(self: *Audio) void {
        var it = self.music.iterator();
        while (it.next()) |entry| rl.updateMusicStream(entry.value_ptr.*);
    }

    // Helper methods
    pub fn loadMusic(self: *Audio, name: []const u8, file_path: []const u8) !void {
        if (self.music.contains(name)) return;
        const path_z = try sliceToZSlice(self.allocator, file_path);
        defer self.allocator.free(path_z);
        const stream = try rl.loadMusicStream(path_z);
        errdefer rl.unloadMusicStream(stream);
        const key = try self.allocator.dupe(u8, name);
        try self.music.put(key, stream);
    }

    pub fn loadSfx(self: *Audio, name: []const u8, file_path: []const u8) !void {
        if (self.sfxs.contains(name)) return;
        const path_z = try sliceToZSlice(self.allocator, file_path);
        defer self.allocator.free(path_z);
        const sound = try rl.loadSound(path_z);
        errdefer rl.unloadSound(sound);
        const key = try self.allocator.dupe(u8, name);
        try self.sfxs.put(key, sound);
    }

    pub fn pauseMusic(self: *Audio, name: []const u8) void {
        const stream = self.music.get(name) orelse return;
        rl.pauseMusicStream(stream);
    }

    pub fn pauseSfx(self: *Audio, name: []const u8) void {
        const sound = self.sfxs.get(name) orelse return;
        rl.pauseSound(sound);
    }

    pub fn playMusic(self: *Audio, name: []const u8) void {
        const stream = self.music.get(name) orelse return;
        rl.playMusicStream(stream);
    }

    pub fn playSfx(self: *Audio, name: []const u8) void {
        const sound = self.sfxs.get(name) orelse return;
        rl.playSound(sound);
    }

    pub fn resumeMusic(self: *Audio, name: []const u8) void {
        const stream = self.music.get(name) orelse return;
        rl.resumeMusicStream(stream);
    }

    pub fn resumeSfx(self: *Audio, name: []const u8) void {
        const sound = self.sfxs.get(name) orelse return;
        rl.resumeSound(sound);
    }

    pub fn stopMusic(self: *Audio, name: []const u8) void {
        const stream = self.music.get(name) orelse return;
        rl.stopMusicStream(stream);
    }

    pub fn stopSfx(self: *Audio, name: []const u8) void {
        const sound = self.sfxs.get(name) orelse return;
        rl.stopSound(sound);
    }

    pub fn unloadMusic(self: *Audio, name: []const u8) void {
        const entry = self.music.fetchRemove(name) orelse return;
        rl.unloadMusicStream(entry.value);
        self.allocator.free(entry.key);
    }

    pub fn unloadSfx(self: *Audio, name: []const u8) void {
        const entry = self.sfxs.fetchRemove(name) orelse return;
        rl.unloadSound(entry.value);
        self.allocator.free(entry.key);
    }
};
