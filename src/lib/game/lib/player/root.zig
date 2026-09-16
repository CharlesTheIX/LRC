const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../utils.zig");
const Game = @import("../../root.zig").Game;
const sprite = @import("../sprite/root.zig");
const Key = @import("../input_handler/root.zig").Key;
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

// const Speed = struct { base: f32, sprint: f32, current: f32 = 0.0 };
const Position = struct { current: rl.Vector2 = rl.Vector2.zero(), target: rl.Vector2 = rl.Vector2.zero() };

const Props = struct { allocator: *std.mem.Allocator, sprite_name: []const u8 };
pub const Player = struct {
    speed: ?f32,
    name: []const u8 = "",
    is_moving: bool = false,
    position: Position = .{},
    is_sprinting: bool = false,
    sprite_data: sprite.Pokemon,
    allocator: *std.mem.Allocator,
    texture: ?rl.Texture2D = null,
    action: sprite.Action = .Walk,
    direction: sprite.Direction = .Down,

    // Base methods
    pub fn deinit(self: *Player) void {
        if (self.texture) |texture| {
            rl.unloadTexture(texture);
            self.texture = null;
        }
    }

    pub fn draw(self: *Player) void {
        self.drawHitbox();
        self.drawLowerRect();
        self.drawUpperRect();
        self.drawCenter();
    }

    pub fn init(props: Props) Player {
        const pokemon = sprite.Pokemon.fromString(props.sprite_name);
        return switch (pokemon) {
            inline else => |config| {
                const texture_path_z = sliceToZSlice(props.allocator, config.texture_path) catch @panic("Failed to convert texture path to Z slice");
                defer props.allocator.free(texture_path_z);
                return Player{
                    .rects = config.walk_data.rects,
                    .speed = config.walk_data.speed,
                    .allocator = props.allocator,
                    .texture = rl.loadTexture(texture_path_z) catch @panic("Failed to load player texture"),
                };
            },
        };
    }

    pub fn load(self: *Player, game: *Game) void {
        self.direction = .Down;
        self.name = game.save_data.name;
        self.position.current = rl.Vector2.init(100, 100);
        self.position.target = self.position.current;
    }

    pub fn update(self: *Player, game: *Game) void {
        self.updateMovement(game);
    }

    // Helper methods
    fn drawCenter(self: *Player) void {
        const hitbox = self.getHitboxRect();
        const center = rl.Vector2.init(hitbox.x + hitbox.width / 2, hitbox.y + hitbox.height / 2);
        rl.drawCircleV(center, 2.0, rl.Color.red);
    }

    fn drawHitbox(self: *Player) void {
        var rect = self.rects.hitbox;
        const origin = self.getSpriteOrigin();
        rect.x += origin.x;
        rect.y += origin.y;
        rl.drawRectangleRec(rect, rl.Color.red.alpha(0.5));
    }

    pub fn drawLowerRect(self: *Player) void {
        if (self.texture) |texture| {
            var rect = self.rects.lower;
            const frame = self.getActiveFrame();
            const origin = self.getSpriteOrigin();
            const src = rl.Rectangle{ .x = frame.x + rect.x, .y = frame.y + rect.y, .width = rect.width, .height = rect.height };
            rect.x += origin.x;
            rect.y += origin.y;
            rl.drawTexturePro(texture, src, rect, rl.Vector2.zero(), 0.0, rl.Color.white);
        }
    }

    pub fn drawUpperRect(self: *Player) void {
        if (self.texture) |texture| {
            var rect = self.rects.upper;
            const frame = self.getActiveFrame();
            const origin = self.getSpriteOrigin();
            const src = rl.Rectangle{ .x = frame.x + rect.x, .y = frame.y + rect.y, .width = rect.width, .height = rect.height };
            rect.x += origin.x;
            rect.y += origin.y;
            rl.drawTexturePro(texture, src, rect, rl.Vector2.zero(), 0.0, rl.Color.white);
        }
    }

    fn getActiveFrame(self: *Player) rl.Rectangle {
        var core = self.rects.core;
        const frame_multiplier = @as(f32, @floatFromInt(self.walk.current_frame));
        const direction_multiplier = @as(f32, @floatFromInt(@intFromEnum(self.direction)));
        core.x = core.width * frame_multiplier;
        core.y = core.height * direction_multiplier;
        return core;
    }

    pub fn getHitboxRect(self: *Player) rl.Rectangle {
        return self.getHitboxRectAt(self.position.current);
    }

    fn getHitboxRectAt(self: *Player, position: rl.Vector2) rl.Rectangle {
        return rl.Rectangle{
            .x = position.x - self.rects.hitbox.width / 2,
            .y = position.y - self.rects.hitbox.height / 2,
            .width = self.rects.hitbox.width,
            .height = self.rects.hitbox.height,
        };
    }

    // self.position is the center of the hitbox; parts are offset from the core sprite's top-left
    fn getSpriteOrigin(self: *Player) rl.Vector2 {
        const hitbox_center_offset = rl.Vector2.init(self.rects.hitbox.x + self.rects.hitbox.width / 2, self.rects.hitbox.y + self.rects.hitbox.height / 2);
        return rl.Vector2.init(self.position.current.x - hitbox_center_offset.x, self.position.current.y - hitbox_center_offset.y);
    }

    fn handleMapEdgeCollision(self: *Player, game: *Game) void {
        const play_screen = game.play_screen;
        if (play_screen) |ps| {
            const map = ps.map;
            // check against the hitbox at the target position, not the stale current position, otherwise the player overshoots the edge for a frame and snaps back, causing jitter
            const hitbox_rect = self.getHitboxRectAt(self.position.target);
            if (hitbox_rect.x < map.rect.x) self.position.target.x = map.rect.x + hitbox_rect.width / 2;
            if (hitbox_rect.y < map.rect.y) self.position.target.y = map.rect.y + hitbox_rect.height / 2;
            if (hitbox_rect.x + hitbox_rect.width > map.rect.x + map.rect.width) self.position.target.x = map.rect.x + map.rect.width - hitbox_rect.width / 2;
            if (hitbox_rect.y + hitbox_rect.height > map.rect.y + map.rect.height) self.position.target.y = map.rect.y + map.rect.height - hitbox_rect.height / 2;
        }
    }

    fn updateMovement(self: *Player, game: *Game) void {
        self.speed.current = self.speed.base;
        var move = rl.Vector2.zero();
        const keyboard = game.input_handler.keyboard;
        if (keyboard.activeKeysInclude(&[_]Key{ .Up, .W }, .Or)) move.y -= 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Down, .S }, .Or)) move.y += 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Left, .A }, .Or)) move.x -= 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Right, .D }, .Or)) move.x += 1;
        const was_moving = self.is_moving;
        const delta_time = rl.getFrameTime();
        self.is_moving = move.x != 0 or move.y != 0;
        self.is_sprinting = self.is_moving and keyboard.activeKeysInclude(&[_]Key{ .LeftShift, .RightShift }, .Or);
        if (self.is_sprinting) self.speed.current = self.speed.sprint;
        self.updateWalkFrame(delta_time, self.is_moving and !was_moving);
        if (self.is_moving) {
            const normalized = move.normalize();
            self.direction = sprite.Direction.fromVector(normalized);
            self.position.target.x += normalized.x * self.speed.current * delta_time;
            self.position.target.y += normalized.y * self.speed.current * delta_time;
            self.handleMapEdgeCollision(game);
            self.position.current = self.position.target;
        }
    }

    fn updateWalkFrame(self: *Player, delta_time: f32, started_moving: bool) void {
        if (!self.is_moving) {
            self.walk.current_frame = 0;
            self.walk.frame_elapsed = 0.0;
            return;
        }
        if (started_moving) {
            self.walk.current_frame = 1;
            self.walk.frame_elapsed = 0.0;
            return;
        }
        const speed_multiplier = if (self.speed.base > 0.0) self.speed.current / self.speed.base else 1.0;
        self.walk.frame_elapsed += delta_time * speed_multiplier;
        while (self.walk.frame_elapsed >= self.walk.frame_duration) {
            self.walk.frame_elapsed -= self.walk.frame_duration;
            self.walk.current_frame = (self.walk.current_frame + 1) % self.walk.frame_count;
        }
    }
};
