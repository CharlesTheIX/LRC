const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../../utils.zig");
const Game = @import("../../../root.zig").Game;
const Key = @import("../../input_handler/root.zig").Key;

const Props = struct { font: rl.Font, font_size: u32 = 32, allocator: *std.mem.Allocator };

pub const NewGameScreen = struct {
    font: rl.Font,
    font_size: u32,
    allocator: *std.mem.Allocator,
    background_texture: rl.Texture2D,

    // Base methods
    pub fn deinit(self: *NewGameScreen) void {
        rl.unloadTexture(self.background_texture);
    }

    pub fn draw(self: *NewGameScreen) void {
        self.drawBackground();
    }

    pub fn init(props: Props) NewGameScreen {
        return NewGameScreen{
            .font = props.font,
            .font_size = props.font_size,
            .allocator = props.allocator,
            .background_texture = undefined,
        };
    }

    pub fn load(self: *NewGameScreen, game: *Game) void {
        self.loadBackground();
        loadCamera(game);
    }

    pub fn update(self: *NewGameScreen, game: *Game) void {
        _ = self;
        _ = game;
    }

    // Helper methods
    fn drawBackground(self: *NewGameScreen) void {
        const origin = rl.Vector2{ .x = 0, .y = 0 };
        const window_rect = rl.Rectangle{ .x = 0, .y = 0, .width = @as(f32, @floatFromInt(rl.getScreenWidth())), .height = @as(f32, @floatFromInt(rl.getScreenHeight())) };
        const target_rect = rl.Rectangle{ .x = 0, .y = 0, .width = @as(f32, @floatFromInt(rl.getScreenWidth())) / 2, .height = @as(f32, @floatFromInt(rl.getScreenHeight())) / 2 };
        const src_rect = rl.Rectangle{ .x = 0, .y = 0, .width = @as(f32, @floatFromInt(self.background_texture.width)), .height = @as(f32, @floatFromInt(self.background_texture.height)) };
        const dest_rect = utils.getCenterRectOfRectInRect(window_rect, target_rect);
        rl.drawTexturePro(self.background_texture, src_rect, dest_rect, origin, 0.0, rl.Color.white);
    }

    fn loadBackground(self: *NewGameScreen) void {
        const background_texture = rl.loadTexture("./assets/textures/new_game_screen_background.png") catch @panic("Failed to load start screen background texture");
        self.background_texture = background_texture;
    }

    fn loadCamera(game: *Game) void {
        const camera = &game.camera;
        camera.state = .Fixed;
        camera.camera2D.zoom = 1.0;
        camera.camera2D.target = rl.Vector2.zero();
        camera.camera2D.offset = rl.Vector2.zero();
    }
};
