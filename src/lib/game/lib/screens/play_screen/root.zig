const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../../utils.zig");
const Map = @import("../../map/root.zig").Map;
const Game = @import("../../../root.zig").Game;
const Player = @import("../../player/root.zig").Player;
const Key = @import("../../input_handler/root.zig").Key;

const Props = struct { font: rl.Font, font_size: u32 = 32, allocator: *std.mem.Allocator };

pub const PlayScreen = struct {
    map: Map,
    font: rl.Font,
    font_size: u32,
    player: Player,
    allocator: *std.mem.Allocator,

    // Base methods
    pub fn deinit(self: *PlayScreen) void {
        self.map.deinit();
        self.player.deinit();
    }

    pub fn draw(self: *PlayScreen, game: *Game) void {
        rl.beginMode2D(game.camera.camera2D);
        self.map.draw();
        self.player.draw();
        rl.endMode2D();
    }

    pub fn init(props: Props) PlayScreen {
        return PlayScreen{
            .font = props.font,
            .font_size = props.font_size,
            .allocator = props.allocator,
            .map = Map.init(.{ .allocator = props.allocator }),
            .player = Player.init(.{ .allocator = props.allocator }),
        };
    }

    pub fn load(self: *PlayScreen, game: *Game) void {
        self.map.load(game);
        self.player.load(game);
        self.loadCamera(game);
    }

    pub fn update(self: *PlayScreen, game: *Game) void {
        self.map.update(game);
        self.player.update(game);
        game.camera.update(&game.input_handler, self.player.position, &self.map.rect);
    }

    // Helper methods
    fn loadCamera(self: *PlayScreen, game: *Game) void {
        game.camera.setZoom(10.0);
        game.camera.state = .Follow;
        game.camera.snap_to_map = true;
        game.camera.setTarget(self.player.position);
        game.camera.camera2D.offset = utils.getCenterVector2OfRect(utils.getWindowRect());
        game.camera.snapToMap(&self.map.rect);
    }
};
