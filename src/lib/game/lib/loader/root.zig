const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../utils.zig");
const Game = @import("../../root.zig").Game;
const Timer = @import("../timer/root.zig").Timer;
const LoaderPhase = @import("./utils.zig").LoaderPhase;

const Props = struct { font: rl.Font, font_size: u32 = 32, allocator: *std.mem.Allocator, fade_time: f64 = 0.3 };

pub const Loader = struct {
    font: rl.Font,
    font_size: u32,
    fade_timer: Timer,
    spinner_timer: Timer,
    phase: LoaderPhase = .Idle,
    allocator: *std.mem.Allocator,
    message: [:0]const u8 = "LOADING",
    pending_state: ?utils.GameState = null,

    // Base methods
    pub fn deinit(self: *Loader) void {
        self.fade_timer.deinit();
        self.spinner_timer.deinit();
    }

    pub fn draw(self: *Loader) void {
        if (self.phase == .Idle) return;
        const alpha = self.currentAlpha();
        const window_rect = utils.getWindowRect();
        rl.drawRectangleRec(window_rect, rl.Color.black.alpha(alpha));
        self.drawSpinner(alpha);
        self.drawMessage(alpha);
    }

    pub fn init(props: Props) Loader {
        return Loader{
            .font = props.font,
            .font_size = props.font_size,
            .allocator = props.allocator,
            .spinner_timer = Timer.init(.{ .timer_type = .Continuous, .allocator = props.allocator }),
            .fade_timer = Timer.init(.{ .timer_type = .Countdown, .target_time = props.fade_time, .allocator = props.allocator }),
        };
    }

    pub fn update(self: *Loader, game: *Game) void {
        if (self.phase == .Idle) return;
        const delta_time = @as(f64, @floatCast(rl.getFrameTime()));
        self.spinner_timer.update(delta_time);
        switch (self.phase) {
            .Idle => {},
            .FadeIn => {
                self.fade_timer.update(delta_time);
                if (self.fade_timer.finished) self.phase = .Working;
            },
            .Working => {
                if (self.pending_state) |state| game.applyState(state);
                self.pending_state = null;
                self.restartFadeTimer();
                self.phase = .FadeOut;
            },
            .FadeOut => {
                self.fade_timer.update(delta_time);
                if (self.fade_timer.finished) {
                    self.phase = .Idle;
                    self.fade_timer.stop();
                    self.spinner_timer.stop();
                }
            },
        }
    }

    // Helper methods
    pub fn isBusy(self: *Loader) bool {
        return self.phase != .Idle;
    }

    pub fn requestState(self: *Loader, state: utils.GameState, message: ?[:0]const u8) void {
        if (self.isBusy()) return;
        self.phase = .FadeIn;
        self.pending_state = state;
        self.message = message orelse "LOADING";
        self.restartFadeTimer();
        self.spinner_timer.restart();
    }

    // Timer.reset() does not clear the finished flag, so clear it on every restart.
    fn restartFadeTimer(self: *Loader) void {
        self.fade_timer.finished = false;
        self.fade_timer.restart();
    }

    fn currentAlpha(self: *Loader) f32 {
        const target = self.fade_timer.target_time orelse 0.0;
        if (target <= 0.0) return 1.0;
        const remaining = @as(f32, @floatCast(self.fade_timer.current_time / target));
        return switch (self.phase) {
            .Idle => 0.0,
            .Working => 1.0,
            .FadeOut => std.math.clamp(remaining, 0.0, 1.0),
            .FadeIn => std.math.clamp(1.0 - remaining, 0.0, 1.0),
        };
    }

    fn drawMessage(self: *Loader, a: f32) void {
        const spacing = utils.getCharSpacing(self.font_size);
        const font_size_f32 = utils.getFontSizeF32(self.font_size);
        const center = utils.getCenterVector2OfRect(utils.getWindowRect());
        const text_size = rl.measureTextEx(self.font, self.message, font_size_f32, spacing);
        const pos = rl.Vector2{ .x = center.x - text_size.x / 2, .y = center.y + font_size_f32 };
        rl.drawTextEx(self.font, self.message, pos, font_size_f32, spacing, rl.Color.white.alpha(a));
    }

    fn drawSpinner(self: *Loader, a: f32) void {
        const radius = utils.getFontSizeF32(self.font_size);
        const center = utils.getCenterVector2OfRect(utils.getWindowRect());
        const start_angle = @as(f32, @floatCast(@mod(self.spinner_timer.current_time * 360.0, 360.0)));
        rl.drawRing(center, radius * 0.6, radius, start_angle, start_angle + 90.0, 32, rl.Color.white.alpha(a));
    }
};
