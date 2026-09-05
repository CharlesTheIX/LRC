const std = @import("std");
const rl = @import("raylib");
const ui_utils = @import("../utils.zig");
const ManualCreateFeedingItemForm = @import("../forms/manual_create_feeding_item_form.zig").ManualCreateFeedingItemForm;

const Props = struct {
    font: rl.Font,
    font_size: u32 = 16,
    color_set: ui_utils.ColorSet,
    allocator: *std.mem.Allocator,
};

pub const TestScreen = struct {
    font: rl.Font,
    font_size: u32,
    color_set: ui_utils.ColorSet,
    allocator: *std.mem.Allocator,
    manual_create_feeding_item_form: ManualCreateFeedingItemForm,

    // Base methods
    pub fn deinit(self: *TestScreen) void {
        self.manual_create_feeding_item_form.deinit();
    }

    pub fn draw(self: *TestScreen) void {
        self.drawBackground();
        self.manual_create_feeding_item_form.draw();
    }

    pub fn init(props: Props) TestScreen {
        const font_size_f32 = @as(f32, @floatFromInt(props.font_size));
        const draw_pos = rl.Vector2.init(font_size_f32, font_size_f32).scale(2.0);
        const manual_create_feeding_item_form = ManualCreateFeedingItemForm.init(.{ .font = props.font, .draw_pos = &draw_pos, .font_size = props.font_size, .color_set = props.color_set, .allocator = props.allocator });
        return TestScreen{
            .font = props.font,
            .font_size = props.font_size,
            .color_set = props.color_set,
            .allocator = props.allocator,
            .manual_create_feeding_item_form = manual_create_feeding_item_form,
        };
    }

    pub fn load(self: *TestScreen) void {
        self.manual_create_feeding_item_form.bindCallbacks();
    }

    pub fn update(self: *TestScreen) void {
        self.manual_create_feeding_item_form.update();
    }

    // Helper methods
    fn drawBackground(self: *TestScreen) void {
        const rect = rl.Rectangle.init(0, 0, @as(f32, @floatFromInt(rl.getScreenWidth())), @as(f32, @floatFromInt(rl.getScreenHeight())));
        rl.drawRectangleRec(rect, self.color_set.primary);
    }
};
