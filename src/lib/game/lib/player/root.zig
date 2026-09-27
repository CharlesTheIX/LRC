const std = @import("std");
const rl = @import("raylib");
const Game = @import("../../root.zig").Game;
const Sprite = @import("../sprite/root.zig").Sprite;

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
        const sprite = Sprite.init(.{ .allocator = props.allocator, .name = props.sprite_name, .io = props.io, .sprite_type = .Player });
        return Player{ .sprite = sprite, .allocator = props.allocator };
    }

    pub fn load(self: *Player, game: *Game) void {
        self.name = game.save_data.name;
        self.sprite.position.target = rl.Vector2.init(100, 100);
        self.sprite.position.current = rl.Vector2.init(100, 100);
    }

    pub fn update(self: *Player, game: *Game) void {
        self.sprite.update(game);
    }
};
