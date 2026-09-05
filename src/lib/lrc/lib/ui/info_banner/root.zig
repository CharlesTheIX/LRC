const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const ui_utils = @import("../utils.zig");
const Audio = @import("../audio/root.zig").Audio;
const Timer = @import("../../timer/root.zig").Timer;
const BabyData = @import("../../baby_data/root.zig").BabyData;
const DateTime = @import("../../date_time/root.zig").DateTime;
const SelectInput = @import("../inputs/select_input.zig").SelectInput;
const sliceToZSlice = @import("../../../utils.zig").sliceToZSlice;

const Props = struct {
    font: rl.Font,
    audio: *Audio,
    font_size: u32 = 16,
    baby_data: *BabyData,
    color_set: ui_utils.ColorSet,
    allocator: *std.mem.Allocator,
};

pub const InfoBanner = struct {
    audio: *Audio,
    font: rl.Font,
    font_size: u32,
    color_set: ui_utils.ColorSet,
    allocator: *std.mem.Allocator,

    // Base methods
    pub fn deinit(self: *InfoBanner) void {
        _ = self;
    }

    pub fn draw(self: *InfoBanner) void {
        self.drawBackground();
        self.drawAppName();
    }

    pub fn init(props: Props) InfoBanner {
        return InfoBanner{ .font = props.font, .audio = props.audio, .font_size = props.font_size, .color_set = props.color_set, .allocator = props.allocator };
    }

    pub fn load(self: *InfoBanner) void {
        self.audio.loadSfx("click", "./assets/audio/sfx/click.mp3") catch @panic("Failed to load click sound effect");
    }

    pub fn update(self: *InfoBanner) void {
        if (rl.isMouseButtonDown(.left)) self.audio.playSfx("click");
    }

    // Helper methods
    pub fn drawAppName(self: *InfoBanner) void {
        const app_name = "BABY TRACKER!";
        const font_size_f32 = @as(f32, @floatFromInt(self.font_size));
        const draw_pos = rl.Vector2.init(font_size_f32, font_size_f32);
        const app_name_slice = sliceToZSlice(self.allocator, app_name) catch @panic("Failed to convert app_name to zslice");
        defer self.allocator.free(app_name_slice);
        rl.drawTextEx(self.font, app_name_slice, draw_pos, font_size_f32, ui_utils.getCharSpacing(self.font_size), self.color_set.secondary);
    }

    pub fn drawBackground(self: *InfoBanner) void {
        const banner_rect = rl.Rectangle.init(0, 0, @as(f32, @floatFromInt(rl.getScreenWidth())), 3 * @as(f32, @floatFromInt(self.font_size)));
        rl.drawRectangleRec(banner_rect, self.color_set.primary.alpha(0.3));
    }
};
