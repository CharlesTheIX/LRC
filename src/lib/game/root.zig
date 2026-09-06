const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const Timer = @import("./lib/timer/root.zig").Timer;
const Camera = @import("./lib/camera/root.zig").Camera;
const Loader = @import("./lib/loader/root.zig").Loader;
const SaveData = @import("./lib/save_data/root.zig").SaveData;
const DevScreen = @import("./lib/screens/dev_screen/root.zig").DevScreen;
const InputHandler = @import("./lib/input_handler/root.zig").InputHandler;
const PlayScreen = @import("./lib/screens/play_screen/root.zig").PlayScreen;
const StartScreen = @import("./lib/screens/start_screen/root.zig").StartScreen;
const PauseScreen = @import("./lib/screens/pause_screen/root.zig").PauseScreen;
const NewGameScreen = @import("./lib/screens/new_game_screen/root.zig").NewGameScreen;
const SettingsScreen = @import("./lib/screens/settings_screen/root.zig").SettingsScreen;

const Props = struct { io: *std.Io, writer: *std.Io.Writer, allocator: *std.mem.Allocator, env_map: *std.process.Environ.Map, args_it: *std.process.Args.Iterator };

pub const Game = struct {
    io: *std.Io,
    font: rl.Font,
    camera: Camera,
    loader: Loader,
    font_size: u32,
    game_timer: Timer,
    save_data: SaveData,
    dev_screen: DevScreen,
    writer: *std.Io.Writer,
    shut_down: bool = false,
    input_handler: InputHandler,
    allocator: *std.mem.Allocator,
    play_screen: ?PlayScreen = null,
    start_screen: ?StartScreen = null,
    pause_screen: ?PauseScreen = null,
    env_map: *std.process.Environ.Map,
    game_state: utils.GameState = .Start,
    new_game_screen: ?NewGameScreen = null,
    settings_screen: ?SettingsScreen = null,

    // Base methods
    pub fn deinit(self: *Game) void {
        self.camera.deinit();
        self.loader.deinit();
        self.save_data.deinit();
        self.dev_screen.deinit();
        self.input_handler.deinit();
        if (self.play_screen) |*play_screen| play_screen.deinit();
        if (self.start_screen) |*start_screen| start_screen.deinit();
        if (self.pause_screen) |*pause_screen| pause_screen.deinit();
        if (self.new_game_screen) |*new_game_screen| new_game_screen.deinit();
        if (self.settings_screen) |*settings_screen| settings_screen.deinit();
        rl.closeWindow();
        rl.closeAudioDevice();
        rl.unloadFont(self.font);
    }

    pub fn draw(self: *Game) void {
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        switch (self.game_state) {
            .Playing => if (self.play_screen) |*play_screen| play_screen.draw(),
            .Paused => if (self.pause_screen) |*pause_screen| pause_screen.draw(),
            .Start => if (self.start_screen) |*start_screen| start_screen.draw(),
            .NewGame => if (self.new_game_screen) |*new_game_screen| new_game_screen.draw(),
            .Settings => if (self.settings_screen) |*settings_screen| settings_screen.draw(),
        }
        self.loader.draw();
        self.dev_screen.draw(self);
        rl.endDrawing();
        // rl.beginMode2D(self.camera.camera2D);
        // const rect = rl.Rectangle{ .x = 0, .y = 0, .width = @as(f32, @floatFromInt(rl.getScreenWidth())), .height = @as(f32, @floatFromInt(rl.getScreenHeight())) };
        // rl.drawRectangleRec(rect, rl.Color.gray);
        // utils.drawGrid(.{ .color = rl.Color.orange, .rect = rect, .gap = 16 });
        // rl.endMode2D();
    }

    pub fn init(props: Props) Game {
        rl.setConfigFlags(.{ .vsync_hint = true, .window_resizable = true });
        rl.initWindow(800, 600, "Game");
        rl.setTargetFPS(60);
        rl.initAudioDevice();
        rl.maximizeWindow();
        const font_size: u32 = 32;
        const font = rl.loadFontEx("./assets/fonts/JetBrains.ttf", @as(i32, @intCast(font_size)), null) catch rl.getFontDefault() catch @panic("Failed to load font");
        var game = Game{
            .font = font,
            .io = props.io,
            .font_size = font_size,
            .env_map = props.env_map,
            .writer = props.writer,
            .allocator = props.allocator,
            .input_handler = InputHandler.init(.{ .allocator = props.allocator }),
            .camera = Camera.init(.{ .offset = utils.getCenterVector2OfRect(utils.getWindowRect()) }),
            .game_timer = Timer.init(.{ .timer_type = .Continuous, .allocator = props.allocator }),
            .loader = Loader.init(.{ .font = font, .font_size = font_size, .allocator = props.allocator }),
            .dev_screen = DevScreen.init(.{ .font = font, .font_size = font_size, .allocator = props.allocator }),
            .save_data = SaveData.init(.{ .allocator = props.allocator, .io = props.io, .env_map = props.env_map }),
            .start_screen = StartScreen.init(.{ .font = font, .font_size = font_size, .allocator = props.allocator }),
        };
        game.loadArgs(props.args_it);
        return game;
    }

    fn load(self: *Game) void {
        self.save_data.load();
        self.dev_screen.load();
        self.game_timer.current_time = self.save_data.time;
        if (self.start_screen) |*start_screen| start_screen.load(self);
    }

    pub fn run(self: *Game) void {
        self.load();
        while (!rl.windowShouldClose() and !self.shut_down) {
            self.update();
            self.draw();
        }
    }

    fn update(self: *Game) void {
        rl.setMouseCursor(.default);
        self.input_handler.update();
        if (self.loader.isBusy()) {
            self.loader.update(self);
            self.dev_screen.update(self);
            return;
        }
        switch (self.game_state) {
            .Start => if (self.start_screen) |*start_screen| start_screen.update(self),
            .Paused => if (self.pause_screen) |*pause_screen| pause_screen.update(self),
            .NewGame => if (self.new_game_screen) |*new_game_screen| new_game_screen.update(self),
            .Settings => if (self.settings_screen) |*settings_screen| settings_screen.update(self),
            .Playing => {
                if (self.play_screen) |*play_screen| play_screen.update(self);
                self.camera.update(&self.input_handler, null, null);
                self.game_timer.update(rl.getFrameTime());
                std.debug.print("Current Time: {d}\n", .{self.game_timer.current_time});
            },
        }
        self.dev_screen.update(self);
    }

    // Helper methods
    pub fn clearScreens(self: *Game) void {
        if (self.play_screen) |*play_screen| play_screen.deinit();
        if (self.start_screen) |*start_screen| start_screen.deinit();
        if (self.pause_screen) |*pause_screen| pause_screen.deinit();
        if (self.new_game_screen) |*new_game_screen| new_game_screen.deinit();
        if (self.settings_screen) |*settings_screen| settings_screen.deinit();
        self.play_screen = null;
        self.pause_screen = null;
        self.start_screen = null;
        self.new_game_screen = null;
        self.settings_screen = null;
    }

    fn loadArgs(self: *Game, args_it: *std.process.Args.Iterator) void {
        _ = self;
        var args = args_it.*;
        while (args.next()) |arg| {
            _ = arg;
            // Process each argument as needed
        }
    }

    pub fn setState(self: *Game, state: utils.GameState) void {
        if (state == self.game_state) return;
        self.loader.requestState(state, null);
    }

    pub fn applyState(self: *Game, state: utils.GameState) void {
        self.clearScreens();
        self.game_state = state;
        switch (state) {
            .Playing => {
                self.play_screen = PlayScreen.init(.{ .font = self.font, .font_size = self.font_size, .allocator = self.allocator });
                if (self.play_screen) |*play_screen| play_screen.load(self);
                self.game_timer.start();
            },
            .Start => {
                self.start_screen = StartScreen.init(.{ .font = self.font, .font_size = self.font_size, .allocator = self.allocator });
                if (self.start_screen) |*start_screen| start_screen.load(self);
                self.game_timer.pause();
            },
            .Paused => {
                self.pause_screen = PauseScreen.init(.{ .font = self.font, .font_size = self.font_size, .allocator = self.allocator });
                if (self.pause_screen) |*pause_screen| pause_screen.load(self);
                self.game_timer.pause();
            },
            .NewGame => {
                self.new_game_screen = NewGameScreen.init(.{ .font = self.font, .font_size = self.font_size, .allocator = self.allocator });
                if (self.new_game_screen) |*new_game_screen| new_game_screen.load(self);
                self.game_timer.pause();
            },
            .Settings => {
                self.settings_screen = SettingsScreen.init(.{ .font = self.font, .font_size = self.font_size, .allocator = self.allocator });
                if (self.settings_screen) |*settings_screen| settings_screen.load(self);
                self.game_timer.pause();
            },
        }
    }
};
