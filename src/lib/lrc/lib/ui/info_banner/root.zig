const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const Audio = @import("../audio/root.zig").Audio;
const Timer = @import("../../timer/root.zig").Timer;
const BabyData = @import("../../baby_data/root.zig").BabyData;
const DateTime = @import("../../date_time/root.zig").DateTime;
const SelectInput = @import("../inputs/select_input.zig").SelectInput;

const Props = struct { font: rl.Font, allocator: *std.mem.Allocator, baby_data: *BabyData, audio: *Audio };

pub const InfoBanner = struct {
    timer: Timer,
    audio: *Audio,
    font: rl.Font,
    select: SelectInput,
    font_size: f32 = 16,
    timer_started: bool = false,
    allocator: *std.mem.Allocator,
    padding: rl.Vector2 = rl.Vector2.init(8, 8),

    pub fn deinit(self: *InfoBanner) void {
        self.timer.deinit();
        self.select.deinit();
    }

    pub fn draw(self: *InfoBanner, draw_position: *rl.Vector2) void {
        utils.drawBackground(self, draw_position);
        draw_position.x += self.padding.x; // Move right for padding
        draw_position.y += self.padding.y; // Move down for padding
        utils.drawAppName(self, draw_position);
        draw_position.y += self.font_size; // Move down for the app name
        draw_position.y += self.padding.y; // Move down for the padding
        utils.drawLastFeedingTime(self, draw_position);
        draw_position.y += self.font_size; // Move down for the app name
        draw_position.y += self.padding.y; // Move down for the padding
        utils.drawNextFeedingTime(self, draw_position);
        draw_position.y += self.font_size; // Move down for the app name
        draw_position.y += self.padding.y; // Move down for the padding
        utils.drawTimer(self, draw_position);
        draw_position.x = 0; // Reset x position for the next line
        draw_position.y += self.font_size; // Move down for the app name
        draw_position.y += self.padding.y; // Move down for the padding
        // self.select.draw();
    }

    pub fn init(props: Props) InfoBanner {
        const timer_target_time = 1000;
        const timer = Timer.init(.{ .timer_type = .Countdown, .allocator = props.allocator, .target_time = timer_target_time, .continue_on_finish = true });
        const select = SelectInput.init(.{
            .font_size = 18,
            .font = props.font,
            .txt_color = rl.Color.black,
            .border_color = rl.Color.gray,
            .bg_color = rl.Color.light_gray,
            .allocator = props.allocator,
            .highlight_color = rl.Color.sky_blue,
            .position = rl.Vector2.init(20, 90),
            .options = &.{ "Pavla", "David", "Other" },
        });
        return InfoBanner{
            .timer = timer,
            .font = props.font,
            .audio = props.audio,
            .select = select,
            .allocator = props.allocator,
        };
    }

    pub fn load(self: *InfoBanner) void {
        self.audio.loadSfx("click", "./assets/audio/sfx/click.mp3") catch @panic("Failed to load click sound effect");
    }

    pub fn update(self: *InfoBanner) void {
        if (!self.timer_started) {
            self.timer.start();
            self.timer_started = true;
        }
        self.select.update();
        self.timer.update(rl.getFrameTime());
        if (self.timer.finished) {}

        if (rl.isMouseButtonDown(.left)) self.audio.playSfx("click");
    }
};
