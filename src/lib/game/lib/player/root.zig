const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../utils.zig");
const Game = @import("../../root.zig").Game;
const Key = @import("../input_handler/root.zig").Key;

const SpriteDirection = enum {
    Down,
    DownRight,
    Right,
    UpRight,
    Up,
    UpLeft,
    Left,
    DownLeft,

    pub fn toColor(self: SpriteDirection) rl.Color {
        switch (self) {
            .Up => return rl.Color.red,
            .Down => return rl.Color.green,
            .Left => return rl.Color.blue,
            .Right => return rl.Color.yellow,
            .UpRight => return rl.Color.orange,
            .UpLeft => return rl.Color.purple,
            .DownRight => return rl.Color.pink,
            .DownLeft => return rl.Color.magenta,
        }
    }

    pub fn fromVector(vector: rl.Vector2) SpriteDirection {
        if (vector.x > 0 and vector.y < 0) return .UpRight;
        if (vector.x < 0 and vector.y < 0) return .UpLeft;
        if (vector.x > 0 and vector.y > 0) return .DownRight;
        if (vector.x < 0 and vector.y > 0) return .DownLeft;
        if (vector.x > 0) return .Right;
        if (vector.x < 0) return .Left;
        if (vector.y < 0) return .Up;
        return .Down;
    }

    pub fn toString(self: SpriteDirection) []const u8 {
        switch (self) {
            .Up => return "Up",
            .Down => return "Down",
            .Left => return "Left",
            .Right => return "Right",
            .UpLeft => return "UpLeft",
            .UpRight => return "UpRight",
            .DownLeft => return "DownLeft",
            .DownRight => return "DownRight",
        }
    }
};

const SpriteRects = struct { upper: rl.Rectangle, lower: rl.Rectangle, hitbox: rl.Rectangle, core: rl.Rectangle };

const Props = struct { allocator: *std.mem.Allocator };

const SpriteAction = enum {
    Idle,
    Walk,
    Run,
};

const SpriteName = enum {
    Sneasel,

    pub fn getSpriteRects(self: SpriteName) SpriteRects {
        switch (self) {
            .Sneasel => return SpriteRects{
                .core = rl.Rectangle{ .x = 0, .y = 0, .width = 32, .height = 32 },
                .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 32, .height = 16 },
                .lower = rl.Rectangle{ .x = 0, .y = 16, .width = 32, .height = 16 },
                .hitbox = rl.Rectangle{ .x = 4, .y = 17, .width = 20, .height = 13 },
            },
        }
    }
};

