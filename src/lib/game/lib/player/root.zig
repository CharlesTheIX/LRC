const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../utils.zig");
const Game = @import("../../root.zig").Game;
const Sprite = @import("../sprite/root.zig").Sprite;
const Action = @import("../sprite/root.zig").Action;
const Key = @import("../input_handler/root.zig").Key;
const Direction = @import("../sprite/root.zig").Direction;
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

const Props = struct { allocator: *std.mem.Allocator, sprite_name: []const u8, io: *std.Io };
pub const Player = struct {
    sprite: Sprite,
    name: []const u8 = "",
    allocator: *std.mem.Allocator,

    // base methods
    pub fn deinit(self: *Player) void {
        self.sprite.deinit();
    }

    pub fn draw(self: *Player) void {
        self.sprite.draw();
    }

    pub fn init(props: Props) Player {
        const sprite = Sprite.init(.{ .allocator = props.allocator, .name = props.sprite_name, .io = props.io });
        return Player{ .sprite = sprite, .allocator = props.allocator };
    }

    pub fn load(self: *Player, game: *Game) void {
        self.sprite.direction = .Down;
        self.name = game.save_data.name;
        self.sprite.position.target = rl.Vector2.init(100, 100);
        self.sprite.position.current = rl.Vector2.init(100, 100);
    }

    pub fn update(self: *Player, game: *Game) void {
        var move = rl.Vector2.zero();
        const keyboard = game.input_handler.keyboard;
        if (keyboard.activeKeysInclude(&[_]Key{ .Up, .W }, .Or)) move.y -= 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Down, .S }, .Or)) move.y += 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Left, .A }, .Or)) move.x -= 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Right, .D }, .Or)) move.x += 1;
        const delta_time = rl.getFrameTime();
        self.sprite.is_moving = move.x != 0 or move.y != 0;
        self.sprite.is_sprinting = self.sprite.is_moving and keyboard.activeKeysInclude(&[_]Key{ .LeftShift, .RightShift }, .Or);
        if (self.sprite.is_moving) {
            self.sprite.setAction(if (self.sprite.is_sprinting) .Run else .Walk);
            self.sprite.action_elapsed = 0.0;
        } else {
            if (self.sprite.action == .Run) self.sprite.setAction(.Walk);
            self.sprite.action_elapsed += delta_time;
            const action_data = self.sprite.getActionData(null);
            if (action_data.timeout) |timeout| {
                if (self.sprite.action_elapsed >= timeout) {
                    switch (self.sprite.action) {
                        .Walk => self.sprite.setAction(.Rest),
                        else => {},
                    }
                }
            }
        }
        if (self.sprite.is_moving) {
            const normalized = move.normalize();
            self.sprite.direction = Direction.fromVector(normalized);
            const action_data = self.sprite.getActionData(null);
            const move_speed = action_data.speed orelse 0.0;
            self.sprite.position.target.x += normalized.x * move_speed * delta_time;
            self.sprite.position.target.y += normalized.y * move_speed * delta_time;
            self.handleMapEdgeCollision(game);
            self.sprite.position.current = self.sprite.position.target;
        }
    }

    // helper methods
    fn handleMapEdgeCollision(self: *Player, game: *Game) void {
        const play_screen = game.play_screen;
        if (play_screen) |ps| {
            const map = ps.map;
            const hitbox_rect = self.sprite.getHitboxRect(self.sprite.position.target);
            if (hitbox_rect.x < map.rect.x) self.sprite.position.target.x = map.rect.x + hitbox_rect.width / 2;
            if (hitbox_rect.y < map.rect.y) self.sprite.position.target.y = map.rect.y + hitbox_rect.height / 2;
            if (hitbox_rect.x + hitbox_rect.width > map.rect.x + map.rect.width) self.sprite.position.target.x = map.rect.x + map.rect.width - hitbox_rect.width / 2;
            if (hitbox_rect.y + hitbox_rect.height > map.rect.y + map.rect.height) self.sprite.position.target.y = map.rect.y + map.rect.height - hitbox_rect.height / 2;
        }
    }
};
