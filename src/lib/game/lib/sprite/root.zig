const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const readAsset = @import("../../utils.zig").readAsset;
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

const Props = struct { name: []const u8, allocator: *std.mem.Allocator, io: *std.Io };

pub const Action = utils.Action;
pub const ActionData = utils.ActionData;
pub const ActionRects = utils.ActionRects;
pub const Direction = utils.Direction;

pub const Sprite = struct {
    name: utils.SpriteName,
    allocator: *std.mem.Allocator,
    texture: ?rl.Texture2D = null,
    run_data: utils.ActionData = .init(),
    idle_data: utils.ActionData = .init(),
    rest_data: utils.ActionData = .init(),
    walk_data: utils.ActionData = .init(),

    // base methods
    pub fn deinit(self: *Sprite) void {
        if (self.texture) |tex| {
            rl.unloadTexture(tex);
            self.texture = null;
        }
    }

    pub fn init(props: Props) Sprite {
        var sprite = Sprite{ .name = utils.SpriteName.fromSlice(props.name), .allocator = props.allocator };
        sprite.load(props.io);
        return sprite;
    }

    pub fn actionData(self: *const Sprite, action: Action) ActionData {
        return switch (action) {
            .Idle => self.idle_data,
            .Rest => self.rest_data,
            .Run => self.run_data,
            .Walk => self.walk_data,
        };
    }

    fn load(self: *Sprite, io: *std.Io) void {
        var buffer: [128]u8 = undefined;
        const texture_path = self.name.getTexturePath(&buffer);
        if (texture_path) |path| self.texture = rl.loadTexture(path) catch @panic("Failed to load texture");
        buffer = undefined;
        const data_path = self.name.getDataPath(&buffer);
        if (data_path) |path| {
            const content = readAsset(io, self.allocator, path) catch @panic("Failed to read file");
            defer self.allocator.free(content);
            self.extractData(content);
        }
    }

    // helper methods
    fn extractData(self: *Sprite, content: []const u8) void {
        var line_it = std.mem.splitSequence(u8, content, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) continue; // Skip empty lines
            if (line[0] == '#') continue; // Skip comment lines
            var key_value = std.mem.splitSequence(u8, line, ":");
            const key = key_value.first();
            const value = key_value.rest();
            utils.extractActionData(&self.run_data, "run", key, value);
            utils.extractActionData(&self.idle_data, "idle", key, value);
            utils.extractActionData(&self.walk_data, "walk", key, value);
            utils.extractActionData(&self.rest_data, "rest", key, value);
        }
    }
};
