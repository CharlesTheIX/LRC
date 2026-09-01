const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

const spinner_width = 18;

const Props = struct {
    width: f32,
    font: rl.Font,
    font_size: i32,
    bg_color: rl.Color,
    txt_color: rl.Color,
    border_color: rl.Color,
    layout_rect: rl.Rectangle,
    placeholder: []const u8 = "",
    allocator: *std.mem.Allocator,
    initial_value: f64 = 0,
    min: f64 = -std.math.floatMax(f64),
    max: f64 = std.math.floatMax(f64),
    step: f64 = 1,
    allow_float: bool = true,
};

pub const NumberInput = struct {
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
    buffer: [64]u8 = undefined,
    cursor_visible: bool = true,
    allocator: *std.mem.Allocator,
    min: f64,
    max: f64,
    step: f64,
    allow_float: bool,

    pub fn deinit(self: *NumberInput) void {
        self.buffer = undefined;
    }

    pub fn draw(self: *NumberInput) void {
        if (!self.visible) return;
        rl.drawRectangleRec(self.rect, self.bg_color);
        rl.drawRectangleLinesEx(self.rect, if (self.focused) 2 else 1, self.border_color);
        const padding = rl.Vector2.init(8, 6);
        const visible_width = self.rect.width - (2 * padding.x) - spinner_width;
        if (self.len > 0) self.updateScroll(visible_width) else self.scroll_offset = 0;
        const text = if (self.len > 0) self.getValueText() else self.placeholder;
        const text_z = sliceToZSlice(self.allocator, text) catch "Failed to convert text to Z slice";
        defer self.allocator.free(text_z);
        rl.beginScissorMode(@intFromFloat(self.rect.x), @intFromFloat(self.rect.y), @intFromFloat(self.rect.width - spinner_width), @intFromFloat(self.rect.height));
        rl.drawTextEx(self.font, text_z, .init(self.rect.x + padding.x - self.scroll_offset, self.rect.y + padding.y), @as(f32, @floatFromInt(self.font_size)), utils.char_spacing, self.txt_color);
        rl.endScissorMode();
        if (self.focused and self.cursor_visible) {
            const cursor_x = self.rect.x + padding.x + self.getTextWidth(self.buffer[0..self.cursor]) - self.scroll_offset;
            const font_height = @as(f32, @floatFromInt(self.font_size));
            rl.drawLineEx(.init(cursor_x, self.rect.y + padding.y), .init(cursor_x, self.rect.y + padding.y + font_height), 1.0, self.txt_color);
        }
        self.drawSpinner();
    }

    fn drawSpinner(self: *NumberInput) void {
        const x = self.rect.x + self.rect.width - spinner_width;
        rl.drawLineEx(.init(x, self.rect.y), .init(x, self.rect.y + self.rect.height), 1.0, self.border_color);
        const mid_y = self.rect.y + (self.rect.height / 2);
        const arrow_w = 6.0;
        const cx = x + (spinner_width / 2);
        rl.drawTriangle(.init(cx - arrow_w / 2, mid_y - 3), .init(cx + arrow_w / 2, mid_y - 3), .init(cx, mid_y - 8), self.txt_color);
        rl.drawTriangle(.init(cx - arrow_w / 2, mid_y + 3), .init(cx + arrow_w / 2, mid_y + 3), .init(cx, mid_y + 8), self.txt_color);
    }

    fn getTextWidth(self: *NumberInput, text: []const u8) f32 {
        if (text.len == 0) return 0;
        const text_z = sliceToZSlice(self.allocator, text) catch return 0;
        defer self.allocator.free(text_z);
        return rl.measureTextEx(self.font, text_z, @as(f32, @floatFromInt(self.font_size)), utils.char_spacing).x;
    }

    pub fn getValueText(self: *NumberInput) []const u8 {
        return self.buffer[0..self.len];
    }

    pub fn getValue(self: *NumberInput) f64 {
        return std.fmt.parseFloat(f64, self.getValueText()) catch 0;
    }

    pub fn init(props: Props) NumberInput {
        const height = @as(f32, @floatFromInt(props.font_size)) + (2 * 6);
        const input_rect = rl.Rectangle.init(props.layout_rect.x, props.layout_rect.y, props.width, height);
        var input = NumberInput{
            .font = props.font,
            .rect = input_rect,
            .font_size = props.font_size,
            .bg_color = props.bg_color,
            .txt_color = props.txt_color,
            .allocator = props.allocator,
            .border_color = props.border_color,
            .placeholder = props.placeholder,
            .min = props.min,
            .max = props.max,
            .step = props.step,
            .allow_float = props.allow_float,
        };
        input.setValue(props.initial_value);
        return input;
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

    pub fn setValue(self: *NumberInput, new_value: f64) void {
        const clamped = std.math.clamp(new_value, self.min, self.max);
        const text = if (self.allow_float)
            std.fmt.bufPrint(&self.buffer, "{d}", .{clamped}) catch self.buffer[0..0]
        else
            std.fmt.bufPrint(&self.buffer, "{d}", .{@as(i64, @intFromFloat(clamped))}) catch self.buffer[0..0];
        self.len = text.len;
        self.cursor = self.len;
        self.scroll_offset = 0;
    }

    fn step_(self: *NumberInput, direction: f64) void {
        self.setValue(self.getValue() + (self.step * direction));
        self.resetBlink();
    }

    fn isCharAllowed(self: *NumberInput, char: i32) bool {
        if (char >= '0' and char <= '9') return true;
        if (char == '-' and self.cursor == 0 and (self.len == 0 or self.buffer[0] != '-')) return true;
        if (self.allow_float and char == '.' and std.mem.indexOfScalar(u8, self.getValueText(), '.') == null) return true;
        return false;
    }

    pub fn update(self: *NumberInput) void {
        if (!self.visible) return;
        const mouse_pos = rl.getMousePosition();
        const spinner_rect = rl.Rectangle.init(self.rect.x + self.rect.width - spinner_width, self.rect.y, spinner_width, self.rect.height);
        const up_rect = rl.Rectangle.init(spinner_rect.x, spinner_rect.y, spinner_rect.width, spinner_rect.height / 2);
        if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
            rl.setMouseCursor(if (rl.checkCollisionPointRec(mouse_pos, spinner_rect)) .default else .ibeam);
            if (rl.isMouseButtonPressed(.left)) {
                self.focused = true;
                if (rl.checkCollisionPointRec(mouse_pos, spinner_rect)) {
                    self.step_(if (rl.checkCollisionPointRec(mouse_pos, up_rect)) 1 else -1);
                } else {
                    self.moveCursorToMouse(mouse_pos);
                    self.resetBlink();
                }
            }
        } else {
            rl.setMouseCursor(.default);
            if (rl.isMouseButtonPressed(.left)) {
                self.focused = false;
                self.setValue(self.getValue());
            }
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
            if (self.len >= self.buffer.len) continue;
            if (!self.isCharAllowed(char)) continue;
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
        if (rl.isKeyPressed(.up) or rl.isKeyPressedRepeat(.up)) self.step_(1);
        if (rl.isKeyPressed(.down) or rl.isKeyPressedRepeat(.down)) self.step_(-1);
        if (edited) self.resetBlink();
    }

    fn updateScroll(self: *NumberInput, visible_width: f32) void {
        const cursor_x = self.getTextWidth(self.buffer[0..self.cursor]);
        if (cursor_x - self.scroll_offset > visible_width) self.scroll_offset = cursor_x - visible_width;
        if (cursor_x - self.scroll_offset < 0) self.scroll_offset = cursor_x;
        const total_width = self.getTextWidth(self.getValueText());
        const max_scroll = @max(0, total_width - visible_width);
        self.scroll_offset = std.math.clamp(self.scroll_offset, 0, max_scroll);
    }
};