pub const Player = struct {
    speed: f32 = 0.0,
    position: rl.Vector2,
    is_moving: bool = false,
    base_speed: f32 = 100.0,
    sprint_speed: f32 = 300.0,
    is_sprinting: bool = false,
    target_position: rl.Vector2,
    name: []const u8 = "Player",
    allocator: *std.mem.Allocator,
    texture: ?rl.Texture2D = null,
    direction: SpriteDirection = .Down,
    rects: SpriteRects = .{
        .core = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 33 },
        .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 17 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
        .lower = rl.Rectangle{ .x = 0, .y = 17, .width = 28, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
        .hitbox = rl.Rectangle{ .x = 4, .y = 17, .width = 20, .height = 13 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
    },

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
        return Player{ .position = rl.Vector2.zero(), .target_position = rl.Vector2.zero(), .allocator = props.allocator };
    }

    pub fn load(self: *Player, game: *Game) void {
        self.name = game.save_data.name;
        self.position = rl.Vector2.init(100, 100);
        self.target_position = self.position;
        self.texture = rl.loadTexture("./assets/sprites/snorelax.png") catch @panic("Failed to load player texture");
    }

    pub fn update(self: *Player, game: *Game) void {
        self.updateMovement(game);
    }

    // Helper methods
    fn drawCenter(self: *Player) void {
        const hitbox = self.getHitboxRect();
        const center = rl.Vector2.init(hitbox.x + hitbox.width / 2, hitbox.y + hitbox.height / 2);
        rl.drawCircleV(center, 5.0, rl.Color.red);
    }

    fn drawHitbox(self: *Player) void {
        const origin = self.getSpriteOrigin();
        var rect = self.rects.hitbox;
        rect.x += origin.x;
        rect.y += origin.y;
        rl.drawRectangleRec(rect, SpriteDirection.toColor(self.direction));
    }

    pub fn drawLowerRect(self: *Player) void {
        if (self.texture) |texture| {
            var rect = self.rects.lower;
            const origin = self.getSpriteOrigin();
            const src = rl.Rectangle{ .x = rect.x, .y = rect.y, .width = rect.width, .height = rect.height };
            rect.x += origin.x;
            rect.y += origin.y;
            rl.drawTexturePro(texture, src, rect, rl.Vector2.zero(), 0.0, rl.Color.white);
        }
    }

    pub fn drawUpperRect(self: *Player) void {
        if (self.texture) |texture| {
            var rect = self.rects.upper;
            const origin = self.getSpriteOrigin();
            const src = rl.Rectangle{ .x = rect.x, .y = rect.y, .width = rect.width, .height = rect.height };
            rect.x += origin.x;
            rect.y += origin.y;
            rl.drawTexturePro(texture, src, rect, rl.Vector2.zero(), 0.0, rl.Color.white);
        }
    }

    pub fn getHitboxRect(self: *Player) rl.Rectangle {
        return self.getHitboxRectAt(self.position);
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
        const hitbox_center_offset = rl.Vector2.init(
            self.rects.hitbox.x + self.rects.hitbox.width / 2,
            self.rects.hitbox.y + self.rects.hitbox.height / 2,
        );
        return rl.Vector2.init(
            self.position.x - hitbox_center_offset.x,
            self.position.y - hitbox_center_offset.y,
        );
    }

    fn handleMapEdgeCollision(self: *Player, game: *Game) void {
        const play_screen = game.play_screen;
        if (play_screen) |ps| {
            const map = ps.map;
            // check against the hitbox at the target position, not the stale current position, otherwise the player overshoots the edge for a frame and snaps back, causing jitter
            const hitbox_rect = self.getHitboxRectAt(self.target_position);
            if (hitbox_rect.x < map.rect.x) self.target_position.x = map.rect.x + hitbox_rect.width / 2;
            if (hitbox_rect.y < map.rect.y) self.target_position.y = map.rect.y + hitbox_rect.height / 2;
            if (hitbox_rect.x + hitbox_rect.width > map.rect.x + map.rect.width) self.target_position.x = map.rect.x + map.rect.width - hitbox_rect.width / 2;
            if (hitbox_rect.y + hitbox_rect.height > map.rect.y + map.rect.height) self.target_position.y = map.rect.y + map.rect.height - hitbox_rect.height / 2;
        }
    }

    fn updateMovement(self: *Player, game: *Game) void {
        self.speed = self.base_speed;
        var move = rl.Vector2.zero();
        const keyboard = game.input_handler.keyboard;
        if (keyboard.activeKeysInclude(&[_]Key{ .Up, .W }, .Or)) move.y -= 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Down, .S }, .Or)) move.y += 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Left, .A }, .Or)) move.x -= 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Right, .D }, .Or)) move.x += 1;
        self.is_moving = move.x != 0 or move.y != 0;
        self.is_sprinting = self.is_moving and keyboard.activeKeysInclude(&[_]Key{ .LeftShift, .RightShift }, .Or);
        if (self.is_moving) {
            const delta_time = rl.getFrameTime();
            const normalized = move.normalize();
            if (self.is_sprinting) self.speed = self.sprint_speed;
            self.direction = SpriteDirection.fromVector(normalized);
            self.target_position.x += normalized.x * self.speed * delta_time;
            self.target_position.y += normalized.y * self.speed * delta_time;
            self.handleMapEdgeCollision(game);
            self.position = self.target_position;
        }
    }
};
