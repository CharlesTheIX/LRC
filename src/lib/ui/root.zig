const std = @import("std");
const rl = @import("raylib");
const Timer = @import("../timer.zig").Timer;
const Button = @import("./button.zig").Button;
const sliceToZSlice = @import("../utils.zig").sliceToZSlice;

const Props = struct {
    allocator: *std.mem.Allocator,
};

pub const UI = struct {
    timer: Timer,
    button: Button,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *UI) void {
        self.timer.deinit();
    }

    pub fn init(props: Props) UI {
        const config_flags = rl.ConfigFlags{ .vsync_hint = true, .window_resizable = true, .window_transparent = true };
        rl.setTargetFPS(60);
        rl.initAudioDevice();
        defer rl.closeAudioDevice();
        rl.setConfigFlags(config_flags);
        rl.initWindow(800, 600, "LRC");
        rl.maximizeWindow();
        const timer = Timer.init(.{ .timer_type = .Continuous, .allocator = props.allocator, .target_time = null });
        const button = Button.init(.{
            .font_size = 20,
            .label = "Click Me",
            .bg_color = rl.Color.blue,
            .txt_color = rl.Color.white,
            .callback = null,
            .allocator = props.allocator,
            .position = rl.Vector2.init(10, 50),
        });
        return UI{ .allocator = props.allocator, .timer = timer, .button = button };
    }

    pub fn run(self: *UI) void {
        self.timer.start();
        while (!rl.windowShouldClose()) {
            self.update();
            self.draw();
        }
        rl.closeWindow();
    }

    pub fn draw(self: *UI) void {
        rl.beginDrawing();
        rl.clearBackground(rl.Color.blank);
        rl.drawText("Hello, LRC!", 10, 10, 20, rl.Color.white);
        self.button.draw();
        self.timer.draw(.init(10, 130), 20, rl.Color.white, .MinutesSeconds);
        rl.endDrawing();
    }

    pub fn update(self: *UI) void {
        self.timer.update(rl.getFrameTime());
        self.button.update();
    }
};
