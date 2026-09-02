const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const sliceToZSlice = @import("../../../utils.zig").sliceToZSlice;

const Props = struct {
    width: f32,
    height: f32,
    font: rl.Font,
    font_size: i32,
    bg_color: rl.Color,
    txt_color: rl.Color,
    border_color: rl.Color,
    layout_rect: rl.Rectangle,
    placeholder: []const u8 = "",
    allocator: *std.mem.Allocator,
    initial_value: []const u8 = "",
};

pub const TextAreaInput = struct {
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
    buffer: [1024]u8 = undefined,
    cursor_visible: bool = true,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *TextAreaInput) void {
        self.buffer = undefined;
    }

    pub fn draw(self: *TextAreaInput) void {
        if (!self.visible) return;
        rl.drawRectangleRec(self.rect, self.bg_color);
        rl.drawRectangleLinesEx(self.rect, if (self.focused) 2 else 1, self.border_color);

        const padding = rl.Vector2.init(8, 6);
        self.updateScroll();
        const text = if (self.len > 0) self.getValue() else self.placeholder;
        const text_z = sliceToZSlice(self.allocator, text) catch return;
        defer self.allocator.free(text_z);
        rl.beginScissorMode(@intFromFloat(self.rect.x), @intFromFloat(self.rect.y), @intFromFloat(self.rect.width), @intFromFloat(self.rect.height));
        rl.drawTextEx(self.font, text_z, .init(self.rect.x + padding.x, self.rect.y + padding.y - self.scroll_offset), @as(f32, @floatFromInt(self.font_size)), utils.char_spacing, self.txt_color);
        rl.endScissorMode();

        if (self.focused and self.cursor_visible) {
            const position = self.cursorPosition();
            const cursor_x = self.rect.x + padding.x + position.x;
            const cursor_y = self.rect.y + padding.y + position.y - self.scroll_offset;
            const font_height = @as(f32, @floatFromInt(self.font_size));
            rl.drawLineEx(.init(cursor_x, cursor_y), .init(cursor_x, cursor_y + font_height), 1.0, self.txt_color);
        }
    }

    pub fn init(props: Props) TextAreaInput {
        var input = TextAreaInput{
            .font = props.font,
            .rect = rl.Rectangle.init(props.layout_rect.x, props.layout_rect.y, props.width, props.height),
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

    pub fn getValue(self: *TextAreaInput) []const u8 {
        return self.buffer[0..self.len];
    }

    pub fn setValue(self: *TextAreaInput, new_value: []const u8) void {
        const len = @min(new_value.len, self.buffer.len);
        @memcpy(self.buffer[0..len], new_value[0..len]);
        self.len = len;
        self.cursor = len;
        self.scroll_offset = 0;
    }

    pub fn update(self: *TextAreaInput) void {
        if (!self.visible) return;
        const mouse_pos = rl.getMousePosition();
        if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
            rl.setMouseCursor(.ibeam);
            if (rl.isMouseButtonPressed(.left)) {
                self.focused = true;
                self.moveCursorToMouse(mouse_pos);
                self.resetBlink();
            }
            const wheel_move = rl.getMouseWheelMove();
            if (wheel_move != 0) {
                self.scroll_offset -= wheel_move * self.lineHeight() * 3;
                self.clampScroll();
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
            if (char < 32 or char > 126 or self.len >= self.buffer.len) continue;
            self.insert(@intCast(char));
            edited = true;
        }
        if (rl.isKeyPressed(.enter) and self.len < self.buffer.len) {
            self.insert('\n');
            edited = true;
        }
        if ((rl.isKeyPressed(.backspace) or rl.isKeyPressedRepeat(.backspace)) and self.cursor > 0) {
            self.deleteAt(self.cursor - 1);
            self.cursor -= 1;
            edited = true;
        }
        if ((rl.isKeyPressed(.delete) or rl.isKeyPressedRepeat(.delete)) and self.cursor < self.len) {
            self.deleteAt(self.cursor);
            edited = true;
        }
        if ((rl.isKeyPressed(.left) or rl.isKeyPressedRepeat(.left)) and self.cursor > 0) {
            self.cursor -= 1;
            edited = true;
        }
        if ((rl.isKeyPressed(.right) or rl.isKeyPressedRepeat(.right)) and self.cursor < self.len) {
            self.cursor += 1;
            edited = true;
        }
        if (rl.isKeyPressed(.home)) {
            self.cursor = self.lineStart(self.cursor);
            edited = true;
        }
        if (rl.isKeyPressed(.end)) {
            self.cursor = self.lineEnd(self.cursor);
            edited = true;
        }
        if (rl.isKeyPressed(.up) or rl.isKeyPressedRepeat(.up)) {
            self.moveCursorVertically(-1);
            edited = true;
        }
        if (rl.isKeyPressed(.down) or rl.isKeyPressedRepeat(.down)) {
            self.moveCursorVertically(1);
            edited = true;
        }
        if (edited) self.resetBlink();
    }

    fn insert(self: *TextAreaInput, char: u8) void {
        var index = self.len;
        while (index > self.cursor) : (index -= 1) self.buffer[index] = self.buffer[index - 1];
        self.buffer[self.cursor] = char;
        self.cursor += 1;
        self.len += 1;
    }

    fn deleteAt(self: *TextAreaInput, index: usize) void {
        var current = index + 1;
        while (current < self.len) : (current += 1) self.buffer[current - 1] = self.buffer[current];
        self.len -= 1;
    }

    fn moveCursorToMouse(self: *TextAreaInput, mouse_pos: rl.Vector2) void {
        const padding = rl.Vector2.init(8, 6);
        const relative_y = mouse_pos.y - self.rect.y - padding.y + self.scroll_offset;
        const clicked_line = @max(0, @as(i32, @intFromFloat(@floor(relative_y / self.lineHeight()))));
        const line = @min(@as(usize, @intCast(clicked_line)), self.lineCount() - 1);
        const start = self.lineStartForIndex(line);
        const end = self.lineEnd(start);
        const click_x = mouse_pos.x - self.rect.x - padding.x;
        self.cursor = self.closestCursorOnLine(start, end, click_x);
    }

    fn moveCursorVertically(self: *TextAreaInput, direction: i32) void {
        const current_line = self.lineNumber(self.cursor);
        if (direction < 0 and current_line == 0) return;
        const target_line = if (direction < 0) current_line - 1 else @min(current_line + 1, self.lineCount() - 1);
        const current_start = self.lineStart(self.cursor);
        const column_x = self.getTextWidth(self.buffer[current_start..self.cursor]);
        const target_start = self.lineStartForIndex(target_line);
        self.cursor = self.closestCursorOnLine(target_start, self.lineEnd(target_start), column_x);
    }

    fn closestCursorOnLine(self: *TextAreaInput, start: usize, end: usize, target_x: f32) usize {
        var index = start;
        var closest = start;
        var best_diff = std.math.floatMax(f32);
        while (index <= end) : (index += 1) {
            const width = self.getTextWidth(self.buffer[start..index]);
            const diff = @abs(width - target_x);
            if (diff < best_diff) {
                closest = index;
                best_diff = diff;
            }
        }
        return closest;
    }

    fn cursorPosition(self: *TextAreaInput) rl.Vector2 {
        const start = self.lineStart(self.cursor);
        return .init(self.getTextWidth(self.buffer[start..self.cursor]), @as(f32, @floatFromInt(self.lineNumber(self.cursor))) * self.lineHeight());
    }

    fn lineStart(self: *TextAreaInput, index: usize) usize {
        var current = @min(index, self.len);
        while (current > 0 and self.buffer[current - 1] != '\n') : (current -= 1) {}
        return current;
    }

    fn lineEnd(self: *TextAreaInput, index: usize) usize {
        var current = @min(index, self.len);
        while (current < self.len and self.buffer[current] != '\n') : (current += 1) {}
        return current;
    }

    fn lineStartForIndex(self: *TextAreaInput, line: usize) usize {
        var current: usize = 0;
        var current_line: usize = 0;
        while (current < self.len and current_line < line) : (current += 1) {
            if (self.buffer[current] == '\n') current_line += 1;
        }
        return current;
    }

    fn lineNumber(self: *TextAreaInput, index: usize) usize {
        var line: usize = 0;
        for (self.buffer[0..@min(index, self.len)]) |char| {
            if (char == '\n') line += 1;
        }
        return line;
    }

    fn lineCount(self: *TextAreaInput) usize {
        return self.lineNumber(self.len) + 1;
    }

    fn lineHeight(self: *TextAreaInput) f32 {
        return @as(f32, @floatFromInt(self.font_size));
    }

    fn updateScroll(self: *TextAreaInput) void {
        const cursor_y = self.cursorPosition().y;
        const visible_height = self.rect.height - 12;
        if (cursor_y - self.scroll_offset + self.lineHeight() > visible_height) self.scroll_offset = cursor_y + self.lineHeight() - visible_height;
        if (cursor_y < self.scroll_offset) self.scroll_offset = cursor_y;
        self.clampScroll();
    }

    fn clampScroll(self: *TextAreaInput) void {
        const content_height = @as(f32, @floatFromInt(self.lineCount())) * self.lineHeight();
        const max_scroll = @max(0, content_height - (self.rect.height - 12));
        self.scroll_offset = std.math.clamp(self.scroll_offset, 0, max_scroll);
    }

    fn getTextWidth(self: *TextAreaInput, text: []const u8) f32 {
        if (text.len == 0) return 0;
        const text_z = sliceToZSlice(self.allocator, text) catch return 0;
        defer self.allocator.free(text_z);
        return rl.measureTextEx(self.font, text_z, @as(f32, @floatFromInt(self.font_size)), utils.char_spacing).x;
    }

    fn resetBlink(self: *TextAreaInput) void {
        self.blink_timer = 0;
        self.cursor_visible = true;
    }
};
