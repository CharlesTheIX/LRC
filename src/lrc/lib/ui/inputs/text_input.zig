const std = @import("std");
const rl = @import("raylib");
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

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
    initial_value: []const u8 = "",
};

pub const TextInput = struct {
    font: rl.Font,
    len: usize = 0,
    font_size: i32,
    rect: rl.Rectangle,
    bg_color: rl.Color,
    txt_color: rl.Color,
    visible: bool = true,
    focused: bool = false,
    border_color: rl.Color,
    placeholder: []const u8,
    buffer: [128]u8 = undefined,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *TextInput) void {
        self.buffer = undefined;
    }

    pub fn draw(self: *TextInput) void {
        if (!self.visible) return;
        rl.drawRectangleRec(self.rect, self.bg_color);
        rl.drawRectangleLinesEx(self.rect, if (self.focused) 2 else 1, self.border_color);
        const padding = rl.Vector2.init(8, 6);
        const text = if (self.len > 0) self.getValue() else self.placeholder;
        const text_z = sliceToZSlice(self.allocator, text) catch "Failed to convert text to Z slice";
        defer self.allocator.free(text_z);
        rl.drawTextEx(self.font, text_z, .init(self.rect.x + padding.x, self.rect.y + padding.y), @as(f32, @floatFromInt(self.font_size)), 2.0, self.txt_color);
    }

    pub fn init(props: Props) TextInput {
        const font_height = @as(f32, @floatFromInt(props.font_size));
        const height = font_height + (2 * 6);
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

    pub fn setValue(self: *TextInput, new_value: []const u8) void {
        const len = @min(new_value.len, self.buffer.len);
        @memcpy(self.buffer[0..len], new_value[0..len]);
        self.len = len;
    }

    pub fn update(self: *TextInput) void {
        if (!self.visible) return;
        const mouse_pos = rl.getMousePosition();
        if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
            rl.setMouseCursor(.ibeam);
            if (rl.isMouseButtonPressed(.left)) self.focused = true;
        } else {
            rl.setMouseCursor(.default);
            if (rl.isMouseButtonPressed(.left)) self.focused = false;
        }
        if (!self.focused) return;
        while (true) {
            const char = rl.getCharPressed();
            if (char == 0) break;
            if (char < 32 or char > 126) continue;
            if (self.len >= self.buffer.len) continue;
            self.buffer[self.len] = @intCast(char);
            self.len += 1;
        }
        if ((rl.isKeyPressed(.backspace) or rl.isKeyPressedRepeat(.backspace)) and self.len > 0) self.len -= 1;
    }

    pub fn getValue(self: *TextInput) []const u8 {
        return self.buffer[0..self.len];
    }
};
