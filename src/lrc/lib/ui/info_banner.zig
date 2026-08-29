const std = @import("std");
const rl = @import("raylib");
const Timer = @import("../timer.zig").Timer;
const Dropdown = @import("./dropdown.zig").Dropdown;

const Props = struct { font: rl.Font, allocator: *std.mem.Allocator };

pub const InfoBanner = struct {
    timer: Timer,
    font: rl.Font,
    dropdown: Dropdown,
    timer_started: bool = false,
    allocator: *std.mem.Allocator,
    layout_padding: rl.Vector2 = rl.Vector2.init(20, 20),

    pub fn deinit(self: *InfoBanner) void {
        self.timer.deinit();
        self.dropdown.deinit();
    }

    pub fn draw(self: *InfoBanner, draw_position: *rl.Vector2) void {
        draw_position.x += self.layout_padding.x;
        draw_position.y += self.layout_padding.y;
        rl.drawText(
            "Welcome to the LRC Application!",
            @as(i32, @intFromFloat(draw_position.x)),
            @as(i32, @intFromFloat(draw_position.y)),
            20,
            rl.Color.dark_gray,
        );
        draw_position.y += 30; // Move down for the next line
        self.timer.draw(draw_position, 20, rl.Color.white, .MinutesSeconds);
        self.dropdown.draw();
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
            .font = props.font,
            .font_size = 18,
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
