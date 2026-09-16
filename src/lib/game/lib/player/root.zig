const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../utils.zig");
const Game = @import("../../root.zig").Game;
const sprite = @import("../sprite/root.zig");
const Key = @import("../input_handler/root.zig").Key;
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

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

    fn actionData(self: *const Player) ?sprite.ActionData {
        return switch (self.sprite_data) {
            .Pikachu => |pokemon| switch (self.action) {
                .Walk => pokemon.walk_data,
                .Run => pokemon.run_data,
                .Sleep => pokemon.sleep_data,
                else => pokemon.walk_data,
            },
            .Scyther => |pokemon| switch (self.action) {
                .Walk => pokemon.walk_data,
                .Run => pokemon.run_data,
                .Sleep => null,
                else => pokemon.walk_data,
            },
            .Snorelax => |pokemon| switch (self.action) {
                .Walk => pokemon.walk_data,
                .Run => pokemon.run_data,
                .Sleep => pokemon.sleep_data,
                else => pokemon.walk_data,
            },
        };
    }

    pub fn rects(self: *const Player) ?sprite.Rects {
        const data = self.actionData() orelse return null;
        const core = data.rects.core orelse return null;
        const upper = data.rects.upper orelse return null;
        const lower = data.rects.lower orelse return null;
        const hitbox = data.rects.hitbox orelse return null;
        return .{ .upper = upper, .lower = lower, .hitbox = hitbox, .core = core };
    }

    pub fn baseSpeed(self: *const Player) f32 {
        const data = self.actionData() orelse return 100.0;
        return data.speed orelse 100.0;
    }

    pub fn sprintSpeed(self: *const Player) f32 {
        const base_speed = self.baseSpeed();
        return if (base_speed > 0.0) base_speed * 2.0 else 200.0;
    }

    pub fn currentSpeed(self: *const Player) f32 {
        return self.speed orelse self.baseSpeed();
    }

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
        const walk_speed: f32 = switch (pokemon) {
            .Pikachu => |config| if (config.walk_data) |walk_data| walk_data.speed orelse 100.0 else 100.0,
            .Scyther => |config| config.walk_data.speed orelse 100.0,
            .Snorelax => |config| if (config.walk_data) |walk_data| walk_data.speed orelse 100.0 else 100.0,
        };
        const texture_path = switch (pokemon) {
            .Pikachu => |config| config.texture_path,
            .Scyther => |config| config.texture_path,
            .Snorelax => |config| config.texture_path,
        };
        const texture_path_z = sliceToZSlice(props.allocator, texture_path) catch @panic("Failed to convert texture path to Z slice");
        defer props.allocator.free(texture_path_z);
        const texture = rl.loadTexture(texture_path_z) catch @panic("Failed to load player texture");

        return Player{
            .speed = walk_speed,
            .sprite_data = pokemon,
            .allocator = props.allocator,
            .texture = texture,
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

    fn drawCenter(self: *Player) void {
        const hitbox = self.getHitboxRect();
        const center = rl.Vector2.init(hitbox.x + hitbox.width / 2, hitbox.y + hitbox.height / 2);
        rl.drawCircleV(center, 2.0, rl.Color.red);
    }

    fn drawHitbox(self: *Player) void {
        const rects_data = self.rects() orelse return;
        var rect = rects_data.hitbox;
        const origin = self.getSpriteOrigin();
        rect.x += origin.x;
        rect.y += origin.y;
        rl.drawRectangleRec(rect, rl.Color.red.alpha(0.5));
    }

    pub fn drawLowerRect(self: *Player) void {
        if (self.texture) |texture| {
            const rects_data = self.rects() orelse return;
            var rect = rects_data.lower;
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
            const rects_data = self.rects() orelse return;
            var rect = rects_data.upper;
            const frame = self.getActiveFrame();
            const origin = self.getSpriteOrigin();
            const src = rl.Rectangle{ .x = frame.x + rect.x, .y = frame.y + rect.y, .width = rect.width, .height = rect.height };
            rect.x += origin.x;
            rect.y += origin.y;
            rl.drawTexturePro(texture, src, rect, rl.Vector2.zero(), 0.0, rl.Color.white);
        }
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

    fn getActiveFrame(self: *Player) rl.Rectangle {
        const data = self.actionData() orelse return .{ .x = 0, .y = 0, .width = 0, .height = 0 };
        const rects_data = self.rects() orelse return .{ .x = 0, .y = 0, .width = 0, .height = 0 };
        var core = rects_data.core;

        const frame_count = data.frame_count orelse 1;
        const frame_duration = data.frame_duration orelse 0.12;
        const frame_index: u8 = if (self.is_moving)
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
        const rects_data = self.rects() orelse return .{ .x = position.x, .y = position.y, .width = 0, .height = 0 };
        return rl.Rectangle{
            .x = position.x - rects_data.hitbox.width / 2,
            .y = position.y - rects_data.hitbox.height / 2,
            .width = rects_data.hitbox.width,
            .height = rects_data.hitbox.height,
        };
    }

    fn getSpriteOrigin(self: *Player) rl.Vector2 {
        const rects_data = self.rects() orelse return self.position.current;
        const hitbox_center_offset = rl.Vector2.init(rects_data.hitbox.x + rects_data.hitbox.width / 2, rects_data.hitbox.y + rects_data.hitbox.height / 2);
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

    fn updateMovement(self: *Player, game: *Game) void {
        self.speed = self.baseSpeed();
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
        if (self.is_sprinting) self.speed = self.sprintSpeed();
        self.updateWalkFrame(delta_time, self.is_moving and !was_moving);
        if (self.is_moving) {
            const normalized = move.normalize();
            self.direction = sprite.Direction.fromVector(normalized);
            const move_speed = self.speed orelse self.baseSpeed();
            self.position.target.x += normalized.x * move_speed * delta_time;
            self.position.target.y += normalized.y * move_speed * delta_time;
            self.handleMapEdgeCollision(game);
            self.position.current = self.position.target;
        }
    }

    fn updateWalkFrame(_: *Player, _: f32, _: bool) void {
        // Frame selection is derived from the Pokémon action timing in getActiveFrame(),
        // so no stored walk state is needed on the Player struct.
    }
};
