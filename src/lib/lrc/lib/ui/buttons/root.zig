const std = @import("std");
const rl = @import("raylib");
const sliceToZSlice = @import("../../../utils.zig").sliceToZSlice;

const Props = struct {
    font: rl.Font,
    label: []const u8,
    bg_color: rl.Color,
    txt_color: rl.Color,
    font_size: u32 = 16,
    draw_pos: *rl.Vector2,
    allocator: *std.mem.Allocator,
    callback: ?*const fn () void = null,
};

pub const Button = struct {
    font: rl.Font,
    font_size: u32,
    label: []const u8,
    bg_color: rl.Color,
    rect: rl.Rectangle,
    txt_color: rl.Color,
    padding: rl.Vector2,
    visible: bool = true,
    callback: ?*const fn () void,
    allocator: *std.mem.Allocator,
    cursor: rl.MouseCursor = rl.MouseCursor.default,

    // Base methods
    pub fn deinit(self: *Button) void {
        _ = self;
    }

    pub fn draw(self: *Button) void {
        if (!self.visible) return;
        self.drawRectangle();
        self.drawText();
    }

    pub fn init(props: Props) Button {
        const font_size_f32 = @as(f32, @floatFromInt(props.font_size));
        const label_z = sliceToZSlice(props.allocator, props.label) catch @panic("Failed to convert label string to Z slice");
        defer props.allocator.free(label_z);
        const label_width = rl.measureTextEx(props.font, label_z, font_size_f32, 2.0).x;
        const padding = rl.Vector2.init(@divFloor(font_size_f32, 2), @divFloor(font_size_f32, 4));
        const rect = rl.Rectangle.init(props.draw_pos.x, props.draw_pos.y, label_width + (2 * padding.x), font_size_f32 + (2 * padding.y));
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

    pub fn update(self: *Button) void {
        const mouse_pos = rl.getMousePosition();
        if (rl.checkCollisionPointRec(mouse_pos, self.rect)) {
            rl.setMouseCursor(rl.MouseCursor.pointing_hand);
            if (rl.isMouseButtonPressed(rl.MouseButton.left)) self.onClick();
        } else rl.setMouseCursor(rl.MouseCursor.default);
    }

    // Helper methods
    fn drawRectangle(self: *Button) void {
        rl.drawRectangleRec(self.rect, self.bg_color);
    }

    fn drawText(self: *Button) void {
        const text = self.label;
        const text_z = sliceToZSlice(self.allocator, text) catch return;
        defer self.allocator.free(text_z);
        rl.drawTextEx(
            self.font,
            text_z,
            .init(self.rect.x + self.padding.x, self.rect.y + self.padding.y),
            @as(f32, @floatFromInt(self.font_size)),
            2.0,
            self.txt_color,
        );
    }

    fn onClick(self: *Button) void {
        if (self.callback) |cb| cb();
    }
};
