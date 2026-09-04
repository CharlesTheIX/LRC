const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const ui_utils = @import("../utils.zig");
const sliceToZSlice = @import("../../../utils.zig").sliceToZSlice;

const Props = struct {
    width: f32,
    font: rl.Font,
    id: []const u8,
    bg_color: rl.Color,
    font_size: u32 = 16,
    txt_color: rl.Color,
    draw_pos: *rl.Vector2,
    border_color: rl.Color,
    label: ?[]const u8 = null,
    selected_index: usize = 0,
    options: []const []const u8,
    placeholder: []const u8 = "",
    initial_value: ?usize = null,
    allocator: *std.mem.Allocator,
    callback_context: ?*anyopaque = null,
    highlight_color: rl.Color = rl.Color.dark_gray,
    callback: ?*const fn (callback_context: ?*anyopaque) void = null,
};

pub const SelectInput = struct {
    font: rl.Font,
    id: []const u8,
    font_size: u32,
    item_height: f32,
    rect: rl.Rectangle,
    label: ?[]const u8,
    bg_color: rl.Color,
    open: bool = false,
    txt_color: rl.Color,
    padding: rl.Vector2,
    visible: bool = true,
    focused: bool = false,
    selected_index: usize,
    border_color: rl.Color,
    label_pos: ?rl.Vector2,
    placeholder: []const u8,
    highlight_color: rl.Color,
    options: []const []const u8,
    active_index: ?usize = null,
    hovered_index: ?usize = null,
    allocator: *std.mem.Allocator,
    callback_context: ?*anyopaque,
    callback: ?*const fn (callback_context: ?*anyopaque) void,

    // Base methods
    pub fn deinit(self: *SelectInput) void {
        _ = self;
    }

    pub fn draw(self: *SelectInput) void {
        if (!self.visible) return;
        self.drawLabel();
        self.drawRectangle();
        self.drawText();
        self.drawArrow();
        if (self.open) self.drawOptions();
    }

    pub fn init(props: Props) SelectInput {
        var selected_index: usize = 0;
        var label_pos: ?rl.Vector2 = null;
        const font_size_f32 = @as(f32, @floatFromInt(props.font_size));
        const padding = rl.Vector2.init(@divFloor(font_size_f32, 2), @divFloor(font_size_f32, 4));
        const item_height = font_size_f32 + (2 * padding.y);
        var input_rect = rl.Rectangle.init(props.draw_pos.x, props.draw_pos.y, props.width, item_height);
        if (props.label) |label| {
            _ = label;
            input_rect.y += font_size_f32 + padding.y;
            label_pos = rl.Vector2.init(props.draw_pos.x, props.draw_pos.y);
        }
        if (props.initial_value) |value| {
            if (value < props.options.len) {
                selected_index = value;
            } else if (props.options.len == 0) {
                selected_index = 0;
            } else selected_index = props.options.len - 1;
        } else if (props.options.len == 0) {
            selected_index = 0;
        } else selected_index = @min(props.selected_index, props.options.len - 1);
        return SelectInput{
            .font = props.font,
            .id = props.id,
            .padding = padding,
            .rect = input_rect,
            .item_height = item_height,
            .label_pos = label_pos,
            .label = props.label,
            .font_size = props.font_size,
            .bg_color = props.bg_color,
            .txt_color = props.txt_color,
            .selected_index = selected_index,
            .allocator = props.allocator,
            .border_color = props.border_color,
            .placeholder = props.placeholder,
            .options = props.options,
            .highlight_color = props.highlight_color,
            .callback_context = props.callback_context,
            .callback = props.callback,
        };
    }

    pub fn update(self: *SelectInput) void {
        if (!self.visible) return;
        if (ui_utils.isBlockedByFocusedElement(self.id)) {
            if (self.focused) self.focused = false;
            return;
        }
        self.updateUserClick();
        if (self.options.len == 0) return;
        self.updateUserInput();
    }

    // Helper methods
    fn drawArrow(self: *SelectInput) void {
        const size: f32 = 5;
        const direction: f32 = if (self.open) -1 else 1;
        const center_y = self.rect.y + (self.rect.height / 2);
        const center_x = self.rect.x + self.rect.width - self.padding.x - size;
        rl.drawTriangle(.init(center_x - size, center_y - (direction * size / 2)), .init(center_x + size, center_y - (direction * size / 2)), .init(center_x, center_y + (direction * size / 2)), self.txt_color);
    }

    fn drawBox(self: *SelectInput, rect: rl.Rectangle, label: []const u8, bg_color: rl.Color) void {
        rl.drawRectangleRec(rect, bg_color);
        const border_width: f32 = if (rect.y == self.rect.y and self.focused) 2 else 1;
        rl.drawRectangleLinesEx(rect, border_width, self.border_color);
        const label_z = sliceToZSlice(self.allocator, label) catch return;
        defer self.allocator.free(label_z);
        rl.drawTextEx(self.font, label_z, .init(rect.x + self.padding.x, rect.y + self.padding.y), @as(f32, @floatFromInt(self.font_size)), 1, self.txt_color);
    }

    fn drawLabel(self: *SelectInput) void {
        if (self.label) |label| {
            if (self.label_pos) |label_pos| {
                const label_z = sliceToZSlice(self.allocator, label) catch @panic("Failed to convert label to Z slice");
                defer self.allocator.free(label_z);
                rl.drawTextEx(self.font, label_z, label_pos, @as(f32, @floatFromInt(self.font_size)), 1, self.txt_color);
            }
        }
    }

    fn drawOptions(self: *SelectInput) void {
        for (self.options, 0..) |option, i| {
            const item_rect = self.itemRect(i);
            const color = if (self.hovered_index == i or self.active_index == i) self.highlight_color else self.bg_color;
            self.drawBox(item_rect, option, color);
        }
    }

    fn drawRectangle(self: *SelectInput) void {
        const border_thickness: f32 = if (self.focused) 2 else 1;
        rl.drawRectangleRec(self.rect, self.bg_color);
        rl.drawRectangleLinesEx(self.rect, border_thickness, self.border_color);
    }

    fn drawText(self: *SelectInput) void {
        const text = if (self.selected_index < self.options.len) self.options[self.selected_index] else self.placeholder;
        const display_text = if (text.len > 0) text else self.placeholder;
        const text_z = sliceToZSlice(self.allocator, display_text) catch return;
        defer self.allocator.free(text_z);
        rl.beginScissorMode(@intFromFloat(self.rect.x), @intFromFloat(self.rect.y), @intFromFloat(self.rect.width - self.item_height), @intFromFloat(self.rect.height));
        rl.drawTextEx(self.font, text_z, .init(self.rect.x + self.padding.x, self.rect.y + self.padding.y), @as(f32, @floatFromInt(self.font_size)), 1, self.txt_color);
        rl.endScissorMode();
    }

    fn itemRect(self: *SelectInput, index: usize) rl.Rectangle {
        return rl.Rectangle.init(self.rect.x, self.rect.y + (self.item_height * @as(f32, @floatFromInt(index + 1))), self.rect.width, self.item_height);
    }

    pub fn getValue(self: *SelectInput) []const u8 {
        if (self.selected_index >= self.options.len) return "";
        return self.options[self.selected_index];
    }

    pub fn getValueIndex(self: *SelectInput) usize {
        return self.selected_index;
    }

    fn select(self: *SelectInput, index: usize) void {
        if (self.options.len == 0) return;
        self.selected_index = @min(index, self.options.len - 1);
        self.open = false;
        self.active_index = null;
        self.hovered_index = null;
        if (self.callback) |cb| cb(self.callback_context);
    }

    fn selectedLabel(self: *SelectInput) []const u8 {
        if (self.selected_index >= self.options.len) return "";
        return self.options[self.selected_index];
    }

    pub fn setValue(self: *SelectInput, index: usize) void {
        if (self.options.len == 0) return;
        self.selected_index = @min(index, self.options.len - 1);
    }

    fn updateUserClick(self: *SelectInput) void {
        var clicked_option_index: ?usize = null;
        const mouse_pos = rl.getMousePosition();
        const clicked = rl.isMouseButtonPressed(.left);
        if (self.open) {
            self.hovered_index = null;
            for (self.options, 0..) |_, i| {
                const item_rect = self.itemRect(i);
                if (rl.checkCollisionPointRec(mouse_pos, item_rect)) {
                    self.active_index = i;
                    self.hovered_index = i;
                    clicked_option_index = i;
                    rl.setMouseCursor(.pointing_hand);
                }
            }
        }
        if (clicked_option_index) |index| {
            if (clicked) {
                self.select(index);
                ui_utils.claimFocus(self.id);
                return;
            }
        }
        if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
            rl.setMouseCursor(.pointing_hand);
            if (clicked) {
                ui_utils.claimFocus(self.id);
                self.focused = true;
                self.open = !self.open;
                self.active_index = if (self.open and self.options.len > 0) self.selected_index else null;
            }
        } else if (clicked) {
            if (ui_utils.hasFocus(self.id)) ui_utils.clearFocus();
            self.open = false;
            self.focused = false;
            self.active_index = null;
        }
        if (self.open) {
            if (clicked and self.hovered_index == null and !rl.checkCollisionPointRec(mouse_pos, self.rect)) {
                if (ui_utils.hasFocus(self.id)) ui_utils.clearFocus();
                self.open = false;
                self.focused = false;
                self.active_index = null;
            }
        }
    }

    fn updateUserInput(self: *SelectInput) void {
        if (rl.isKeyPressed(.escape)) {
            self.open = false;
            self.focused = false;
            self.active_index = null;
            return;
        }
        if (rl.isKeyPressed(.enter) or rl.isKeyPressed(.space)) {
            if (self.open) {
                if (self.active_index) |index| self.select(index);
            } else {
                self.open = true;
                self.focused = true;
                self.active_index = self.selected_index;
            }
            return;
        }
        const up_pressed = rl.isKeyPressed(.up) or rl.isKeyPressedRepeat(.up);
        const down_pressed = rl.isKeyPressed(.down) or rl.isKeyPressedRepeat(.down);
        if (up_pressed or down_pressed) {
            const current = self.active_index orelse self.selected_index;
            const last_index = self.options.len - 1;
            var next_index: usize = 0;
            if (up_pressed) {
                if (current == 0) {
                    next_index = 0;
                } else next_index = current - 1;
            } else if (current == last_index) {
                next_index = last_index;
            } else next_index = current + 1;

            if (self.open) {
                self.active_index = next_index;
            } else if (next_index != self.selected_index) self.select(next_index);
        }
    }
};
