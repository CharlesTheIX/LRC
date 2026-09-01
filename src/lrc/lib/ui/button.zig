const std = @import("std");
const rl = @import("raylib");
const sliceToZSlice = @import("../utils.zig").sliceToZSlice;

const Props = struct { font: rl.Font, font_size: i32, label: []const u8, bg_color: rl.Color, txt_color: rl.Color, position: rl.Vector2, callback: ?*const fn () void, allocator: *std.mem.Allocator };

pub const Button = struct {
    font: rl.Font,
    font_size: i32,
    label: []const u8,
    bg_color: rl.Color,
    rect: rl.Rectangle,
    txt_color: rl.Color,
    padding: rl.Vector2,
    visible: bool = true,
    allocator: *std.mem.Allocator,
    callback: ?*const fn () void = null,
    cursor: rl.MouseCursor = rl.MouseCursor.default,

    pub fn deinit(self: *Button) void {
        _ = self;
    }

    pub fn draw(self: *Button) void {
        if (!self.visible) return;
        rl.drawRectangleRec(self.rect, self.bg_color);
        const label_z = sliceToZSlice(self.allocator, self.label) catch "Failed to convert label string to Z slice";
        defer self.allocator.free(label_z);
        rl.drawTextEx(self.font, label_z, .init(self.rect.x + self.padding.x, self.rect.y + self.padding.y), @as(f32, @floatFromInt(self.font_size)), 3, self.txt_color);
    }

    pub fn init(props: Props) Button {
        const label_z = sliceToZSlice(props.allocator, props.label) catch "Failed to convert label string to Z slice";
        defer props.allocator.free(label_z);
        const padding = rl.Vector2.init(10, 5);
        const label_width = @as(f32, @floatFromInt(rl.measureText(label_z, props.font_size)));
        const rect = rl.Rectangle.init(props.position.x, props.position.y, label_width + (2 * padding.x), @as(f32, @floatFromInt(props.font_size)) + (2 * padding.y));
        return Button{
            .rect = rect,
            .font = props.font,
            .padding = padding,
            .label = props.label,
            .bg_color = props.bg_color,
            .font_size = props.font_size,
            .txt_color = props.txt_color,
            .allocator = props.allocator,
            .callback = props.callback,
        };
    }

    fn onClick(self: *Button) void {
        if (self.callback) |cb| cb();
    }

    pub fn update(self: *Button) void {
        const mouse_pos = rl.getMousePosition();
        if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
            rl.setMouseCursor(rl.MouseCursor.pointing_hand);
            if (rl.isMouseButtonPressed(rl.MouseButton.left)) self.onClick();
        } else rl.setMouseCursor(rl.MouseCursor.default);
    }
};
