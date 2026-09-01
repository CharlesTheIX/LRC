const std = @import("std");
const rl = @import("raylib");
const utils = @import("../feeding/utils.zig");
const Audio = @import("./audio/root.zig").Audio;
const Feeding = @import("../feeding/root.zig").Feeding;
const HomeScreen = @import("./screens/home.zig").HomeScreen;
const InfoBanner = @import("./info_banner/root.zig").InfoBanner;

const Props = struct { allocator: *std.mem.Allocator, feeding: *Feeding };

pub const UI = struct {
    audio: Audio,
    font: rl.Font,
    feeding: *Feeding,
    home_screen: HomeScreen,
    info_banner: InfoBanner,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *UI) void {
        self.audio.deinit();
        self.home_screen.deinit();
        self.info_banner.deinit();
        rl.unloadFont(self.font);
        rl.closeAudioDevice();
    }

    pub fn draw(self: *UI) void {
        var draw_position = rl.Vector2.zero();
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        self.info_banner.draw(&draw_position);
        rl.endDrawing();
    }

    pub fn init(self: *UI, props: Props) void {
        const config_flags = rl.ConfigFlags{ .window_resizable = true, .window_transparent = true };
        rl.setConfigFlags(config_flags);
        rl.initWindow(800, 600, "LRC");
        rl.setTargetFPS(60);
        rl.initAudioDevice();
        const font = rl.loadFontEx("./assets/fonts/JetBrains.ttf", 16, null) catch @panic("Failed to load font");
        rl.maximizeWindow();
        self.* = UI{
            .font = font,
            .feeding = props.feeding,
            .info_banner = undefined,
            .allocator = props.allocator,
            .home_screen = HomeScreen.init(),
            .audio = Audio.init(.{ .allocator = props.allocator }),
        };
        self.info_banner = InfoBanner.init(.{ .allocator = props.allocator, .font = font, .feeding = props.feeding, .audio = &self.audio });
    }

    fn load(self: *UI) void {
        self.info_banner.load();
    }

    pub fn run(self: *UI) void {
        self.load();
        while (!rl.windowShouldClose()) {
            self.update();
            self.draw();
        }
        rl.closeWindow();
    }

    pub fn update(self: *UI) void {
        self.info_banner.update();
        self.home_screen.update();
    }
};
