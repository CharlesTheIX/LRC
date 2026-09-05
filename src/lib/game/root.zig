const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const Camera = @import("./lib/camera/root.zig").Camera;
const DevScreen = @import("./lib/screens/dev_screen.zig").DevScreen;
const InputHandler = @import("./lib/input_handler/root.zig").InputHandler;

const Props = struct { io: *std.Io, writer: *std.Io.Writer, allocator: *std.mem.Allocator, env_map: *std.process.Environ.Map, args_it: *std.process.Args.Iterator };

pub const Game = struct {
    io: *std.Io,
    font: rl.Font,
    camera: Camera,
    font_size: u32,
    dev_screen: DevScreen,
    writer: *std.Io.Writer,
    shut_down: bool = false,
    input_handler: InputHandler,
    allocator: *std.mem.Allocator,
    env_map: *std.process.Environ.Map,

    // Base methods
    pub fn deinit(self: *Game) void {
        self.camera.deinit();
        self.dev_screen.deinit();
        self.input_handler.deinit();
        rl.closeWindow();
        rl.closeAudioDevice();
        rl.unloadFont(self.font);
    }

    pub fn draw(self: *Game) void {
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        self.dev_screen.draw(self);
        rl.endDrawing();
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
            .camera = Camera.init(.{}),
            .allocator = props.allocator,
            .input_handler = InputHandler.init(.{ .allocator = props.allocator }),
            .dev_screen = DevScreen.init(.{ .font = font, .font_size = font_size, .allocator = props.allocator }),
        };
        game.loadArgs(props.args_it);
        return game;
    }

    fn load(self: *Game) void {
        const camera_offset = rl.Vector2.init(@as(f32, @floatFromInt(rl.getScreenWidth())), @as(f32, @floatFromInt(rl.getScreenHeight()))).scale(0.5);
        self.camera.load(camera_offset);
        self.dev_screen.load();
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
        self.camera.update(&self.input_handler, null, null);
        self.dev_screen.update(self);
    }

    // Helper methods
    fn loadArgs(self: *Game, args_it: *std.process.Args.Iterator) void {
        _ = self;
        var args = args_it.*;
        while (args.next()) |arg| {
            _ = arg;
            // Process each argument as needed
        }
    }
};
