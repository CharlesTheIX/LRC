const std = @import("std");
const rl = @import("raylib");
const utils = @import("../feeding/utils.zig");
const Audio = @import("./audio/root.zig").Audio;
const BabyData = @import("../baby_data/root.zig").BabyData;
const HomeScreen = @import("./screens/home.zig").HomeScreen;
const InfoBanner = @import("./info_banner/root.zig").InfoBanner;
const sliceToZSlice = @import("../utils.zig").sliceToZSlice;

const Props = struct {
    allocator: *std.mem.Allocator,
    baby_data: *BabyData,
    font_file_path: []const u8 = "./assets/fonts/JetBrains.ttf",
};

pub const UI = struct {
    audio: Audio,
    font: rl.Font,
    baby_data: *BabyData,
    home_screen: HomeScreen,
    info_banner: InfoBanner,
    font_file_path: [:0]const u8,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *UI) void {
        self.audio.deinit();
        self.home_screen.deinit();
        self.info_banner.deinit();
        self.allocator.free(self.font_file_path);
        rl.unloadFont(self.font);
        rl.closeAudioDevice();
    }

    pub fn draw(self: *UI) void {
        var draw_position = rl.Vector2.zero();
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        // self.info_banner.draw(&draw_position);
        self.home_screen.draw(&draw_position);
        rl.endDrawing();
    }

    pub fn init(self: *UI, props: Props) void {
        const config_flags = rl.ConfigFlags{ .window_resizable = true, .window_transparent = true };
        rl.setConfigFlags(config_flags);
        rl.initWindow(800, 600, "LRC");
        rl.setTargetFPS(60);
        rl.initAudioDevice();
        rl.maximizeWindow();

        const font_file_path_slice = sliceToZSlice(props.allocator, self.font_file_path) catch @panic("Failed to convert font file path to Z slice");
        const font = rl.loadFontEx(self.font, 16, null) catch @panic("Failed to load font");
        self.* = UI{
            .font = font,
            .home_screen = undefined,
            .info_banner = undefined,
            .baby_data = props.baby_data,
            .allocator = props.allocator,
            .font_file_path = font_file_path_slice,
            .audio = Audio.init(.{ .allocator = props.allocator }),
        };

        const home_screen_layout_rect = rl.Rectangle.init(0, 0, @as(f32, @floatFromInt(rl.getScreenWidth())), @as(f32, @floatFromInt(rl.getScreenHeight())));
        self.home_screen = HomeScreen.init(.{ .font = font, .allocator = props.allocator, .layout_rect = home_screen_layout_rect });
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
