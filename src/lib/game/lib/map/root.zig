const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../utils.zig");
const Game = @import("../../root.zig").Game;

const Props = struct { allocator: *std.mem.Allocator };

pub const Map = struct {
    rect: rl.Rectangle,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *Map) void {
        _ = self;
    }

    pub fn draw(self: *Map) void {
        rl.drawRectangleRec(self.rect, rl.Color.green);
    }

    pub fn init(props: Props) Map {
        return Map{ .rect = rl.Rectangle.init(0, 0, 0, 0), .allocator = props.allocator };
    }

    pub fn load(self: *Map, game: *Game) void {
        _ = game;
        self.rect = utils.getWindowRect();
    }

    pub fn update(self: *Map, game: *Game) void {
        _ = self;
        _ = game;
    }
};
