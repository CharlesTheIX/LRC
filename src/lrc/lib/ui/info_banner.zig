const std = @import("std");
const rl = @import("raylib");
const Timer = @import("../timer.zig").Timer;
const Dropdown = @import("./dropdown.zig").Dropdown;
const sliceToZSlice = @import("../utils.zig").sliceToZSlice;

const Props = struct { font: rl.Font, allocator: *std.mem.Allocator };

pub const InfoBanner = struct {
    timer: Timer,
    font: rl.Font,
    dropdown: Dropdown,
    timer_started: bool = false,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *InfoBanner) void {
        self.timer.deinit();
        self.dropdown.deinit();
    }

    pub fn draw(self: *InfoBanner, draw_position: *rl.Vector2) void {
        const font_size: f32 = 16;
        const padding = rl.Vector2.init(font_size, font_size).scale(0.5);
        draw_position.x += padding.x;
        draw_position.y += padding.y;
        const app_name = "BABY TRACKER!";
        const app_name_slice = sliceToZSlice(self.allocator, app_name) catch @panic("Failed to convert app_name to zslice");
        defer self.allocator.free(app_name_slice);
        const app_name_width = rl.measureText(app_name_slice, font_size);
        _ = app_name_width; // Currently unused, but can be used for alignment or other purposes
        rl.drawTextEx(self.font, app_name_slice, draw_position.*, font_size, 5.0, rl.Color.white);
        draw_position.y += 30; // Move down for the next line
        // self.timer.draw(draw_position, 20, rl.Color.white, .MinutesSeconds);
        // self.dropdown.draw();
    }

    fn drawBackground(self: *InfoBanner, draw_position: *rl.Vector2, padding: *rl.Vector2, font_size: *f32) void {
        _ = self;
        _ = padding;
        _ = font_size;
        const banner_height = 100; // Adjust as needed
        const banner_rect = rl.Rectangle.init(draw_position.x, draw_position.y, rl.getScreenWidth(), banner_height);
        rl.drawRectangleRec(banner_rect, rl.Color.dark_gray);
    }

    pub fn init(props: Props) InfoBanner {
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
        const timer = Timer.init(.{ .timer_type = .Continuous, .allocator = props.allocator, .target_time = null });
        const dropdown = Dropdown.init(.{
            .font_size = 18,
            .font = props.font,
            .options = &.{ "Pavla", "David", "Other" },
            .position = rl.Vector2.init(20, 90),
            .bg_color = rl.Color.light_gray,
            .txt_color = rl.Color.black,
            .border_color = rl.Color.gray,
            .highlight_color = rl.Color.sky_blue,
            .allocator = props.allocator,
        });
        return InfoBanner{ .timer = timer, .allocator = props.allocator, .font = props.font, .dropdown = dropdown };
    }

    pub fn update(self: *InfoBanner) void {
        if (!self.timer_started) {
            self.timer.start();
            self.timer_started = true;
        }
        self.timer.update(rl.getFrameTime());
        self.dropdown.update();
    }
};
