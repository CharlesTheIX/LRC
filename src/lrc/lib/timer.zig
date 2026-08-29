const std = @import("std");
const rl = @import("raylib");
const sliceToZSlice = @import("./utils.zig").sliceToZSlice;

const Props = struct { timer_type: TimerType, target_time: ?f64 = null, allocator: *std.mem.Allocator };

pub const Timer = struct {
    paused: bool = false,
    running: bool = false,
    timer_type: TimerType,
    finished: bool = false,
    current_time: f64 = 0.0,
    target_time: ?f64 = null,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *Timer) void {
        _ = self;
    }

    pub fn draw(self: *Timer, draw_position: *rl.Vector2, font_size: i32, color: rl.Color, format: TimerFormat) void {
        const time_str = self.formatTime(format, self.allocator);
        defer self.allocator.free(time_str);
        const zstr = sliceToZSlice(self.allocator, time_str) catch "Failed to convert time string to Z slice";
        defer self.allocator.free(zstr);
        rl.drawText(
            zstr,
            @as(i32, @intFromFloat(draw_position.x)),
            @as(i32, @intFromFloat(draw_position.y)),
            font_size,
            color,
        );
        draw_position.y += @as(f32, @floatFromInt(font_size)) + 5; // Move down for the next line
    }

    pub fn init(props: Props) Timer {
        const timer = Timer{ .timer_type = props.timer_type, .allocator = props.allocator, .target_time = props.target_time };
        if ((props.timer_type == .Countdown or props.timer_type == .CountUp) and props.target_time == null) @panic("target_time must be provided for Countdown and CountUp timers.");
        return timer;
    }

    fn formatTime(self: *Timer, format: TimerFormat, allocator: *std.mem.Allocator) []const u8 {
        const total_seconds = @as(u43, @intFromFloat(self.current_time));
        const seconds = total_seconds % 60;
        const hours = @divFloor(total_seconds, 3600);
        const minutes = @divFloor(@mod(total_seconds, 3600), 60);
        switch (format) {
            .Seconds => return std.fmt.allocPrint(allocator.*, "{d}", .{seconds}) catch "Failed to allocate time string",
            .MinutesSeconds => return std.fmt.allocPrint(allocator.*, "{d}:{d:0>2}", .{ minutes, seconds }) catch "Failed to allocate time string",
            .HoursMinutesSeconds => return std.fmt.allocPrint(allocator.*, "{d}:{d:0>2}:{d:0>2}", .{ hours, minutes, seconds }) catch "Failed to allocate time string",
        }
    }

    pub fn pause(self: *Timer) void {
        if (self.running) self.paused = true;
    }

    pub fn reset(self: *Timer) void {
        self.paused = false;
        self.running = false;
        self.current_time = 0.0;
    }

    pub fn restart(self: *Timer) void {
        self.reset();
        self.start();
    }

    pub fn start(self: *Timer) void {
        self.running = true;
        self.paused = false;
    }

    pub fn stop(self: *Timer) void {
        self.paused = false;
        self.running = false;
    }

    pub fn unpause(self: *Timer) void {
        if (self.paused) self.paused = false;
    }

    pub fn update(self: *Timer, delta_time: f64) void {
        if (self.paused) return;
        if (!self.running) return;
        switch (self.timer_type) {
            .Continuous => self.current_time += delta_time,
            .CountUp => {
                self.current_time += delta_time;
                if (self.target_time) |target| {
                    if (self.current_time >= target) {
                        self.current_time = target; // Clamp to target time
                        self.finished = true;
                        self.stop();
                    }
                }
            },
            .Countdown => {
                self.current_time -= delta_time;
                if (self.current_time <= 0.0) {
                    self.current_time = 0.0; // Clamp to zero
                    self.finished = true;
                    self.stop();
                }
            },
        }
    }
};

const TimerFormat = enum {
    Seconds,
    MinutesSeconds,
    HoursMinutesSeconds,
};

const TimerType = enum {
    CountUp,
    Countdown,
    Continuous,
};
