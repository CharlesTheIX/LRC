const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const ui_utils = @import("../utils.zig");
const sliceToZSlice = @import("../../../utils.zig").sliceToZSlice;

const Props = struct {
    width: f32,
    font: rl.Font,
    id: []const u8,
    height: f32 = 120,
    bg_color: rl.Color,
    txt_color: rl.Color,
    font_size: u32 = 16,
    draw_pos: *rl.Vector2,
    border_color: rl.Color,
    label: ?[]const u8 = null,
    placeholder: []const u8 = "",
    allocator: *std.mem.Allocator,
    initial_value: []const u8 = "",
};

pub const TextAreaInput = struct {
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
    line_count: usize = 1,
    scroll_offset: f32 = 0,
    border_color: rl.Color,
    label_pos: ?rl.Vector2,
    placeholder: []const u8,
    cursor_visible: bool = true,
    buffer: [1024]u8 = undefined,
    allocator: *std.mem.Allocator,
    lines: [1025]utils.Line = undefined,

    // Base methods
    pub fn deinit(self: *TextAreaInput) void {
        self.lines = undefined;
        self.buffer = undefined;
    }

    pub fn draw(self: *TextAreaInput) void {
        if (!self.visible) return;
        self.refreshLines();
        self.drawLabel();
        self.drawRectangle();
        self.drawText();
        self.drawCursor();
    }

    pub fn init(props: Props) TextAreaInput {
        var label_pos: ?rl.Vector2 = null;
        const font_size_f32 = @as(f32, @floatFromInt(props.font_size));
        const padding = rl.Vector2.init(@divFloor(font_size_f32, 2), @divFloor(font_size_f32, 4));
        var input_rect = rl.Rectangle.init(props.draw_pos.x, props.draw_pos.y, props.width, props.height);
        if (props.label) |_| {
            input_rect.y += font_size_f32 + padding.y;
            label_pos = rl.Vector2.init(props.draw_pos.x, props.draw_pos.y);
        }
        var input = TextAreaInput{
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

    pub fn update(self: *TextAreaInput) void {
        if (!self.visible) return;
        if (ui_utils.isBlockedByFocusedElement(self.id)) {
            if (self.focused) self.focused = false;
            return;
        }
        self.refreshLines();
        self.updateFocus();
        if (!self.focused) return;
        self.updateCursorBlink();
        self.updateUserInput();
        self.updateScroll();
    }

    // Helper methods
    fn clampScroll(self: *TextAreaInput) void {
        const content_height = @as(f32, @floatFromInt(self.line_count)) * self.lineHeight();
        const visible_height = self.rect.height - (2 * self.padding.y);
        const max_scroll = @max(0, content_height - visible_height);
        self.scroll_offset = std.math.clamp(self.scroll_offset, 0, max_scroll);
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
        const line_index = self.lineIndexForCursor();
        const line = self.lines[line_index];
        const x = self.getTextWidth(self.buffer[line.start..self.cursor]);
        return .init(x, @as(f32, @floatFromInt(line_index)) * self.lineHeight());
    }

    fn deleteAt(self: *TextAreaInput, index: usize) void {
        var current = index + 1;
        while (current < self.len) : (current += 1) self.buffer[current - 1] = self.buffer[current];
        self.len -= 1;
        self.refreshLines();
    }

    fn drawCursor(self: *TextAreaInput) void {
        if (self.focused and self.cursor_visible) {
            const position = self.cursorPosition();
            const cursor_x = self.rect.x + self.padding.x + position.x;
            const cursor_y = self.rect.y + self.padding.y + position.y - self.scroll_offset;
            const font_height = @as(f32, @floatFromInt(self.font_size));
            rl.drawLineEx(.init(cursor_x, cursor_y), .init(cursor_x, cursor_y + font_height), 1.0, self.txt_color);
        }
    }

    fn drawLabel(self: *TextAreaInput) void {
        if (self.label) |label| {
            if (self.label_pos) |label_pos| {
                const label_str = sliceToZSlice(self.allocator, label) catch @panic("Failed to convert label to Z slice");
                defer self.allocator.free(label_str);
                rl.drawTextEx(self.font, label_str, label_pos, @as(f32, @floatFromInt(self.font_size)), ui_utils.getCharSpacing(self.font_size), self.txt_color);
            }
        }
    }

    fn drawRectangle(self: *TextAreaInput) void {
        const border_thickness: f32 = if (self.focused) 2 else 1;
        rl.drawRectangleRec(self.rect, self.bg_color);
        rl.drawRectangleLinesEx(self.rect, border_thickness, self.border_color);
    }

    fn drawText(self: *TextAreaInput) void {
        rl.beginScissorMode(@intFromFloat(self.rect.x), @intFromFloat(self.rect.y), @intFromFloat(self.rect.width), @intFromFloat(self.rect.height));
        defer rl.endScissorMode();
        if (self.len == 0) {
            const text_z = sliceToZSlice(self.allocator, self.placeholder) catch return;
            defer self.allocator.free(text_z);
            rl.drawTextEx(self.font, text_z, .init(self.rect.x + self.padding.x, self.rect.y + self.padding.y), @as(f32, @floatFromInt(self.font_size)), ui_utils.getCharSpacing(self.font_size), self.txt_color);
            return;
        }
        for (self.lines[0..self.line_count], 0..) |line, i| {
            if (line.end == line.start) continue;
            const y = self.rect.y + self.padding.y + (@as(f32, @floatFromInt(i)) * self.lineHeight()) - self.scroll_offset;
            const text_z = sliceToZSlice(self.allocator, self.buffer[line.start..line.end]) catch continue;
            defer self.allocator.free(text_z);
            rl.drawTextEx(self.font, text_z, .init(self.rect.x + self.padding.x, y), @as(f32, @floatFromInt(self.font_size)), ui_utils.getCharSpacing(self.font_size), self.txt_color);
        }
    }

    fn getTextWidth(self: *TextAreaInput, text: []const u8) f32 {
        if (text.len == 0) return 0;
        const text_z = sliceToZSlice(self.allocator, text) catch return 0;
        defer self.allocator.free(text_z);
        return rl.measureTextEx(self.font, text_z, @as(f32, @floatFromInt(self.font_size)), ui_utils.getCharSpacing(self.font_size)).x;
    }

    pub fn getValue(self: *TextAreaInput) []const u8 {
        return self.buffer[0..self.len];
    }

    fn insert(self: *TextAreaInput, char: u8) void {
        var index = self.len;
        while (index > self.cursor) : (index -= 1) self.buffer[index] = self.buffer[index - 1];
        self.buffer[self.cursor] = char;
        self.len += 1;
        self.cursor += 1;
        self.refreshLines();
    }

    fn lineHeight(self: *TextAreaInput) f32 {
        return @as(f32, @floatFromInt(self.font_size));
    }

    // Returns the index (into self.lines) of the visual line the cursor sits on, preferring the start of the next line when the cursor sits exactly on a word-wrap boundary.
    fn lineIndexForCursor(self: *TextAreaInput) usize {
        var i: usize = 0;
        while (i < self.line_count) : (i += 1) {
            const line = self.lines[i];
            if (self.cursor < line.end) return i;
            if (self.cursor == line.end) {
                const is_last = i + 1 == self.line_count;
                if (is_last or self.lines[i + 1].start != line.end) return i;
            }
        }
        return self.line_count - 1;
    }

    fn moveCursorToMouse(self: *TextAreaInput, mouse_pos: rl.Vector2) void {
        const relative_y = mouse_pos.y - self.rect.y - self.padding.y + self.scroll_offset;
        const clicked_line = @max(0, @as(i32, @intFromFloat(@floor(relative_y / self.lineHeight()))));
        const line_index = @min(@as(usize, @intCast(clicked_line)), self.line_count - 1);
        const line = self.lines[line_index];
        const click_x = mouse_pos.x - self.rect.x - self.padding.x;
        self.cursor = self.closestCursorOnLine(line.start, line.end, click_x);
    }

    fn moveCursorVertically(self: *TextAreaInput, direction: i32) void {
        const current_line = self.lineIndexForCursor();
        if (direction < 0 and current_line == 0) return;
        if (direction > 0 and current_line + 1 >= self.line_count) return;
        const target_line = if (direction < 0) current_line - 1 else current_line + 1;
        const line = self.lines[current_line];
        const column_x = self.getTextWidth(self.buffer[line.start..self.cursor]);
        const target = self.lines[target_line];
        self.cursor = self.closestCursorOnLine(target.start, target.end, column_x);
    }

    // Recomputes word-wrapped visual lines for the current buffer contents and rect width.
    fn refreshLines(self: *TextAreaInput) void {
        const max_width = @max(self.rect.width - (2 * self.padding.x), 1);
        self.line_count = 0;
        var seg_start: usize = 0;
        var i: usize = 0;
        while (i <= self.len) : (i += 1) {
            if (i == self.len or self.buffer[i] == '\n') {
                self.line_count += self.wrapSegment(seg_start, i, max_width, self.line_count);
                seg_start = i + 1;
            }
        }
        if (self.line_count == 0) self.line_count = 1;
    }

    fn resetBlink(self: *TextAreaInput) void {
        self.blink_timer = 0;
        self.cursor_visible = true;
    }

    pub fn setValue(self: *TextAreaInput, new_value: []const u8) void {
        const len = @min(new_value.len, self.buffer.len);
        @memcpy(self.buffer[0..len], new_value[0..len]);
        self.len = len;
        self.cursor = len;
        self.scroll_offset = 0;
        self.refreshLines();
    }

    fn updateCursorBlink(self: *TextAreaInput) void {
        self.blink_timer += rl.getFrameTime();
        if (self.blink_timer >= utils.cursor_blink_interval) {
            self.cursor_visible = !self.cursor_visible;
            self.blink_timer -= utils.cursor_blink_interval;
        }
    }

    fn updateFocus(self: *TextAreaInput) void {
        const mouse_pos = rl.getMousePosition();
        if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
            rl.setMouseCursor(.ibeam);
            if (rl.isMouseButtonPressed(.left)) {
                self.resetBlink();
                self.focused = true;
                ui_utils.claimFocus(self.id);
                self.moveCursorToMouse(mouse_pos);
            }
            const wheel_move = rl.getMouseWheelMove();
            if (wheel_move != 0) {
                self.scroll_offset -= wheel_move * self.lineHeight() * 3;
                self.clampScroll();
            }
        } else if (rl.isMouseButtonPressed(.left)) {
            self.focused = false;
            if (ui_utils.hasFocus(self.id)) ui_utils.clearFocus();
        }
    }

    fn updateScroll(self: *TextAreaInput) void {
        const cursor_y = self.cursorPosition().y;
        const visible_height = self.rect.height - (2 * self.padding.y);
        if (cursor_y - self.scroll_offset + self.lineHeight() > visible_height) self.scroll_offset = cursor_y + self.lineHeight() - visible_height;
        if (cursor_y < self.scroll_offset) self.scroll_offset = cursor_y;
        self.clampScroll();
    }

    fn updateUserInput(self: *TextAreaInput) void {
        var edited = false;
        while (true) {
            const char = rl.getCharPressed();
            if (char == 0) break;
            if (char < 32 or char > 126 or self.len >= self.buffer.len) continue;
            edited = true;
            self.insert(@intCast(char));
        }
        if (rl.isKeyPressed(.enter) and self.len < self.buffer.len) {
            edited = true;
            self.insert('\n');
        }
        if ((rl.isKeyPressed(.backspace) or rl.isKeyPressedRepeat(.backspace)) and self.cursor > 0) {
            self.deleteAt(self.cursor - 1);
            edited = true;
            self.cursor -= 1;
        }
        if ((rl.isKeyPressed(.delete) or rl.isKeyPressedRepeat(.delete)) and self.cursor < self.len) {
            edited = true;
            self.deleteAt(self.cursor);
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
            self.cursor = self.lines[self.lineIndexForCursor()].start;
        }
        if (rl.isKeyPressed(.end)) {
            edited = true;
            self.cursor = self.lines[self.lineIndexForCursor()].end;
        }
        if (rl.isKeyPressed(.up) or rl.isKeyPressedRepeat(.up)) {
            edited = true;
            self.moveCursorVertically(-1);
        }
        if (rl.isKeyPressed(.down) or rl.isKeyPressedRepeat(.down)) {
            edited = true;
            self.moveCursorVertically(1);
        }
        if (edited) self.resetBlink();
    }

    // Greedily packs buffer[start..end] (a single hard line with no '\n') into word-wrapped visual lines no wider than max_width, writing results into self.lines starting at out_offset.
    fn wrapSegment(self: *TextAreaInput, start: usize, end: usize, max_width: f32, out_offset: usize) usize {
        if (start == end) {
            self.lines[out_offset] = .{ .start = start, .end = end };
            return 1;
        }
        var count: usize = 0;
        var line_start = start;
        var last_space: ?usize = null;
        var i = start;
        while (i < end) : (i += 1) {
            if (self.buffer[i] == ' ') last_space = i;
            const width = self.getTextWidth(self.buffer[line_start .. i + 1]);
            if (width > max_width and i > line_start) {
                if (last_space) |space_idx| {
                    if (space_idx >= line_start) {
                        self.lines[out_offset + count] = .{ .start = line_start, .end = space_idx };
                        count += 1;
                        last_space = null;
                        line_start = space_idx + 1;
                        continue;
                    }
                }
                self.lines[out_offset + count] = .{ .start = line_start, .end = i };
                count += 1;
                line_start = i;
                last_space = null;
            }
        }
        self.lines[out_offset + count] = .{ .start = line_start, .end = end };
        count += 1;
        return count;
    }
};
