const std = @import("std");
const rl = @import("raylib");
const Timer = @import("../timer.zig").Timer;

const Props = struct { allocator: *std.mem.Allocator };

pub const InfoBanner = struct {
    timer: Timer,
    timer_started: bool = false,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *InfoBanner) void {
        self.timer.deinit();
    }

    pub fn draw(self: *InfoBanner) void {
        rl.drawText("Welcome to the LRC Application!", 20, 20, 20, rl.Color.dark_gray);
        self.timer.draw(.init(10, 130), 20, rl.Color.white, .MinutesSeconds);
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
        return InfoBanner{ .timer = timer, .allocator = props.allocator };
    }

    pub fn update(self: *InfoBanner) void {
        if (!self.timer_started) {
            self.timer.start();
            self.timer_started = true;
        }
        self.timer.update(rl.getFrameTime());
    }
};
