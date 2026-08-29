const std = @import("std");
const rl = @import("raylib");
const utils = @import("../feeding/utils.zig");
const InfoBanner = @import("./info_banner.zig").InfoBanner;
const HomeScreen = @import("./screens/home.zig").HomeScreen;

const Props = struct { allocator: *std.mem.Allocator, feeding_data: ?[]const utils.FeedingData = null };

pub const UI = struct {
    font: rl.Font,
    home_screen: HomeScreen,
    info_banner: InfoBanner,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *UI) void {
        self.home_screen.deinit();
        self.info_banner.deinit();
        rl.unloadFont(self.font);
    }

    pub fn draw(self: *UI) void {
        var draw_position = rl.Vector2.zero();
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        self.info_banner.draw(&draw_position);
        // self.home_screen.draw(&draw_position);
        rl.endDrawing();
    }

    pub fn init(props: Props) UI {
        const config_flags = rl.ConfigFlags{ .window_resizable = true, .window_transparent = true };
        rl.setConfigFlags(config_flags);
        rl.initWindow(800, 600, "LRC");
        rl.setTargetFPS(60);
        rl.initAudioDevice();
        defer rl.closeAudioDevice();
        const font = rl.loadFontEx("./assets/fonts/JetBrains.ttf", 32, null) catch @panic("Failed to load font");
        rl.maximizeWindow();
        return UI{
            .font = font,
            .allocator = props.allocator,
            .home_screen = HomeScreen.init(),
            .info_banner = InfoBanner.init(.{ .allocator = props.allocator, .font = font }),
        };
    }

    fn load(self: *UI) void {
        _ = self.home_screen;
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
