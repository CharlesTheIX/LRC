const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../../utils.zig");
const Game = @import("../../../root.zig").Game;
const Menu = @import("../../menu/root.zig").Menu;

const Props = struct { font: rl.Font, font_size: u32 = 32, allocator: *std.mem.Allocator };

pub const StartScreen = struct {
    menu: Menu,
    font: rl.Font,
    font_size: u32,
    allocator: *std.mem.Allocator,
    background_texture: rl.Texture2D,

    // Base methods
    pub fn deinit(self: *StartScreen) void {
        self.menu.deinit();
        rl.unloadTexture(self.background_texture);
    }

    pub fn draw(self: *StartScreen) void {
        self.drawBackground();
        self.menu.draw();
    }

    pub fn init(props: Props) StartScreen {
        return StartScreen{
            .font = props.font,
            .font_size = props.font_size,
            .allocator = props.allocator,
            .background_texture = undefined,
            .menu = Menu.init(.{ .font = props.font, .font_size = props.font_size, .allocator = props.allocator }),
        };
    }

    pub fn load(self: *StartScreen, game: *Game) void {
        self.loadMenu(game);
        self.loadBackground();
        loadCamera(game);
    }

    pub fn update(self: *StartScreen, game: *Game) void {
        self.menu.update(game);
    }

    // Helper methods
    fn drawBackground(self: *StartScreen) void {
        const origin = rl.Vector2{ .x = 0, .y = 0 };
        const window_rect = rl.Rectangle{ .x = 0, .y = 0, .width = @as(f32, @floatFromInt(rl.getScreenWidth())), .height = @as(f32, @floatFromInt(rl.getScreenHeight())) };
        const target_rect = rl.Rectangle{ .x = 0, .y = 0, .width = @as(f32, @floatFromInt(rl.getScreenWidth())) / 2, .height = @as(f32, @floatFromInt(rl.getScreenHeight())) / 2 };
        const src_rect = rl.Rectangle{ .x = 0, .y = 0, .width = @as(f32, @floatFromInt(self.background_texture.width)), .height = @as(f32, @floatFromInt(self.background_texture.height)) };
        const dest_rect = utils.getCenterRectOfRectInRect(window_rect, target_rect);
        rl.drawTexturePro(self.background_texture, src_rect, dest_rect, origin, 0.0, rl.Color.white);
    }

    fn loadBackground(self: *StartScreen) void {
        const background_texture = rl.loadTexture("./assets/textures/start_screen_background.png") catch @panic("Failed to load start screen background texture");
        self.background_texture = background_texture;
    }

    fn loadCamera(game: *Game) void {
        const camera = &game.camera;
        camera.state = .Fixed;
        camera.camera2D.zoom = 1.0;
        camera.camera2D.target = rl.Vector2.zero();
        camera.camera2D.offset = rl.Vector2.zero();
    }

    fn loadMenu(self: *StartScreen, game: *Game) void {
        self.menu.clearItems();
        if (game.save_data.time != 0) self.menu.addItem(.{ .label = "Continue", .on_select = selectContinue });
        if (game.save_data.time == 0) self.menu.addItem(.{ .label = "New Game", .on_select = selectNewGame });
        self.menu.addItem(.{ .label = "Settings", .on_select = selectSettings });
    }

    fn selectContinue(game: *Game) void {
        game.setState(.Playing);
    }

    fn selectNewGame(game: *Game) void {
        game.setState(.NewGame);
    }

    fn selectSettings(game: *Game) void {
        game.setState(.Settings);
    }
};
