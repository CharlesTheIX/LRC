const std = @import("std");
const rl = @import("raylib");
const sliceToZSlice = @import("../../../utils.zig").sliceToZSlice;

const Props = struct {
    font: rl.Font,
    font_size: i32,
    bg_color: rl.Color,
    txt_color: rl.Color,
    position: rl.Vector2,
    border_color: rl.Color,
    highlight_color: rl.Color,
    selected_index: usize = 0,
    options: []const []const u8,
    allocator: *std.mem.Allocator,
    callback: ?*const fn (usize) void = null,
};

/// A `<select>`-style select: shows the selected option in a closed box, and
/// expands a list of options below it (like a native HTML select) when clicked.
pub const SelectInput = struct {
    font: rl.Font,
    font_size: i32,
    item_height: f32,
    rect: rl.Rectangle,
    bg_color: rl.Color,
    open: bool = false,
    txt_color: rl.Color,
    padding: rl.Vector2,
    visible: bool = true,
    focused: bool = false,
    selected_index: usize,
    border_color: rl.Color,
    highlight_color: rl.Color,
    options: []const []const u8,
    hovered_index: ?usize = null,
    active_index: ?usize = null,
    allocator: *std.mem.Allocator,
    callback: ?*const fn (usize) void = null,

    pub fn deinit(self: *SelectInput) void {
        _ = self;
    }

    pub fn draw(self: *SelectInput) void {
        if (!self.visible) return;
        self.drawBox(self.rect, self.selectedLabel(), self.bg_color);
        self.drawArrow();
        if (self.open) {
            for (self.options, 0..) |option, i| {
                const item_rect = self.itemRect(i);
                const color = if (self.hovered_index == i or self.active_index == i) self.highlight_color else self.bg_color;
                self.drawBox(item_rect, option, color);
            }
        }
    }

    pub fn init(props: Props) SelectInput {
        var max_label_width: f32 = 0;
        const padding = rl.Vector2.init(10, 5);
        const font_height = @as(f32, @floatFromInt(props.font_size));
        const item_height = font_height + (2 * padding.y);
        for (props.options) |option| {
            const label_z = sliceToZSlice(props.allocator, option) catch continue;
            defer props.allocator.free(label_z);
            const label_width = @as(f32, @floatFromInt(rl.measureText(label_z, props.font_size)));
            if (label_width > max_label_width) max_label_width = label_width;
        }
        // Reserve extra width on the right for the arrow indicator.
        const width = max_label_width + (2 * padding.x) + item_height;
        const rect = rl.Rectangle.init(props.position.x, props.position.y, width, item_height);
        return SelectInput{
            .rect = rect,
            .font = props.font,
            .padding = padding,
            .item_height = item_height,
            .bg_color = props.bg_color,
            .font_size = props.font_size,
            .txt_color = props.txt_color,
            .allocator = props.allocator,
            .border_color = props.border_color,
            .options = props.options,
            .selected_index = if (props.options.len == 0) 0 else @min(props.selected_index, props.options.len - 1),
            .highlight_color = props.highlight_color,
            .callback = props.callback,
        };
    }

    pub fn update(self: *SelectInput) void {
        if (!self.visible) return;
        var cursor_set = false;
        const mouse_pos = rl.getMousePosition();
        const clicked = rl.isMouseButtonPressed(rl.MouseButton.left);
        if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
            rl.setMouseCursor(rl.MouseCursor.pointing_hand);
            cursor_set = true;
            if (clicked) {
                self.focused = true;
                self.open = !self.open;
                self.active_index = if (self.open and self.options.len > 0) self.selected_index else null;
            }
        } else if (clicked and !self.open) {
            self.focused = false;
        }
        if (self.open) {
            self.hovered_index = null;
            for (self.options, 0..) |_, i| {
                const item_rect = self.itemRect(i);
                if (rl.checkCollisionPointRec(mouse_pos, item_rect)) {
                    self.hovered_index = i;
                    self.active_index = i;
                    rl.setMouseCursor(rl.MouseCursor.pointing_hand);
                    cursor_set = true;
                    if (clicked) self.select(i);
                }
            }
            // Clicking anywhere else while open closes the list without changing the selection.
            if (clicked and self.hovered_index == null and !rl.checkCollisionPointRec(mouse_pos, self.rect)) {
                self.open = false;
                self.active_index = null;
                self.focused = false;
            }
        }

        if (!cursor_set) rl.setMouseCursor(rl.MouseCursor.default);
        if (!self.focused or self.options.len == 0) return;

        if (rl.isKeyPressed(.escape)) {
            self.open = false;
            self.active_index = null;
            return;
        }
        if (rl.isKeyPressed(.enter) or rl.isKeyPressed(.space)) {
            if (self.open) {
                if (self.active_index) |index| self.select(index);
            } else {
                self.open = true;
                self.active_index = self.selected_index;
            }
            return;
        }

        const up_pressed = rl.isKeyPressed(.up) or rl.isKeyPressedRepeat(.up);
        const down_pressed = rl.isKeyPressed(.down) or rl.isKeyPressedRepeat(.down);
        if (up_pressed or down_pressed) {
            const current = self.active_index orelse self.selected_index;
            const last_index = self.options.len - 1;
            const next_index = if (up_pressed)
                if (current == 0) 0 else current - 1
            else if (current == last_index)
                last_index
            else
                current + 1;
            if (self.open) {
                self.active_index = next_index;
            } else if (next_index != self.selected_index) {
                self.select(next_index);
            }
        }
    }

    fn drawArrow(self: *SelectInput) void {
        const size: f32 = 5;
        const center_x = self.rect.x + self.rect.width - self.padding.x - size;
        const center_y = self.rect.y + (self.rect.height / 2);
        const direction: f32 = if (self.open) -1 else 1;
        rl.drawTriangle(
            .init(center_x - size, center_y - (direction * size / 2)),
            .init(center_x + size, center_y - (direction * size / 2)),
            .init(center_x, center_y + (direction * size / 2)),
            self.txt_color,
        );
    }

    fn drawBox(self: *SelectInput, rect: rl.Rectangle, label: []const u8, bg_color: rl.Color) void {
        rl.drawRectangleRec(rect, bg_color);
        const border_width: f32 = if (rect.y == self.rect.y and self.focused) 2 else 1;
        rl.drawRectangleLinesEx(rect, border_width, self.border_color);
        const label_z = sliceToZSlice(self.allocator, label) catch return;
        defer self.allocator.free(label_z);
        rl.drawTextEx(self.font, label_z, .init(rect.x + self.padding.x, rect.y + self.padding.y), @as(f32, @floatFromInt(self.font_size)), 3, self.txt_color);
    }

    fn itemRect(self: *SelectInput, index: usize) rl.Rectangle {
        return rl.Rectangle.init(self.rect.x, self.rect.y + (self.item_height * @as(f32, @floatFromInt(index + 1))), self.rect.width, self.item_height);
    }

    fn select(self: *SelectInput, index: usize) void {
        self.selected_index = index;
        self.open = false;
        self.active_index = null;
        if (self.callback) |cb| cb(index);
    }

    fn selectedLabel(self: *SelectInput) []const u8 {
        if (self.selected_index >= self.options.len) return "";
        return self.options[self.selected_index];
    }
};
