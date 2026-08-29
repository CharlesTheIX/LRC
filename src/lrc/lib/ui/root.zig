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

    // feeding_cards: []FeedingDataCard,

    pub fn deinit(self: *UI) void {
        self.home_screen.deinit();
        self.info_banner.deinit();
        rl.unloadFont(self.font);
        // for (self.feeding_cards) |*card| card.deinit();
        // self.allocator.free(self.feeding_cards);
    }

    pub fn draw(self: *UI) void {
        var draw_position = rl.Vector2.zero();
        rl.beginDrawing();
        rl.clearBackground(rl.Color.blank);
        self.info_banner.draw(&draw_position);
        self.home_screen.draw(&draw_position);
        rl.endDrawing();

        // self.button.draw();
        // for (self.feeding_cards) |*card| card.draw();
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

        // const button = Button.init(.{
        //     .font = font,
        //     .font_size = 20,
        //     .label = "Click Me",
        //     .bg_color = rl.Color.blue,
        //     .txt_color = rl.Color.white,
        //     .allocator = props.allocator,
        //     .callback = buttonCallback,
        //     .position = rl.Vector2.init(10, 50),
        // });

        // const feeding_data = props.feeding_data orelse &.{};
        // var feeding_cards = props.allocator.alloc(FeedingDataCard, feeding_data.len) catch @panic("Failed to allocate feeding data cards");
        // var card_position = rl.Vector2.init(10, 170);
        // for (feeding_data, 0..) |entry, i| {
        //     feeding_cards[i] = FeedingDataCard.init(.{
        //         .font = font,
        //         .font_size = 16,
        //         .data = entry,
        //         .bg_color = rl.Color.dark_gray,
        //         .txt_color = rl.Color.white,
        //         .position = card_position,
        //         .allocator = props.allocator,
        //     });
        //     card_position.y += feeding_cards[i].rect.height + 10;
        // }

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
