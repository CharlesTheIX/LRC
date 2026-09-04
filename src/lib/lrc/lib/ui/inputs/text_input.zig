const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
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
    placeholder: []const u8 = "",
    allocator: *std.mem.Allocator,
    initial_value: []const u8 = "",
};

pub const TextInput = struct {
    font: rl.Font,
    id: []const u8,
    len: usize = 0,
    font_size: u32,
    cursor: usize = 0,
    rect: rl.Rectangle,
    label: ?[]const u8,
    bg_color: rl.Color,
    txt_color: rl.Color,
    padding: rl.Vector2,
    visible: bool = true,
    blink_timer: f32 = 0,
    focused: bool = false,
    scroll_offset: f32 = 0,
    border_color: rl.Color,
    label_pos: ?rl.Vector2,
    placeholder: []const u8,
    buffer: [128]u8 = undefined,
    cursor_visible: bool = true,
    allocator: *std.mem.Allocator,

    // Base methods
    pub fn deinit(self: *TextInput) void {
        self.buffer = undefined;
    }

    pub fn draw(self: *TextInput) void {
        if (!self.visible) return;
        self.drawLabel();
        self.drawRectangle();
        self.drawText();
        self.drawCursor();
    }

    pub fn init(props: Props) TextInput {
        var label_pos: ?rl.Vector2 = null;
        const font_size_f32 = @as(f32, @floatFromInt(props.font_size));
        const padding = rl.Vector2.init(@divFloor(font_size_f32, 2), @divFloor(font_size_f32, 4));
        const height = font_size_f32 + (2 * padding.y);
        var input_rect = rl.Rectangle.init(props.draw_pos.x, props.draw_pos.y, props.width, height);
        if (props.label) |label| {
            _ = label;
            input_rect.y += font_size_f32 + padding.y;
            label_pos = rl.Vector2.init(props.draw_pos.x, props.draw_pos.y);
        }
        var input = TextInput{
            .font = props.font,
            .id = props.id,
            .padding = padding,
            .rect = input_rect,
            .label_pos = label_pos,
            .label = props.label,
            .font_size = props.font_size,
            .bg_color = props.bg_color,
            .txt_color = props.txt_color,
            .allocator = props.allocator,
            .border_color = props.border_color,
            .placeholder = props.placeholder,
        };
        input.setValue(props.initial_value);
        return input;
    }

    pub fn update(self: *TextInput) void {
        if (!self.visible) return;
        self.updateFocus();
        if (!self.focused) return;
        self.updateCursorBlink();
        self.updateUserInput();
    }

    // Helper methods
    fn drawCursor(self: *TextInput) void {
        if (self.focused and self.cursor_visible) {
            const cursor_x = self.rect.x + self.padding.x + self.getTextWidth(self.buffer[0..self.cursor]) - self.scroll_offset;
            const font_height = @as(f32, @floatFromInt(self.font_size));
            rl.drawLineEx(.init(cursor_x, self.rect.y + self.padding.y), .init(cursor_x, self.rect.y + self.padding.y + font_height), 1.0, self.txt_color);
        }
    }

    fn drawLabel(self: *TextInput) void {
        if (self.label) |label| {
            if (self.label_pos) |label_pos| {
                const label_str = sliceToZSlice(self.allocator, label) catch @panic("Failed to convert label to Z slice");
                defer self.allocator.free(label_str);
                rl.drawTextEx(self.font, label_str, label_pos, @as(f32, @floatFromInt(self.font_size)), utils.getCharSpacing(self.font_size), self.txt_color);
            }
        }
    }

    fn drawRectangle(self: *TextInput) void {
        const border_thickness: f32 = if (self.focused) 2 else 1;
        rl.drawRectangleRec(self.rect, self.bg_color);
        rl.drawRectangleLinesEx(self.rect, border_thickness, self.border_color);
    }

    fn drawText(self: *TextInput) void {
        const visible_width = self.rect.width - (2 * self.padding.x);
        if (self.len > 0) self.updateScroll(visible_width) else self.scroll_offset = 0;
        const text = if (self.len > 0) self.getValue() else self.placeholder;
        const text_z = sliceToZSlice(self.allocator, text) catch return;
        defer self.allocator.free(text_z);
        rl.beginScissorMode(@intFromFloat(self.rect.x), @intFromFloat(self.rect.y), @intFromFloat(self.rect.width), @intFromFloat(self.rect.height));
        rl.drawTextEx(self.font, text_z, .init(self.rect.x + self.padding.x - self.scroll_offset, self.rect.y + self.padding.y), @as(f32, @floatFromInt(self.font_size)), utils.getCharSpacing(self.font_size), self.txt_color);
        rl.endScissorMode();
    }

    fn getTextWidth(self: *TextInput, text: []const u8) f32 {
        if (text.len == 0) return 0;
        const text_z = sliceToZSlice(self.allocator, text) catch return 0;
        defer self.allocator.free(text_z);
        return rl.measureTextEx(self.font, text_z, @as(f32, @floatFromInt(self.font_size)), utils.getCharSpacing(self.font_size)).x;
    }

    pub fn getValue(self: *TextInput) []const u8 {
        return self.buffer[0..self.len];
    }

    fn handleBackspace(self: *TextInput, edited: *bool) void {
        var i = self.cursor;
        while (i < self.len) : (i += 1) self.buffer[i - 1] = self.buffer[i];
        edited.* = true;
        self.len -= 1;
        self.cursor -= 1;
    }

    fn handleDelete(self: *TextInput, edited: *bool) void {
        var i = self.cursor + 1;
        while (i < self.len) : (i += 1) self.buffer[i - 1] = self.buffer[i];
        self.len -= 1;
        edited.* = true;
    }

    fn moveCursorToMouse(self: *TextInput, mouse_pos: rl.Vector2) void {
        var i: usize = 0;
        var best_index: usize = 0;
        var best_diff: f32 = std.math.floatMax(f32);
        const click_x = mouse_pos.x - (self.rect.x + self.padding.x - self.scroll_offset);
        while (i <= self.len) : (i += 1) {
            const width = self.getTextWidth(self.buffer[0..i]);
            const diff = @abs(width - click_x);
            if (diff < best_diff) {
                best_index = i;
                best_diff = diff;
            }
        }
        self.cursor = best_index;
    }

    fn resetBlink(self: *TextInput) void {
        self.blink_timer = 0;
        self.cursor_visible = true;
    }

    fn setCursorEnd(self: *TextInput, edited: *bool) void {
        edited.* = true;
        self.cursor = self.len;
    }

    fn setCursorStart(self: *TextInput, edited: *bool) void {
        edited.* = true;
        self.cursor = 0;
    }

    pub fn setValue(self: *TextInput, new_value: []const u8) void {
        const len = @min(new_value.len, self.buffer.len);
        @memcpy(self.buffer[0..len], new_value[0..len]);
        self.len = len;
        self.cursor = len;
        self.scroll_offset = 0;
    }

    fn shiftCursorLeft(self: *TextInput, edited: *bool) void {
        edited.* = true;
        self.cursor -= 1;
    }

    fn shiftCursorRight(self: *TextInput, edited: *bool) void {
        edited.* = true;
        self.cursor += 1;
    }

    fn updateCursorBlink(self: *TextInput) void {
        self.blink_timer += rl.getFrameTime();
        if (self.blink_timer >= utils.cursor_blink_interval) {
            self.cursor_visible = !self.cursor_visible;
            self.blink_timer -= utils.cursor_blink_interval;
        }
    }

    fn updateFocus(self: *TextInput) void {
        const mouse_pos = rl.getMousePosition();
        if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
            rl.setMouseCursor(.ibeam);
            if (rl.isMouseButtonPressed(.left)) {
                self.resetBlink();
                self.focused = true;
                self.moveCursorToMouse(mouse_pos);
            }
        } else if (rl.isMouseButtonPressed(.left)) self.focused = false;
    }

    fn updateScroll(self: *TextInput, visible_width: f32) void {
        const cursor_x = self.getTextWidth(self.buffer[0..self.cursor]);
        if (cursor_x - self.scroll_offset > visible_width) self.scroll_offset = cursor_x - visible_width;
        if (cursor_x - self.scroll_offset < 0) self.scroll_offset = cursor_x;
        const total_width = self.getTextWidth(self.getValue());
        const max_scroll = @max(0, total_width - visible_width);
        self.scroll_offset = std.math.clamp(self.scroll_offset, 0, max_scroll);
    }

    fn updateUserInput(self: *TextInput) void {
        var edited = false;
        while (true) {
            const char = rl.getCharPressed();
            if (char == 0) break;
            if (char < 32 or char > 126) continue;
            if (self.len >= self.buffer.len) continue;
            const insert_at = self.cursor;
            var i = self.len;
            while (i > insert_at) : (i -= 1) self.buffer[i] = self.buffer[i - 1];
            self.len += 1;
            edited = true;
            self.cursor += 1;
            self.buffer[insert_at] = @intCast(char);
        }
        if (rl.isKeyPressed(.end)) self.setCursorEnd(&edited);
        if (rl.isKeyPressed(.home)) self.setCursorStart(&edited);
        if ((rl.isKeyPressed(.left) or rl.isKeyPressedRepeat(.left)) and self.cursor > 0) self.shiftCursorLeft(&edited);
        if ((rl.isKeyPressed(.delete) or rl.isKeyPressedRepeat(.delete)) and self.cursor < self.len) self.handleDelete(&edited);
        if ((rl.isKeyPressed(.backspace) or rl.isKeyPressedRepeat(.backspace)) and self.cursor > 0) self.handleBackspace(&edited);
        if ((rl.isKeyPressed(.right) or rl.isKeyPressedRepeat(.right)) and self.cursor < self.len) self.shiftCursorRight(&edited);
        if (edited) self.resetBlink();
    }
};
