const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../utils.zig");
const Game = @import("../../root.zig").Game;

const Props = struct { allocator: *std.mem.Allocator };

pub const Player = struct {
    position: rl.Vector2,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *Player) void {
        _ = self;
    }

    pub fn draw(self: *Player) void {
        const rect = rl.Rectangle{ .x = self.position.x, .y = self.position.y, .width = 32, .height = 32 };
        rl.drawRectangleRec(rect, rl.Color.blue);
    }

    pub fn init(props: Props) Player {
        return Player{ .position = rl.Vector2.zero(), .allocator = props.allocator };
    }

    pub fn load(self: *Player, game: *Game) void {
        _ = game;
        self.position = rl.Vector2.init(100, 100);
    }

    pub fn update(self: *Player, game: *Game) void {
        _ = self;
        _ = game;
    }
};
