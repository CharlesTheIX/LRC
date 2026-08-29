const std = @import("std");
const rl = @import("raylib");
const sliceToZSlice = @import("../utils.zig").sliceToZSlice;

const Props = struct {
    font: rl.Font,
    font_size: i32,
    options: []const []const u8,
    position: rl.Vector2,
    bg_color: rl.Color,
    txt_color: rl.Color,
    border_color: rl.Color,
    highlight_color: rl.Color,
    selected_index: usize = 0,
    callback: ?*const fn (usize) void = null,
    allocator: *std.mem.Allocator,
};

/// A `<select>`-style dropdown: shows the selected option in a closed box, and
/// expands a list of options below it (like a native HTML select) when clicked.
pub const Dropdown = struct {
    font: rl.Font,
    font_size: i32,
    item_height: f32,
    rect: rl.Rectangle,
    bg_color: rl.Color,
    open: bool = false,
    txt_color: rl.Color,
    padding: rl.Vector2,
    visible: bool = true,
    selected_index: usize,
    border_color: rl.Color,
    highlight_color: rl.Color,
    options: []const []const u8,
    hovered_index: ?usize = null,
    allocator: *std.mem.Allocator,
    callback: ?*const fn (usize) void = null,

    pub fn deinit(self: *Dropdown) void {
        _ = self;
    }

    pub fn draw(self: *Dropdown) void {
        if (!self.visible) return;
        self.drawBox(self.rect, self.selectedLabel(), self.bg_color);
        self.drawArrow();
        if (self.open) {
            for (self.options, 0..) |option, i| {
                const item_rect = self.itemRect(i);
                const color = if (self.hovered_index == i) self.highlight_color else self.bg_color;
                self.drawBox(item_rect, option, color);
            }
        }
    }

    pub fn init(props: Props) Dropdown {
        const padding = rl.Vector2.init(10, 5);
        const font_height = @as(f32, @floatFromInt(props.font_size));
        const item_height = font_height + (2 * padding.y);

        var max_label_width: f32 = 0;
        for (props.options) |option| {
            const label_z = sliceToZSlice(props.allocator, option) catch "Failed to convert label string to Z slice";
            defer props.allocator.free(label_z);
            const label_width = @as(f32, @floatFromInt(rl.measureText(label_z, props.font_size)));
            if (label_width > max_label_width) max_label_width = label_width;
        }
        // Reserve extra width on the right for the arrow indicator.
        const width = max_label_width + (2 * padding.x) + item_height;
        const rect = rl.Rectangle.init(props.position.x, props.position.y, width, item_height);

        return Dropdown{
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
            .selected_index = props.selected_index,
            .highlight_color = props.highlight_color,
            .callback = props.callback,
        };
    }

    pub fn update(self: *Dropdown) void {
        const mouse_pos = rl.getMousePosition();
        const clicked = rl.isMouseButtonPressed(rl.MouseButton.left);
        var cursor_set = false;

        if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
            rl.setMouseCursor(rl.MouseCursor.pointing_hand);
            cursor_set = true;
            if (clicked) self.open = !self.open;
        }

        if (self.open) {
            self.hovered_index = null;
            for (self.options, 0..) |_, i| {
                const item_rect = self.itemRect(i);
                if (rl.checkCollisionPointRec(mouse_pos, item_rect)) {
                    self.hovered_index = i;
                    rl.setMouseCursor(rl.MouseCursor.pointing_hand);
                    cursor_set = true;
                    if (clicked) self.select(i);
                }
            }
            // Clicking anywhere else while open closes the list without changing the selection.
            if (clicked and self.hovered_index == null and !rl.checkCollisionPointRec(mouse_pos, self.rect)) {
                self.open = false;
            }
        }

        if (!cursor_set) rl.setMouseCursor(rl.MouseCursor.default);
    }

    fn drawArrow(self: *Dropdown) void {
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

    fn drawBox(self: *Dropdown, rect: rl.Rectangle, label: []const u8, bg_color: rl.Color) void {
        rl.drawRectangleRec(rect, bg_color);
        rl.drawRectangleLinesEx(rect, 1, self.border_color);
        const label_z = sliceToZSlice(self.allocator, label) catch "Failed to convert label string to Z slice";
        defer self.allocator.free(label_z);
        rl.drawTextEx(self.font, label_z, .init(rect.x + self.padding.x, rect.y + self.padding.y), @as(f32, @floatFromInt(self.font_size)), 3, self.txt_color);
    }

    fn itemRect(self: *Dropdown, index: usize) rl.Rectangle {
        return rl.Rectangle.init(self.rect.x, self.rect.y + (self.item_height * @as(f32, @floatFromInt(index + 1))), self.rect.width, self.item_height);
    }

    fn select(self: *Dropdown, index: usize) void {
        self.selected_index = index;
        self.open = false;
        if (self.callback) |cb| cb(index);
    }

    fn selectedLabel(self: *Dropdown) []const u8 {
        if (self.selected_index >= self.options.len) return "";
        return self.options[self.selected_index];
    }
};
