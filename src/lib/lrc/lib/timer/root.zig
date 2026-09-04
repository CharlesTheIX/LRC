const std = @import("std");
const utils = @import("./utils.zig");

const Props = struct {
    timer_type: utils.TimerType,
    target_time: ?f64 = null,
    allocator: *std.mem.Allocator,
    continue_on_finish: bool = false,
};

pub const Timer = struct {
    paused: bool = false,
    running: bool = false,
    finished: bool = false,
    current_time: f64 = 0.0,
    target_time: ?f64 = null,
    timer_type: utils.TimerType,
    allocator: *std.mem.Allocator,
    continue_on_finish: bool = false,

    // Base methods
    pub fn deinit(self: *Timer) void {
        _ = self;
    }

    pub fn init(props: Props) Timer {
        var timer = Timer{ .timer_type = props.timer_type, .allocator = props.allocator, .target_time = props.target_time, .continue_on_finish = props.continue_on_finish };
        if ((props.timer_type == .Countdown or props.timer_type == .CountUp) and props.target_time == null) @panic("target_time must be provided for Countdown and CountUp timers.");
        if (props.timer_type == .Countdown) {
            timer.target_time = 0.0;
            timer.current_time = props.target_time orelse 0.0;
        }
        return timer;
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
                        self.finished = true;
                        if (self.continue_on_finish) return;
                        self.current_time = target;
                        self.stop();
                    }
                }
            },
            .Countdown => {
                self.current_time -= delta_time;
                if (self.current_time <= 0.0) {
                    self.finished = true;
                    if (self.continue_on_finish) return;
                    self.current_time = 0.0;
                    self.stop();
                }
            },
        }
    }

    // Helper methods
    pub fn formatTime(self: *Timer, format: utils.TimerFormat, allocator: *std.mem.Allocator) []const u8 {
        const is_negative = self.current_time < 0.0;
        const sign = if (is_negative) "-" else "";
        const total_seconds = @as(u43, @intFromFloat(@abs(self.current_time)));
        const seconds = total_seconds % 60;
        const hours = @divFloor(total_seconds, 3600);
        const minutes = @divFloor(@mod(total_seconds, 3600), 60);
        switch (format) {
            .Seconds => return std.fmt.allocPrint(allocator.*, "{s}{d}", .{ sign, seconds }) catch "Failed to allocate time string",
            .MinutesSeconds => return std.fmt.allocPrint(allocator.*, "{s}{d}:{d:0>2}", .{ sign, minutes, seconds }) catch "Failed to allocate time string",
            .HoursMinutesSeconds => return std.fmt.allocPrint(allocator.*, "{s}{d}:{d:0>2}:{d:0>2}", .{ sign, hours, minutes, seconds }) catch "Failed to allocate time string",
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
};
