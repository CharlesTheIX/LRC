const std = @import("std");
const rl = @import("raylib");
const Timer = @import("../timer.zig").Timer;
const sliceToZSlice = @import("../utils.zig").sliceToZSlice;

const Props = struct {
    allocator: *std.mem.Allocator,
};

pub const UI = struct {
    timer: Timer,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *UI) void {
        self.timer.deinit();
    }

    pub fn init(props: Props) UI {
        const timer = Timer.init(.{ .timer_type = .Continuous, .allocator = props.allocator, .target_time = null });
        return UI{ .allocator = props.allocator, .timer = timer };
    }

    pub fn run(self: *UI) void {
        const config_flags = rl.ConfigFlags{ .vsync_hint = true, .window_resizable = true, .window_transparent = true };
        rl.setTargetFPS(60);
        rl.initAudioDevice();
        defer rl.closeAudioDevice();
        rl.setConfigFlags(config_flags);
        rl.initWindow(800, 600, "LRC");
        rl.maximizeWindow();
        defer rl.closeWindow();
        self.timer.start();
        while (!rl.windowShouldClose()) {
            self.update();
            self.draw();
        }
    }

    pub fn draw(self: *UI) void {
        rl.beginDrawing();
        rl.clearBackground(rl.Color.blank);
        rl.drawText("Hello, LRC!", 10, 10, 20, rl.Color.white);

        // const clock = std.fmt.allocPrint(self.allocator.*, "Time: {d}", .{rl.getTime()}) catch "Failed to allocate clock string";
        // defer self.allocator.free(clock);
        // const clock_z = sliceToZSlice(self.allocator, clock) catch "Failed to convert clock string to Z slice";
        // defer self.allocator.free(clock_z);
        // rl.drawText(clock_z, 10, 70, 20, rl.Color.white);

        // const frame_time = std.fmt.allocPrint(self.allocator.*, "Frame Time: {d}", .{rl.getFrameTime()}) catch "Failed to allocate frame time string";
        // defer self.allocator.free(frame_time);
        // const frame_time_z = sliceToZSlice(self.allocator, frame_time) catch "Failed to convert frame time string to Z slice";
        // defer self.allocator.free(frame_time_z);
        // rl.drawText(frame_time_z, 10, 100, 20, rl.Color.white);
        // self.timer.draw(position: Vector2, font_size: i32, color: Color, format: TimerFormat)
        self.timer.draw(.init(10, 130), 20, rl.Color.white, .MinutesSeconds);
        rl.endDrawing();
    }

    pub fn update(self: *UI) void {
        self.timer.update(rl.getFrameTime());
    }
};
