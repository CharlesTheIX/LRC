const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const Game = @import("../../root.zig").Game;
const Key = @import("../input_handler/root.zig").Key;
const readAsset = @import("../../utils.zig").readAsset;
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

const Props = struct { name: []const u8, allocator: *std.mem.Allocator, io: *std.Io, sprite_type: utils.SpriteType };
pub const Sprite = struct {
    name: utils.SpriteName,
    is_moving: bool = false,
    frame_elapsed: f32 = 0.0,
    action_elapsed: f32 = 0.0,
    is_sprinting: bool = false,
    current_cycle: ?u32 = null,
    action: utils.Action = .Walk,
    sprite_type: utils.SpriteType,
    texture: ?rl.Texture2D = null,
    allocator: *std.mem.Allocator,
    position: utils.Position = .{},
    direction: utils.Direction = .Down,
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

    pub fn draw(self: *Sprite) void {
        self.drawLowerRect();
        self.drawUpperRect();
        // self.drawHitbox();
        // self.drawCenter();
    }

    pub fn init(props: Props) Sprite {
        var buffer: [128]u8 = undefined;
        var sprite = Sprite{ .name = utils.SpriteName.fromSlice(props.name), .allocator = props.allocator, .sprite_type = props.sprite_type };
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

    pub fn update(self: *Sprite, game: *Game) void {
        self.frame_elapsed += rl.getFrameTime();
        switch (self.sprite_type) {
            .Player => return self.updatePlayer(game),
            else => return,
        }
    }

    // helper methods
    fn drawCenter(self: *Sprite) void {
        const hitbox = self.getHitboxRect(null);
        const center = rl.Vector2.init(hitbox.x + hitbox.width / 2, hitbox.y + hitbox.height / 2);
        rl.drawCircleV(center, 2.0, rl.Color.red);
    }

    fn drawHitbox(self: *Sprite) void {
        const origin = self.getOrigin();
        var rect = self.getActionData(self.action).rects.hitbox orelse return;
        rect.x += origin.x;
        rect.y += origin.y;
        rl.drawRectangleRec(rect, rl.Color.red.alpha(0.5));
    }

    fn drawLowerRect(self: *Sprite) void {
        if (self.texture) |texture| {
            const origin = self.getOrigin();
            const frame = self.getActiveFrame();
            var rect = self.getActionData(self.action).rects.lower orelse return;
            const src = rl.Rectangle{ .x = frame.x + rect.x, .y = frame.y + rect.y, .width = rect.width, .height = rect.height };
            rect.x += origin.x;
            rect.y += origin.y;
            rl.drawTexturePro(texture, src, rect, rl.Vector2.zero(), 0.0, rl.Color.white);
        }
    }

    pub fn drawUpperRect(self: *Sprite) void {
        if (self.texture) |texture| {
            const origin = self.getOrigin();
            const frame = self.getActiveFrame();
            var rect = self.getActionData(self.action).rects.upper orelse return;
            const src = rl.Rectangle{ .x = frame.x + rect.x, .y = frame.y + rect.y, .width = rect.width, .height = rect.height };
            rect.x += origin.x;
            rect.y += origin.y;
            rl.drawTexturePro(texture, src, rect, rl.Vector2.zero(), 0.0, rl.Color.white);
        }
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

    pub fn getActionData(self: *const Sprite, action: ?utils.Action) utils.ActionData {
        const _action = action orelse self.action;
        return switch (_action) {
            .Run => self.run_data,
            .Idle => self.idle_data,
            .Rest => self.rest_data,
            .Walk => self.walk_data,
        };
    }

    fn getActiveFrame(self: *Sprite) rl.Rectangle {
        var frame_index: u8 = 0;
        const data = self.getActionData(self.action);
        const direction_offset = self.getDirectionOffset();
        const should_update_frame = self.is_moving or self.action == .Rest or self.action == .Idle;
        const frame_count = data.frame_count orelse 1;
        const frame_duration = data.frame_duration orelse 0.12;
        const spritesheet_offset = data.spritesheet_offset orelse rl.Vector2.zero();
        var core = data.rects.core orelse return .{ .x = 0, .y = 0, .width = 0, .height = 0 };
        if (should_update_frame) frame_index = @intFromFloat(@mod(self.frame_elapsed / frame_duration, @as(f32, @floatFromInt(frame_count))));
        core.x = spritesheet_offset.x + direction_offset.x + core.width * @as(f32, @floatFromInt(frame_index));
        core.y = spritesheet_offset.y + direction_offset.y;
        return core;
    }

    fn getDirectionOffset(self: *const Sprite) rl.Vector2 {
        const fallback = rl.Vector2.zero();
        const data = self.getActionData(self.action);
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

    fn getHasCompletedAnimationCycles(self: *const Sprite, data: utils.ActionData) bool {
        const cycle_counts = data.cycle_counts orelse return false;
        if (cycle_counts[0] == 0) return false;
        const frame_count = data.frame_count orelse 1;
        const frame_duration = data.frame_duration orelse 0.12;
        const cycle_duration = frame_duration * @as(f32, @floatFromInt(frame_count)) * @as(f32, @floatFromInt(cycle_counts[0]));
        return cycle_duration > 0.0 and self.frame_elapsed >= cycle_duration;
    }

    pub fn getHitboxRect(self: *Sprite, position: ?rl.Vector2) rl.Rectangle {
        const _position = position orelse self.position.current;
        const hitbox = self.getActionData(self.action).rects.hitbox orelse return .{ .x = _position.x, .y = _position.y, .width = 0, .height = 0 };
        return rl.Rectangle{ .x = _position.x - hitbox.width / 2, .y = _position.y - hitbox.height / 2, .width = hitbox.width, .height = hitbox.height };
    }

    fn getOrigin(self: *Sprite) rl.Vector2 {
        const position = self.position.current;
        const hitbox = self.getActionData(self.action).rects.hitbox orelse return position;
        const hitbox_center_offset = rl.Vector2.init(hitbox.x + hitbox.width / 2, hitbox.y + hitbox.height / 2);
        return rl.Vector2.init(position.x - hitbox_center_offset.x, position.y - hitbox_center_offset.y);
    }

    fn handleMapEdgeCollision(self: *Sprite, game: *Game) void {
        const play_screen = game.play_screen;
        if (play_screen) |ps| {
            const map = ps.map;
            const hitbox_rect = self.getHitboxRect(self.position.target);
            if (hitbox_rect.x < map.rect.x) self.position.target.x = map.rect.x + hitbox_rect.width / 2;
            if (hitbox_rect.y < map.rect.y) self.position.target.y = map.rect.y + hitbox_rect.height / 2;
            if (hitbox_rect.x + hitbox_rect.width > map.rect.x + map.rect.width) self.position.target.x = map.rect.x + map.rect.width - hitbox_rect.width / 2;
            if (hitbox_rect.y + hitbox_rect.height > map.rect.y + map.rect.height) self.position.target.y = map.rect.y + map.rect.height - hitbox_rect.height / 2;
        }
    }

    pub fn setAction(self: *Sprite, action: utils.Action) void {
        if (self.action == action) return;
        if (action == .Rest) {
            self.direction = switch (self.direction) {
                .Left, .UpLeft, .DownLeft => .Left,
                .Right, .UpRight, .DownRight => .Right,
                .Up, .Down => if (rl.getRandomValue(0, 1) == 0) .Left else .Right,
            };
        }
        self.action = action;
        self.frame_elapsed = 0.0;
        self.action_elapsed = 0.0;
    }

    fn updatePlayer(self: *Sprite, game: *Game) void {
        var move = rl.Vector2.zero();
        const delta_time = rl.getFrameTime();
        const keyboard = game.input_handler.keyboard;
        if (keyboard.activeKeysInclude(&[_]Key{ .Up, .W }, .Or)) move.y -= 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Down, .S }, .Or)) move.y += 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Left, .A }, .Or)) move.x -= 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Right, .D }, .Or)) move.x += 1;
        self.is_moving = move.x != 0 or move.y != 0;
        self.is_sprinting = self.is_moving and keyboard.activeKeysInclude(&[_]Key{ .LeftShift, .RightShift }, .Or);
        if (self.is_moving) {
            self.current_cycle = 0;
            self.action_elapsed = 0.0;
            self.setAction(if (self.is_sprinting) .Run else .Walk);
            const normalized = move.normalize();
            self.direction = utils.Direction.fromVector(normalized);
            const action_data = self.getActionData(null);
            const move_speed = action_data.speed orelse 0.0;
            self.position.target.x += normalized.x * move_speed * delta_time;
            self.position.target.y += normalized.y * move_speed * delta_time;
            self.handleMapEdgeCollision(game);
            self.position.current = self.position.target;
        } else {
            if (self.action == .Run) self.setAction(.Walk);
            if (self.action == .Walk) self.frame_elapsed = 0.0; // hold the standing frame so the next step starts the cycle over
            self.action_elapsed += delta_time;
            var should_transition: bool = false;
            const action_data = self.getActionData(null);
            if (self.action == .Idle and action_data.cycle_counts != null) {
                should_transition = self.getHasCompletedAnimationCycles(action_data);
            } else if (action_data.timeout) |timeout| should_transition = self.action_elapsed >= timeout;
            if (should_transition) {
                switch (self.action) {
                    .Walk => {
                        const idle_cycle_counts = self.idle_data.cycle_counts orelse .{ 0, 0 };
                        if (idle_cycle_counts[1] > 0 and (self.current_cycle orelse 0) >= idle_cycle_counts[1]) {
                            self.setAction(.Rest);
                            self.current_cycle = 0;
                        } else self.setAction(.Idle);
                    },
                    .Idle => {
                        self.setAction(.Walk);
                        self.current_cycle = (self.current_cycle orelse 0) + 1;
                    },
                    else => {},
                }
            }
        }
    }
};
