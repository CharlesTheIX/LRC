const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const ui_utils = @import("../utils.zig");
const sliceToZSlice = @import("../../../utils.zig").sliceToZSlice;

const Props = struct {
    width: f32,
    font: rl.Font,
    step: f64 = 1,
    id: []const u8,
    bg_color: rl.Color,
    font_size: u32 = 16,
    txt_color: rl.Color,
    draw_pos: *rl.Vector2,
    border_color: rl.Color,
    initial_value: f64 = 0,
    allow_float: bool = true,
    label: ?[]const u8 = null,
    placeholder: []const u8 = "",
    allocator: *std.mem.Allocator,
    max: f64 = std.math.floatMax(f64),
    min: f64 = -std.math.floatMax(f64),
};

pub const NumberInput = struct {
    min: f64,
    max: f64,
    step: f64,
    font: rl.Font,
    id: []const u8,
    len: usize = 0,
    font_size: u32,
    allow_float: bool,
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
    buffer: [64]u8 = undefined,
    cursor_visible: bool = true,
    allocator: *std.mem.Allocator,

    // Base methods
    pub fn deinit(self: *NumberInput) void {
        self.buffer = undefined;
    }

    pub fn draw(self: *NumberInput) void {
        if (!self.visible) return;
        self.drawLabel();
        self.drawRectangle();
        self.drawText();
        self.drawCursor();
        self.drawSpinner();
    }

    pub fn init(props: Props) NumberInput {
        var label_pos: ?rl.Vector2 = null;
        const font_size_f32 = @as(f32, @floatFromInt(props.font_size));
        const padding = rl.Vector2.init(@divFloor(font_size_f32, 2), @divFloor(font_size_f32, 4));
        const height = @as(f32, @floatFromInt(props.font_size)) + (2 * padding.y);
        var input_rect = rl.Rectangle.init(props.draw_pos.x, props.draw_pos.y, props.width, height);
        if (props.label) |label| {
            _ = label;
            input_rect.y += font_size_f32 + padding.y;
            label_pos = rl.Vector2.init(props.draw_pos.x, props.draw_pos.y);
        }
        var input = NumberInput{
            .min = props.min,
            .max = props.max,
            .step = props.step,
            .font = props.font,
            .id = props.id,
            .padding = padding,
            .rect = input_rect,
            .label_pos = label_pos,
            .label = props.label,
            .font_size = props.font_size,
            .bg_color = props.bg_color,
            .txt_color = props.txt_color,
            .allow_float = props.allow_float,
            .allocator = props.allocator,
            .border_color = props.border_color,
            .placeholder = props.placeholder,
        };
        input.setValue(props.initial_value);
        return input;
    }

    pub fn update(self: *NumberInput) void {
        if (!self.visible) return;
        if (ui_utils.isBlockedByFocusedElement(self.id)) {
            if (self.focused) self.focused = false;
            return;
        }
        self.updateFocus();
        if (!self.focused) return;
        self.updateCursorBlink();
        self.updateUserInput();
    }

    // Helper methods
    fn drawCursor(self: *NumberInput) void {
        if (self.focused and self.cursor_visible) {
            const cursor_x = self.rect.x + self.padding.x + self.getTextWidth(self.buffer[0..self.cursor]) - self.scroll_offset;
            const font_height = @as(f32, @floatFromInt(self.font_size));
            rl.drawLineEx(.init(cursor_x, self.rect.y + self.padding.y), .init(cursor_x, self.rect.y + self.padding.y + font_height), 1.0, self.txt_color);
        }
    }

    fn drawLabel(self: *NumberInput) void {
        if (self.label) |label| {
            if (self.label_pos) |label_pos| {
                const label_str = sliceToZSlice(self.allocator, label) catch @panic("Failed to convert label to Z slice");
                defer self.allocator.free(label_str);
                rl.drawTextEx(self.font, label_str, label_pos, @as(f32, @floatFromInt(self.font_size)), utils.getCharSpacing(self.font_size), self.txt_color);
            }
        }
    }

    fn drawRectangle(self: *NumberInput) void {
        const border_thickness: f32 = if (self.focused) 2 else 1;
        rl.drawRectangleRec(self.rect, self.bg_color);
        rl.drawRectangleLinesEx(self.rect, border_thickness, self.border_color);
    }

    fn drawSpinner(self: *NumberInput) void {
        const x = self.rect.x + self.rect.width - utils.spinner_width;
        rl.drawLineEx(.init(x, self.rect.y), .init(x, self.rect.y + self.rect.height), 1.0, self.border_color);
        const mid_y = self.rect.y + (self.rect.height / 2);
        const arrow_w = 6.0;
        const cx = x + (utils.spinner_width / 2);
        rl.drawTriangle(.init(cx - arrow_w / 2, mid_y - 3), .init(cx + arrow_w / 2, mid_y - 3), .init(cx, mid_y - 8), self.txt_color);
        rl.drawTriangle(.init(cx - arrow_w / 2, mid_y + 3), .init(cx, mid_y + 8), .init(cx + arrow_w / 2, mid_y + 3), self.txt_color);
    }

    fn drawText(self: *NumberInput) void {
        const visible_width = self.rect.width - (2 * self.padding.x);
        if (self.len > 0) self.updateScroll(visible_width) else self.scroll_offset = 0;
        const text = if (self.len > 0) self.getValueText() else self.placeholder;
        const text_z = sliceToZSlice(self.allocator, text) catch return;
        defer self.allocator.free(text_z);
        rl.beginScissorMode(@intFromFloat(self.rect.x), @intFromFloat(self.rect.y), @intFromFloat(self.rect.width - utils.spinner_width), @intFromFloat(self.rect.height));
        rl.drawTextEx(self.font, text_z, .init(self.rect.x + self.padding.x - self.scroll_offset, self.rect.y + self.padding.y), @as(f32, @floatFromInt(self.font_size)), utils.getCharSpacing(self.font_size), self.txt_color);
        rl.endScissorMode();
    }

    fn getTextWidth(self: *NumberInput, text: []const u8) f32 {
        if (text.len == 0) return 0;
        const text_z = sliceToZSlice(self.allocator, text) catch return 0;
        defer self.allocator.free(text_z);
        return rl.measureTextEx(self.font, text_z, @as(f32, @floatFromInt(self.font_size)), utils.getCharSpacing(self.font_size)).x;
    }

    pub fn getValue(self: *NumberInput) f64 {
        return std.fmt.parseFloat(f64, self.getValueText()) catch 0;
    }

    pub fn getValueText(self: *NumberInput) []const u8 {
        return self.buffer[0..self.len];
    }

    fn handleBackspace(self: *NumberInput, edited: *bool) void {
        var i = self.cursor;
        while (i < self.len) : (i += 1) self.buffer[i - 1] = self.buffer[i];
        edited.* = true;
        self.len -= 1;
        self.cursor -= 1;
    }

    fn handleDelete(self: *NumberInput, edited: *bool) void {
        var i = self.cursor + 1;
        while (i < self.len) : (i += 1) self.buffer[i - 1] = self.buffer[i];
        self.len -= 1;
        edited.* = true;
    }

    fn handleStep(self: *NumberInput, direction: f64, edited: ?*bool) void {
        self.setValue(self.getValue() + (self.step * direction));
        if (edited) |e| e.* = true;
    }

    fn isCharAllowed(self: *NumberInput, char: i32) bool {
        if (char >= '0' and char <= '9') return true;
        if (char == '-' and self.cursor == 0 and (self.len == 0 or self.buffer[0] != '-')) return true;
        if (self.allow_float and char == '.' and std.mem.indexOfScalar(u8, self.getValueText(), '.') == null) return true;
        return false;
    }

    fn moveCursorToMouse(self: *NumberInput, mouse_pos: rl.Vector2) void {
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

    fn resetBlink(self: *NumberInput) void {
        self.blink_timer = 0;
        self.cursor_visible = true;
    }

    fn setCursorEnd(self: *NumberInput, edited: *bool) void {
        edited.* = true;
        self.cursor = self.len;
    }

    fn setCursorStart(self: *NumberInput, edited: *bool) void {
        edited.* = true;
        self.cursor = 0;
    }

    pub fn setValue(self: *NumberInput, new_value: f64) void {
        const clamped = std.math.clamp(new_value, self.min, self.max);
        const text = if (self.allow_float) std.fmt.bufPrint(&self.buffer, "{d}", .{clamped}) catch self.buffer[0..0] else std.fmt.bufPrint(&self.buffer, "{d}", .{@as(i64, @intFromFloat(clamped))}) catch self.buffer[0..0];
        self.len = text.len;
        self.cursor = self.len;
        self.scroll_offset = 0;
    }

    fn shiftCursorLeft(self: *NumberInput, edited: *bool) void {
        edited.* = true;
        self.cursor -= 1;
    }

    fn shiftCursorRight(self: *NumberInput, edited: *bool) void {
        edited.* = true;
        self.cursor += 1;
    }

    fn updateScroll(self: *NumberInput, visible_width: f32) void {
        const cursor_x = self.getTextWidth(self.buffer[0..self.cursor]);
        if (cursor_x - self.scroll_offset > visible_width) self.scroll_offset = cursor_x - visible_width;
        if (cursor_x - self.scroll_offset < 0) self.scroll_offset = cursor_x;
        const total_width = self.getTextWidth(self.getValueText());
        const max_scroll = @max(0, total_width - visible_width);
        self.scroll_offset = std.math.clamp(self.scroll_offset, 0, max_scroll);
    }

    fn updateCursorBlink(self: *NumberInput) void {
        self.blink_timer += rl.getFrameTime();
        if (self.blink_timer >= utils.cursor_blink_interval) {
            self.cursor_visible = !self.cursor_visible;
            self.blink_timer -= utils.cursor_blink_interval;
        }
    }

    fn updateFocus(self: *NumberInput) void {
        const mouse_pos = rl.getMousePosition();
        const spinner_rect = rl.Rectangle.init(self.rect.x + self.rect.width - utils.spinner_width, self.rect.y, utils.spinner_width, self.rect.height);
        if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
            const up_rect = rl.Rectangle.init(spinner_rect.x, spinner_rect.y, spinner_rect.width, spinner_rect.height / 2);
            if (rl.checkCollisionPointRec(mouse_pos, spinner_rect)) {
                rl.setMouseCursor(.pointing_hand);
                if (rl.checkCollisionPointRec(mouse_pos, up_rect)) {} else {} // This can be used to visually indicate which part of the spinner is being hovered over at a later date
            } else rl.setMouseCursor(.ibeam);
            if (rl.isMouseButtonPressed(.left)) {
                self.focused = true;
                ui_utils.claimFocus(self.id);
                if (rl.checkCollisionPointRec(mouse_pos, spinner_rect)) {
                    self.handleStep(if (rl.checkCollisionPointRec(mouse_pos, up_rect)) 1 else -1, null);
                } else {
                    self.resetBlink();
                    self.moveCursorToMouse(mouse_pos);
                }
            }
        } else if (rl.isMouseButtonPressed(.left)) {
            self.focused = false;
            self.setValue(self.getValue());
            if (ui_utils.hasFocus(self.id)) ui_utils.clearFocus();
        }
    }

    fn updateUserInput(self: *NumberInput) void {
        var edited = false;
        while (true) {
            const char = rl.getCharPressed();
            if (char == 0) break;
            if (char < 32 or char > 126) continue;
            if (!self.isCharAllowed(char)) continue;
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
        if (rl.isKeyPressed(.up) or rl.isKeyPressedRepeat(.up)) self.handleStep(1, &edited);
        if (rl.isKeyPressed(.down) or rl.isKeyPressedRepeat(.down)) self.handleStep(-1, &edited);
        if ((rl.isKeyPressed(.left) or rl.isKeyPressedRepeat(.left)) and self.cursor > 0) self.shiftCursorLeft(&edited);
        if ((rl.isKeyPressed(.delete) or rl.isKeyPressedRepeat(.delete)) and self.cursor < self.len) self.handleDelete(&edited);
        if ((rl.isKeyPressed(.backspace) or rl.isKeyPressedRepeat(.backspace)) and self.cursor > 0) self.handleBackspace(&edited);
        if ((rl.isKeyPressed(.right) or rl.isKeyPressedRepeat(.right)) and self.cursor < self.len) self.shiftCursorRight(&edited);
        if (edited) self.resetBlink();
    }
};
