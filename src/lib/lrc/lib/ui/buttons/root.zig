const std = @import("std");
const rl = @import("raylib");
const ui_utils = @import("../utils.zig");
const sliceToZSlice = @import("../../../utils.zig").sliceToZSlice;

const Props = struct {
    font: rl.Font,
    id: []const u8,
    label: []const u8,
    bg_color: rl.Color,
    txt_color: rl.Color,
    font_size: u32 = 16,
    draw_pos: *rl.Vector2,
    border_color: rl.Color,
    allocator: *std.mem.Allocator,
    callback_context: ?*anyopaque = null,
    callback: ?*const fn (callback_context: ?*anyopaque) void = null,
};

pub const Button = struct {
    font: rl.Font,
    id: []const u8,
    font_size: u32,
    label: []const u8,
    bg_color: rl.Color,
    rect: rl.Rectangle,
    txt_color: rl.Color,
    padding: rl.Vector2,
    visible: bool = true,
    focused: bool = false,
    border_color: rl.Color,
    focused_bg_color: rl.Color,
    focused_txt_color: rl.Color,
    callback_context: ?*anyopaque,
    allocator: *std.mem.Allocator,
    cursor: rl.MouseCursor = rl.MouseCursor.default,
    callback: ?*const fn (callback_context: ?*anyopaque) void,

    // Base methods
    pub fn deinit(self: *Button) void {
        _ = self;
    }

    pub fn draw(self: *Button) void {
        if (!self.visible) return;
        self.drawRectangle();
        self.drawText();
    }

    pub fn init(props: Props) Button {
        const font_size_f32 = @as(f32, @floatFromInt(props.font_size));
        const label_z = sliceToZSlice(props.allocator, props.label) catch @panic("Failed to convert label string to Z slice");
        defer props.allocator.free(label_z);
        const label_width = rl.measureTextEx(props.font, label_z, font_size_f32, 2.0).x;
        const padding = rl.Vector2.init(@divFloor(font_size_f32, 2), @divFloor(font_size_f32, 4));
        const rect = rl.Rectangle.init(props.draw_pos.x, props.draw_pos.y, label_width + (2 * padding.x), font_size_f32 + (2 * padding.y));
        return Button{
            .rect = rect,
            .font = props.font,
            .id = props.id,
            .padding = padding,
            .label = props.label,
            .bg_color = props.bg_color,
            .font_size = props.font_size,
            .txt_color = props.txt_color,
            .allocator = props.allocator,
            .border_color = props.border_color,
            .focused_txt_color = props.bg_color,
            .focused_bg_color = props.border_color,
            .callback_context = props.callback_context,
            .callback = props.callback,
        };
    }

    pub fn update(self: *Button) void {
        if (ui_utils.isBlockedByFocusedElement(self.id)) {
            if (self.focused) self.focused = false;
            return;
        }
        self.updateFocus();
    }

    // Helper methods
    fn drawRectangle(self: *Button) void {
        const border_thickness: f32 = if (self.focused) 2 else 1;
        const bg_color = if (self.focused) self.focused_bg_color else self.bg_color;
        rl.drawRectangleRec(self.rect, bg_color);
        rl.drawRectangleLinesEx(self.rect, border_thickness, self.border_color);
    }

    fn drawText(self: *Button) void {
        const text = self.label;
        const txt_color = if (self.focused) self.focused_txt_color else self.txt_color;
        const text_z = sliceToZSlice(self.allocator, text) catch return;
        defer self.allocator.free(text_z);
        rl.drawTextEx(self.font, text_z, .init(self.rect.x + self.padding.x, self.rect.y + self.padding.y), @as(f32, @floatFromInt(self.font_size)), ui_utils.getCharSpacing(self.font_size), txt_color);
    }

    fn onClick(self: *Button) void {
        if (self.callback) |cb| cb(self.callback_context);
    }

    fn updateFocus(self: *Button) void {
        const mouse_pos = rl.getMousePosition();
        if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
            self.focused = true;
            rl.setMouseCursor(.pointing_hand);
            if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
                self.onClick();
                ui_utils.claimFocus(self.id);
            }
        } else {
            self.focused = false;
            if (rl.isMouseButtonPressed(rl.MouseButton.left) and ui_utils.hasFocus(self.id)) ui_utils.clearFocus();
        }
    }
};
