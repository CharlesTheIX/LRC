const std = @import("std");
const rl = @import("raylib");
const Audio = @import("./audio/root.zig").Audio;
const ColorSet = @import("./utils.zig").ColorSet;
const BabyData = @import("../baby_data/root.zig").BabyData;
const TestScreen = @import("./screens/test.zig").TestScreen;
const InfoBanner = @import("./info_banner/root.zig").InfoBanner;
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

const Props = struct {
    color_set: ColorSet,
    baby_data: *BabyData,
    allocator: *std.mem.Allocator,
    font_file_path: []const u8 = "./assets/fonts/JetBrains.ttf",
};

pub const UI = struct {
    audio: Audio,
    font: rl.Font,
    color_set: ColorSet,
    info_banner: InfoBanner,
    test_screen: TestScreen,
    font_file_path: [:0]const u8,
    allocator: *std.mem.Allocator,

    // Base method
    pub fn deinit(self: *UI) void {
        self.audio.deinit();
        self.info_banner.deinit();
        self.test_screen.deinit();
        self.allocator.free(self.font_file_path);
        rl.unloadFont(self.font);
        rl.closeAudioDevice();
    }

    pub fn draw(self: *UI) void {
        rl.beginDrawing();
        rl.clearBackground(rl.Color.blank);
        self.info_banner.draw();
        // self.test_screen.draw();
        rl.endDrawing();
    }

    pub fn init(self: *UI, props: Props) void {
        const config_flags = rl.ConfigFlags{ .window_resizable = true, .window_transparent = true };
        rl.setConfigFlags(config_flags);
        rl.initWindow(800, 600, "LRC");
        rl.setTargetFPS(60);
        rl.initAudioDevice();
        rl.maximizeWindow();
        const font_file_path_slice = sliceToZSlice(props.allocator, props.font_file_path) catch @panic("Failed to convert font file path to Z slice");
        const font = rl.loadFontEx(font_file_path_slice, 32, null) catch @panic("Failed to load font");
        self.* = UI{
            .font = font,
            .color_set = props.color_set,
            .allocator = props.allocator,
            .font_file_path = font_file_path_slice,
            .audio = Audio.init(.{ .allocator = props.allocator }),
            .test_screen = TestScreen.init(.{ .font = font, .allocator = props.allocator, .color_set = props.color_set, .baby_data = props.baby_data }),
            .info_banner = InfoBanner.init(.{ .font = font, .allocator = props.allocator, .color_set = props.color_set, .baby_data = props.baby_data, .audio = &self.audio }),
        };
    }

    fn load(self: *UI) void {
        self.info_banner.load();
        self.test_screen.load();
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
        rl.setMouseCursor(.default);
        self.info_banner.update();
        self.test_screen.update();
    }
};
