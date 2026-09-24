const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../utils.zig");
const Game = @import("../../root.zig").Game;
const sprite = @import("../sprite/root.zig");
const Key = @import("../input_handler/root.zig").Key;
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

const Position = struct { current: rl.Vector2 = rl.Vector2.zero(), target: rl.Vector2 = rl.Vector2.zero() };

const Props = struct { allocator: *std.mem.Allocator, sprite_name: []const u8, io: *std.Io };
pub const Player = struct {
    name: []const u8 = "",
    is_moving: bool = false,
    position: Position = .{},
    action_elapsed: f32 = 0.0,
    is_sprinting: bool = false,
    sprite_data: sprite.Sprite,
    allocator: *std.mem.Allocator,
    action: sprite.Action = .Walk,
    direction: sprite.Direction = .Down,

    // base methods
    pub fn deinit(self: *Player) void {
        self.sprite_data.deinit();
    }

    pub fn draw(self: *Player) void {
        self.drawHitbox();
        self.drawLowerRect();
        self.drawUpperRect();
        self.drawCenter();
    }

    pub fn init(props: Props) Player {
        return Player{
            .allocator = props.allocator,
            .sprite_data = sprite.Sprite.init(.{ .allocator = props.allocator, .name = "snorelax", .io = props.io }),
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

    // helper methods
    pub fn actionData(self: *const Player) sprite.ActionData {
        return self.sprite_data.actionData(self.action);
    }

    fn directionOffset(self: *const Player, data: sprite.ActionData) rl.Vector2 {
        const fallback = rl.Vector2.zero();
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

    fn drawCenter(self: *Player) void {
        const hitbox = self.getHitboxRect();
        const center = rl.Vector2.init(hitbox.x + hitbox.width / 2, hitbox.y + hitbox.height / 2);
        rl.drawCircleV(center, 2.0, rl.Color.red);
    }

    fn drawHitbox(self: *Player) void {
        const rects_data = self.rects();
        var rect = rects_data.hitbox orelse return;
        const origin = self.getSpriteOrigin();
        rect.x += origin.x;
        rect.y += origin.y;
        rl.drawRectangleRec(rect, rl.Color.red.alpha(0.5));
    }

    pub fn drawLowerRect(self: *Player) void {
        if (self.sprite_data.texture) |texture| {
            const rects_data = self.rects();
            var rect = rects_data.lower orelse return;
            const frame = self.getActiveFrame();
            const origin = self.getSpriteOrigin();
            const src = rl.Rectangle{ .x = frame.x + rect.x, .y = frame.y + rect.y, .width = rect.width, .height = rect.height };
            rect.x += origin.x;
            rect.y += origin.y;
            rl.drawTexturePro(texture, src, rect, rl.Vector2.zero(), 0.0, rl.Color.white);
        }
    }

    pub fn drawUpperRect(self: *Player) void {
        if (self.sprite_data.texture) |texture| {
            const rects_data = self.rects();
            var rect = rects_data.upper orelse return;
            const frame = self.getActiveFrame();
            const origin = self.getSpriteOrigin();
            const src = rl.Rectangle{ .x = frame.x + rect.x, .y = frame.y + rect.y, .width = rect.width, .height = rect.height };
            rect.x += origin.x;
            rect.y += origin.y;
            rl.drawTexturePro(texture, src, rect, rl.Vector2.zero(), 0.0, rl.Color.white);
        }
    }

    fn getActiveFrame(self: *Player) rl.Rectangle {
        const data = self.actionData();
        const rects_data = self.rects();
        var core = rects_data.core orelse return .{ .x = 0, .y = 0, .width = 0, .height = 0 };

        const frame_count = data.frame_count orelse 1;
        const frame_duration = data.frame_duration orelse 0.12;
        const frame_index: u8 = if (self.is_moving or self.action == .Rest)
            @as(u8, @intFromFloat(@mod(rl.getTime() / frame_duration, @as(f32, @floatFromInt(frame_count)))))
        else
            0;

        const spritesheet_offset = data.spritesheet_offset orelse rl.Vector2.zero();
        const direction_offset = self.directionOffset(data);

        core.x = spritesheet_offset.x + direction_offset.x + core.width * @as(f32, @floatFromInt(frame_index));
        core.y = spritesheet_offset.y + direction_offset.y;
        return core;
    }

    pub fn getHitboxRect(self: *Player) rl.Rectangle {
        return self.getHitboxRectAt(self.position.current);
    }

    fn getHitboxRectAt(self: *Player, position: rl.Vector2) rl.Rectangle {
        const rects_data = self.rects();
        const hitbox = rects_data.hitbox orelse return .{ .x = position.x, .y = position.y, .width = 0, .height = 0 };
        return rl.Rectangle{
            .x = position.x - hitbox.width / 2,
            .y = position.y - hitbox.height / 2,
            .width = hitbox.width,
            .height = hitbox.height,
        };
    }

    fn getSpriteOrigin(self: *Player) rl.Vector2 {
        const rects_data = self.rects();
        const hitbox = rects_data.hitbox orelse return self.position.current;
        const hitbox_center_offset = rl.Vector2.init(hitbox.x + hitbox.width / 2, hitbox.y + hitbox.height / 2);
        return rl.Vector2.init(self.position.current.x - hitbox_center_offset.x, self.position.current.y - hitbox_center_offset.y);
    }

    fn handleMapEdgeCollision(self: *Player, game: *Game) void {
        const play_screen = game.play_screen;
        if (play_screen) |ps| {
            const map = ps.map;
            const hitbox_rect = self.getHitboxRectAt(self.position.target);
            if (hitbox_rect.x < map.rect.x) self.position.target.x = map.rect.x + hitbox_rect.width / 2;
            if (hitbox_rect.y < map.rect.y) self.position.target.y = map.rect.y + hitbox_rect.height / 2;
            if (hitbox_rect.x + hitbox_rect.width > map.rect.x + map.rect.width) self.position.target.x = map.rect.x + map.rect.width - hitbox_rect.width / 2;
            if (hitbox_rect.y + hitbox_rect.height > map.rect.y + map.rect.height) self.position.target.y = map.rect.y + map.rect.height - hitbox_rect.height / 2;
        }
    }

    pub fn rects(self: *const Player) sprite.ActionRects {
        return self.actionData().rects;
    }

    fn setAction(self: *Player, action: sprite.Action) void {
        if (self.action == action) return;
        if (action == .Rest) {
            self.direction = switch (self.direction) {
                .Left, .UpLeft, .DownLeft => .Left,
                .Right, .UpRight, .DownRight => .Right,
                .Up, .Down => if (rl.getRandomValue(0, 1) == 0) .Left else .Right,
            };
        }
        self.action = action;
        self.action_elapsed = 0.0;
    }

    fn updateMovement(self: *Player, game: *Game) void {
        var move = rl.Vector2.zero();
        const keyboard = game.input_handler.keyboard;
        if (keyboard.activeKeysInclude(&[_]Key{ .Up, .W }, .Or)) move.y -= 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Down, .S }, .Or)) move.y += 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Left, .A }, .Or)) move.x -= 1;
        if (keyboard.activeKeysInclude(&[_]Key{ .Right, .D }, .Or)) move.x += 1;
        const delta_time = rl.getFrameTime();
        self.is_moving = move.x != 0 or move.y != 0;
        self.is_sprinting = self.is_moving and keyboard.activeKeysInclude(&[_]Key{ .LeftShift, .RightShift }, .Or);
        if (self.is_moving) {
            self.setAction(if (self.is_sprinting) .Run else .Walk);
            self.action_elapsed = 0.0;
        } else {
            if (self.action == .Run) self.setAction(.Walk);
            self.action_elapsed += delta_time;
            const action_data = self.actionData();
            if (action_data.timeout) |timeout| {
                if (self.action_elapsed >= timeout) {
                    switch (self.action) {
                        .Walk => self.setAction(.Rest),
                        else => {},
                    }
                }
            }
        }
        if (self.is_moving) {
            const normalized = move.normalize();
            self.direction = sprite.Direction.fromVector(normalized);
            const action_data = self.actionData();
            const move_speed = action_data.speed orelse 0.0;
            self.position.target.x += normalized.x * move_speed * delta_time;
            self.position.target.y += normalized.y * move_speed * delta_time;
            self.handleMapEdgeCollision(game);
            self.position.current = self.position.target;
        }
    }
};
