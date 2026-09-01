const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

const Props = struct { width: f32, font: rl.Font, font_size: i32, bg_color: rl.Color, txt_color: rl.Color, border_color: rl.Color, layout_rect: rl.Rectangle, placeholder: []const u8 = "", allocator: *std.mem.Allocator, initial_value: []const u8 = "" };

pub const TextInput = struct {
    font: rl.Font,
    len: usize = 0,
    font_size: i32,
    cursor: usize = 0,
    rect: rl.Rectangle,
    bg_color: rl.Color,
    txt_color: rl.Color,
    visible: bool = true,
    blink_timer: f32 = 0,
    focused: bool = false,
    scroll_offset: f32 = 0,
    border_color: rl.Color,
    placeholder: []const u8,
    buffer: [128]u8 = undefined,
    cursor_visible: bool = true,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *TextInput) void {
        self.buffer = undefined;
    }

    pub fn draw(self: *TextInput) void {
        if (!self.visible) return;
        rl.drawRectangleRec(self.rect, self.bg_color);
        rl.drawRectangleLinesEx(self.rect, if (self.focused) 2 else 1, self.border_color);
        const padding = rl.Vector2.init(8, 6);
        const visible_width = self.rect.width - (2 * padding.x);
        if (self.len > 0) self.updateScroll(visible_width) else self.scroll_offset = 0;
        const text = if (self.len > 0) self.getValue() else self.placeholder;
        const text_z = sliceToZSlice(self.allocator, text) catch "Failed to convert text to Z slice";
        defer self.allocator.free(text_z);
        rl.beginScissorMode(@intFromFloat(self.rect.x), @intFromFloat(self.rect.y), @intFromFloat(self.rect.width), @intFromFloat(self.rect.height));
        rl.drawTextEx(self.font, text_z, .init(self.rect.x + padding.x - self.scroll_offset, self.rect.y + padding.y), @as(f32, @floatFromInt(self.font_size)), utils.char_spacing, self.txt_color);
        rl.endScissorMode();
        if (self.focused and self.cursor_visible) {
            const cursor_x = self.rect.x + padding.x + self.getTextWidth(self.buffer[0..self.cursor]) - self.scroll_offset;
            const font_height = @as(f32, @floatFromInt(self.font_size));
            rl.drawLineEx(.init(cursor_x, self.rect.y + padding.y), .init(cursor_x, self.rect.y + padding.y + font_height), 1.0, self.txt_color);
        }
    }

    fn getTextWidth(self: *TextInput, text: []const u8) f32 {
        if (text.len == 0) return 0;
        const text_z = sliceToZSlice(self.allocator, text) catch return 0;
        defer self.allocator.free(text_z);
        return rl.measureTextEx(self.font, text_z, @as(f32, @floatFromInt(self.font_size)), utils.char_spacing).x;
    }

    pub fn getValue(self: *TextInput) []const u8 {
        return self.buffer[0..self.len];
    }

    pub fn init(props: Props) TextInput {
        const height = @as(f32, @floatFromInt(props.font_size)) + (2 * 6);
        const input_rect = rl.Rectangle.init(props.layout_rect.x, props.layout_rect.y, props.width, height);
        var input = TextInput{
            .font = props.font,
            .rect = input_rect,
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

    fn moveCursorToMouse(self: *TextInput, mouse_pos: rl.Vector2) void {
        var i: usize = 0;
        const padding_x: f32 = 8;
        var best_index: usize = 0;
        var best_diff: f32 = std.math.floatMax(f32);
        const click_x = mouse_pos.x - (self.rect.x + padding_x - self.scroll_offset);
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

    pub fn setValue(self: *TextInput, new_value: []const u8) void {
        const len = @min(new_value.len, self.buffer.len);
        @memcpy(self.buffer[0..len], new_value[0..len]);
        self.len = len;
        self.cursor = len;
        self.scroll_offset = 0;
    }

    pub fn update(self: *TextInput) void {
        if (!self.visible) return;
        const mouse_pos = rl.getMousePosition();
        if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
            rl.setMouseCursor(.ibeam);
            if (rl.isMouseButtonPressed(.left)) {
                self.focused = true;
                self.moveCursorToMouse(mouse_pos);
                self.resetBlink();
            }
        } else {
            rl.setMouseCursor(.default);
            if (rl.isMouseButtonPressed(.left)) self.focused = false;
        }
        if (!self.focused) return;
        self.blink_timer += rl.getFrameTime();
        if (self.blink_timer >= utils.cursor_blink_interval) {
            self.cursor_visible = !self.cursor_visible;
            self.blink_timer -= utils.cursor_blink_interval;
        }
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
        if ((rl.isKeyPressed(.backspace) or rl.isKeyPressedRepeat(.backspace)) and self.cursor > 0) {
            var i = self.cursor;
            while (i < self.len) : (i += 1) self.buffer[i - 1] = self.buffer[i];
            edited = true;
            self.len -= 1;
            self.cursor -= 1;
        }
        if ((rl.isKeyPressed(.delete) or rl.isKeyPressedRepeat(.delete)) and self.cursor < self.len) {
            var i = self.cursor + 1;
            while (i < self.len) : (i += 1) self.buffer[i - 1] = self.buffer[i];
            self.len -= 1;
            edited = true;
        }
        if ((rl.isKeyPressed(.left) or rl.isKeyPressedRepeat(.left)) and self.cursor > 0) {
            edited = true;
            self.cursor -= 1;
        }
        if ((rl.isKeyPressed(.right) or rl.isKeyPressedRepeat(.right)) and self.cursor < self.len) {
            edited = true;
            self.cursor += 1;
        }
        if (rl.isKeyPressed(.home)) {
            edited = true;
            self.cursor = 0;
        }
        if (rl.isKeyPressed(.end)) {
            edited = true;
            self.cursor = self.len;
        }
        if (edited) self.resetBlink();
    }

    fn updateScroll(self: *TextInput, visible_width: f32) void {
        const cursor_x = self.getTextWidth(self.buffer[0..self.cursor]);
        if (cursor_x - self.scroll_offset > visible_width) self.scroll_offset = cursor_x - visible_width;
        if (cursor_x - self.scroll_offset < 0) self.scroll_offset = cursor_x;
        const total_width = self.getTextWidth(self.getValue());
        const max_scroll = @max(0, total_width - visible_width);
        self.scroll_offset = std.math.clamp(self.scroll_offset, 0, max_scroll);
    }
};
