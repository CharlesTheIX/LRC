const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const readAsset = @import("../../utils.zig").readAsset;
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

pub const Action = utils.Action;
pub const Direction = utils.Direction;
pub const ActionData = utils.ActionData;
pub const ActionRects = utils.ActionRects;

const Props = struct { name: []const u8, allocator: *std.mem.Allocator, io: *std.Io };
pub const Sprite = struct {
    name: utils.SpriteName,
    is_moving: bool = false,
    allocator: *std.mem.Allocator,
    texture: ?rl.Texture2D = null,
    current_action: Action = .Idle,
    direction: Direction = .Down,
    run_data: utils.ActionData = .init(),
    idle_data: utils.ActionData = .init(),
    rest_data: utils.ActionData = .init(),
    walk_data: utils.ActionData = .init(),
    position: rl.Vector2 = rl.Vector2.init(0, 0),
    target_position: rl.Vector2 = rl.Vector2.init(0, 0),

    // base methods
    pub fn deinit(self: *Sprite) void {
        if (self.texture) |tex| {
            rl.unloadTexture(tex);
            self.texture = null;
        }
    }

    pub fn draw(self: *Sprite) void {
        self.drawLowerRect();
        self.drawUpperRect();
        self.drawHitbox();
        self.drawCenter();
    }

    pub fn init(props: Props) Sprite {
        var buffer: [128]u8 = undefined;
        var sprite = Sprite{ .name = utils.SpriteName.fromSlice(props.name), .allocator = props.allocator };
        const texture_path = sprite.name.getTexturePath(&buffer);
        if (texture_path) |path| sprite.texture = rl.loadTexture(path) catch @panic("Failed to load texture");
        buffer = undefined;
        const data_path = sprite.name.getDataPath(&buffer);
        if (data_path) |path| {
            const content = readAsset(props.io, props.allocator, path) catch @panic("Failed to read file");
            defer props.allocator.free(content);
            sprite.extractData(content);
        }
        return sprite;
    }

    // helper methods
    fn drawCenter(self: *Sprite) void {
        const hitbox = self.getHitboxRect(null);
        const center = rl.Vector2.init(hitbox.x + hitbox.width / 2, hitbox.y + hitbox.height / 2);
        rl.drawCircleV(center, 2.0, rl.Color.red);
    }

    fn drawHitbox(self: *Sprite) void {
        const rects_data = self.getActionData(self.current_action).rects;
        var rect = rects_data.hitbox orelse return;
        const origin = self.getOrigin();
        rect.x += origin.x;
        rect.y += origin.y;
        rl.drawRectangleRec(rect, rl.Color.red.alpha(0.5));
    }

    fn drawLowerRect(self: *Sprite) void {
        if (self.texture) |texture| {
            const rects_data = self.getActionData(self.current_action).rects;
            var rect = rects_data.lower orelse return;
            const frame = self.getActiveFrame();
            const origin = self.getOrigin();
            const src = rl.Rectangle{ .x = frame.x + rect.x, .y = frame.y + rect.y, .width = rect.width, .height = rect.height };
            rect.x += origin.x;
            rect.y += origin.y;
            rl.drawTexturePro(texture, src, rect, rl.Vector2.zero(), 0.0, rl.Color.white);
        }
    }

    pub fn drawUpperRect(self: *Sprite) void {
        if (self.texture) |texture| {
            const rects_data = self.getActionData(self.current_action).rects;
            var rect = rects_data.upper orelse return;
            const frame = self.getActiveFrame();
            const origin = self.getOrigin();
            const src = rl.Rectangle{ .x = frame.x + rect.x, .y = frame.y + rect.y, .width = rect.width, .height = rect.height };
            rect.x += origin.x;
            rect.y += origin.y;
            rl.drawTexturePro(texture, src, rect, rl.Vector2.zero(), 0.0, rl.Color.white);
        }
    }

    pub fn getActionData(self: *const Sprite, action: Action) ActionData {
        return switch (action) {
            .Run => self.run_data,
            .Idle => self.idle_data,
            .Rest => self.rest_data,
            .Walk => self.walk_data,
        };
    }

    fn getActiveFrame(self: *Sprite) rl.Rectangle {
        const data = self.getActionData(self.current_action);
        const rects_data = data.rects;
        var core = rects_data.core orelse return .{ .x = 0, .y = 0, .width = 0, .height = 0 };
        const frame_count = data.frame_count orelse 1;
        const frame_duration = data.frame_duration orelse 0.12;
        var frame_index: u8 = 0;
        if (self.is_moving or self.current_action == .Rest) {
            frame_index = @as(u8, @intFromFloat(@mod(rl.getTime() / frame_duration, @as(f32, @floatFromInt(frame_count)))));
        }
        const spritesheet_offset = data.spritesheet_offset orelse rl.Vector2.zero();
        const direction_offset = self.getDirectionOffset();
        core.x = spritesheet_offset.x + direction_offset.x + core.width * @as(f32, @floatFromInt(frame_index));
        core.y = spritesheet_offset.y + direction_offset.y;
        return core;
    }

    fn getDirectionOffset(self: *const Sprite) rl.Vector2 {
        const fallback = rl.Vector2.zero();
        const data = self.getActionData(self.current_action);
        return switch (self.direction) {
            .Up => data.directions.up orelse fallback,
            .Down => data.directions.down orelse fallback,
            .Left => data.directions.left orelse fallback,
            .Right => data.directions.right orelse fallback,
            .UpLeft => data.directions.up_left orelse data.directions.left orelse fallback,
            .UpRight => data.directions.up_right orelse data.directions.right orelse fallback,
            .DownLeft => data.directions.down_left orelse data.directions.left orelse fallback,
            .DownRight => data.directions.down_right orelse data.directions.right orelse fallback,
        };
    }

    pub fn getHitboxRect(self: *Sprite, target: ?rl.Vector2) rl.Rectangle {
        const position = target orelse self.position;
        const rects_data = self.getActionData(self.current_action).rects;
        const hitbox = rects_data.hitbox orelse return .{ .x = position.x, .y = position.y, .width = 0, .height = 0 };
        return rl.Rectangle{
            .x = position.x - hitbox.width / 2,
            .y = position.y - hitbox.height / 2,
            .width = hitbox.width,
            .height = hitbox.height,
        };
    }

    fn getOrigin(self: *Sprite) rl.Vector2 {
        const rects_data = self.getActionData(self.current_action).rects;
        const hitbox = rects_data.hitbox orelse return self.position;
        const hitbox_center_offset = rl.Vector2.init(hitbox.x + hitbox.width / 2, hitbox.y + hitbox.height / 2);
        return rl.Vector2.init(self.position.x - hitbox_center_offset.x, self.position.y - hitbox_center_offset.y);
    }

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
