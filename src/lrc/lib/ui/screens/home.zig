const std = @import("std");
const rl = @import("raylib");
const TextInput = @import("../inputs/text_input.zig").TextInput;

const Props = struct { font: rl.Font, allocator: *std.mem.Allocator, layout_rect: rl.Rectangle };

pub const HomeScreen = struct {
    font: rl.Font,
    font_size: f32,
    padding: rl.Vector2,
    text_input: TextInput,
    layout_rect: rl.Rectangle,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *HomeScreen) void {
        self.text_input.deinit();
    }

    pub fn draw(self: *HomeScreen, draw_position: *rl.Vector2) void {
        draw_position.x += self.padding.x;
        draw_position.y += self.padding.y;
        rl.drawTextEx(self.font, "Welcome to the Home Screen!", draw_position.*, self.font_size, @divFloor(self.font_size, 8), rl.Color.white);
        self.text_input.draw();
    }

    pub fn init(props: Props) HomeScreen {
        const font_size: f32 = 16;
        const padding_value = @divFloor(font_size, 2);
        const padding: rl.Vector2 = rl.Vector2.init(padding_value, padding_value);
        const text_input = TextInput.init(.{
            .width = 200,
            .font = props.font,
            .font_size = font_size,
            .initial_value = "",
            .bg_color = rl.Color.black,
            .txt_color = rl.Color.white,
            .border_color = rl.Color.green,
            .allocator = props.allocator,
            .placeholder = "Enter text...",
            .layout_rect = rl.Rectangle.init(props.layout_rect.x + padding.x, props.layout_rect.y + padding.y, props.layout_rect.width, props.layout_rect.height),
        });
        return HomeScreen{
            .font = props.font,
            .font_size = font_size,
            .padding = padding,
            .text_input = text_input,
            .allocator = props.allocator,
            .layout_rect = props.layout_rect,
        };
    }

    pub fn update(self: *HomeScreen) void {
        self.text_input.update();
    }
};
