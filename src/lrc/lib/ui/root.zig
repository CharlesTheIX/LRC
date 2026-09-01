const std = @import("std");
const rl = @import("raylib");
const utils = @import("../feeding/utils.zig");
const Audio = @import("./audio/root.zig").Audio;
const Feeding = @import("../feeding/root.zig").Feeding;
const HomeScreen = @import("./screens/home.zig").HomeScreen;
const InfoBanner = @import("./info_banner/root.zig").InfoBanner;
const TimerFeedingForm = @import("./feeding_form/root.zig").TimerFeedingForm;
const HistoricFeedingForm = @import("./feeding_form/root.zig").HistoricFeedingForm;
const sliceToZSlice = @import("../utils.zig").sliceToZSlice;

const Props = struct { allocator: *std.mem.Allocator, feeding: *Feeding };

pub const UI = struct {
    audio: Audio,
    font: rl.Font,
    feeding: *Feeding,
    home_screen: HomeScreen,
    info_banner: InfoBanner,
    allocator: *std.mem.Allocator,
    timer_feeding_form: TimerFeedingForm,
    historic_feeding_form: HistoricFeedingForm,
    font_file_path: []const u8 = "./assets/fonts/JetBrains.ttf",

    pub fn deinit(self: *UI) void {
        self.audio.deinit();
        self.home_screen.deinit();
        self.info_banner.deinit();
        self.timer_feeding_form.deinit();
        self.historic_feeding_form.deinit();
        rl.unloadFont(self.font);
        rl.closeAudioDevice();
    }

    pub fn draw(self: *UI) void {
        var draw_position = rl.Vector2.zero();
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        // self.info_banner.draw(&draw_position);
        self.home_screen.draw(&draw_position);
        // self.timer_feeding_form.draw();
        // self.historic_feeding_form.draw();
        rl.endDrawing();
    }

    pub fn init(self: *UI, props: Props) void {
        const config_flags = rl.ConfigFlags{ .window_resizable = true, .window_transparent = true };
        rl.setConfigFlags(config_flags);
        rl.initWindow(800, 600, "LRC");
        rl.setTargetFPS(60);
        rl.initAudioDevice();
        rl.maximizeWindow();
        self.* = UI{
            .font = undefined,
            .feeding = props.feeding,
            .home_screen = undefined,
            .info_banner = undefined,
            .allocator = props.allocator,
            .timer_feeding_form = undefined,
            .historic_feeding_form = undefined,
            .audio = Audio.init(.{ .allocator = props.allocator }),
        };
        const font_file_path_slice = sliceToZSlice(props.allocator, self.font_file_path) catch @panic("Failed to convert font file path to Z slice");
        defer props.allocator.free(font_file_path_slice);
        const font = rl.loadFontEx(font_file_path_slice, 16, null) catch @panic("Failed to load font");
        const home_screen_layout_rect = rl.Rectangle.init(0, 0, @as(f32, @floatFromInt(rl.getScreenWidth())), @as(f32, @floatFromInt(rl.getScreenHeight())));
        self.font = font;
        self.home_screen = HomeScreen.init(.{ .font = font, .allocator = props.allocator, .layout_rect = home_screen_layout_rect });

        self.info_banner = InfoBanner.init(.{ .allocator = props.allocator, .font = font, .feeding = props.feeding, .audio = &self.audio });
        self.timer_feeding_form = TimerFeedingForm.init(.{ .font = font, .position = rl.Vector2.init(20, 220), .feeding = props.feeding, .allocator = props.allocator, .layout_rect = home_screen_layout_rect });
        self.historic_feeding_form = HistoricFeedingForm.init(.{ .font = font, .position = rl.Vector2.init(320, 220), .feeding = props.feeding, .allocator = props.allocator, .layout_rect = home_screen_layout_rect });
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
        self.timer_feeding_form.update();
        self.historic_feeding_form.update();
    }
};
