const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../../utils.zig");
const Game = @import("../../../root.zig").Game;
const Key = @import("../../input_handler/root.zig").Key;

const Props = struct { font: rl.Font, font_size: u32 = 32, allocator: *std.mem.Allocator };

pub const PlayScreen = struct {
    font: rl.Font,
    font_size: u32,
    allocator: *std.mem.Allocator,
    background_texture: rl.Texture2D,

    // Base methods
    pub fn deinit(self: *PlayScreen) void {
        rl.unloadTexture(self.background_texture);
    }

    pub fn draw(self: *PlayScreen) void {
        self.drawBackground();
        self.drawMenu();
    }

    pub fn init(props: Props) PlayScreen {
        return PlayScreen{
            .font = props.font,
            .font_size = props.font_size,
            .allocator = props.allocator,
            .background_texture = undefined,
        };
    }

    pub fn load(self: *PlayScreen, game: *Game) void {
        const background_texture = rl.loadTexture("./assets/textures/play_screen_background.png") catch @panic("Failed to load play screen background texture");
        self.background_texture = background_texture;
        const camera = &game.camera;
        camera.state = .Fixed;
        camera.camera2D.zoom = 1.0;
        camera.camera2D.target = rl.Vector2.zero();
        camera.camera2D.offset = rl.Vector2.zero();
    }

    pub fn update(self: *PlayScreen, game: *Game) void {
        _ = self;
        const kb = game.input_handler.keyboard;
        if (kb.activeKeysInclude(&[_]Key{.S}, .Or)) game.setState(.Start);
        if (kb.activeKeysInclude(&[_]Key{.G}, .Or)) game.setState(.Paused);
        if (kb.activeKeysInclude(&[_]Key{.H}, .Or)) game.setState(.NewGame);
        if (kb.activeKeysInclude(&[_]Key{.H}, .Or)) game.setState(.Settings);
    }

    // Helper methods
    fn drawBackground(self: *PlayScreen) void {
        const origin = rl.Vector2{ .x = 0, .y = 0 };
        const window_rect = rl.Rectangle{ .x = 0, .y = 0, .width = @as(f32, @floatFromInt(rl.getScreenWidth())), .height = @as(f32, @floatFromInt(rl.getScreenHeight())) };
        const target_rect = rl.Rectangle{ .x = 0, .y = 0, .width = @as(f32, @floatFromInt(rl.getScreenWidth())) / 2, .height = @as(f32, @floatFromInt(rl.getScreenHeight())) / 2 };
        const src_rect = rl.Rectangle{ .x = 0, .y = 0, .width = @as(f32, @floatFromInt(self.background_texture.width)), .height = @as(f32, @floatFromInt(self.background_texture.height)) };
        const dest_rect = utils.getCenterRectOfRectInRect(window_rect, target_rect);
        rl.drawTexturePro(self.background_texture, src_rect, dest_rect, origin, 0.0, rl.Color.white);
    }

    fn drawMenu(self: *PlayScreen) void {
        const window_center = utils.getCenterVector2OfRect(utils.getWindowRect());
        var draw_pos = window_center;
        const font_size_f32 = utils.getFontSizeF32(self.font_size);
        // Draw play game option
        draw_pos.y -= font_size_f32;
        const play_game_txt = "Press G to Pause Game";
        const play_game_txt_size = rl.measureTextEx(self.font, play_game_txt, font_size_f32, utils.getCharSpacing(self.font_size));
        draw_pos.x -= play_game_txt_size.x / 2;
        rl.drawTextEx(self.font, play_game_txt, draw_pos, font_size_f32, utils.getCharSpacing(self.font_size), rl.Color.white);
        // Draw pause game option
        draw_pos.y += font_size_f32 * 2;
        const pause_game_txt = "Press H for New Game";
        const pause_game_txt_size = rl.measureTextEx(self.font, pause_game_txt, font_size_f32, utils.getCharSpacing(self.font_size));
        draw_pos.x = window_center.x;
        draw_pos.x -= pause_game_txt_size.x / 2;
        rl.drawTextEx(self.font, pause_game_txt, draw_pos, font_size_f32, utils.getCharSpacing(self.font_size), rl.Color.white);
        // Draw new game option
        draw_pos.y += font_size_f32 * 2;
        const new_game_txt = "Press S for Start Screen";
        const new_game_txt_size = rl.measureTextEx(self.font, new_game_txt, font_size_f32, utils.getCharSpacing(self.font_size));
        draw_pos.x = window_center.x;
        draw_pos.x -= new_game_txt_size.x / 2;
        rl.drawTextEx(self.font, new_game_txt, draw_pos, font_size_f32, utils.getCharSpacing(self.font_size), rl.Color.white);
        // Draw settings option
        draw_pos.y += font_size_f32 * 2;
        const settings_txt = "Press J for Settings";
        const settings_txt_size = rl.measureTextEx(self.font, settings_txt, font_size_f32, utils.getCharSpacing(self.font_size));
        draw_pos.x = window_center.x;
        draw_pos.x -= settings_txt_size.x / 2;
        rl.drawTextEx(self.font, settings_txt, draw_pos, font_size_f32, utils.getCharSpacing(self.font_size), rl.Color.white);
    }
};
