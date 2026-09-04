const std = @import("std");
const rl = @import("raylib");

// const TextInput = @import("../inputs/text_input.zig").TextInput;
// const NumberInput = @import("../inputs/number_input.zig").NumberInput;
// const SelectInput = @import("../inputs/select_input.zig").SelectInput;
const AddBodyItemForm = @import("../forms/baby_data_forms/add_body_item_form.zig").AddBodyItemForm;

const Props = struct { font: rl.Font, allocator: *std.mem.Allocator, layout_rect: rl.Rectangle };

pub const HomeScreen = struct {
    font: rl.Font,
    font_size: f32,
    padding: rl.Vector2,
    layout_rect: rl.Rectangle,
    allocator: *std.mem.Allocator,
    add_body_item_form: AddBodyItemForm,

    // text_input: TextInput,
    // number_input: NumberInput,

    pub fn deinit(self: *HomeScreen) void {
        // self.text_input.deinit();
        // self.number_input.deinit();
        self.add_body_item_form.deinit();
    }

    pub fn draw(self: *HomeScreen, draw_position: *rl.Vector2) void {
        _ = draw_position;
        self.add_body_item_form.draw();
        // self.text_input.draw();
        // self.number_input.draw();
    }

    pub fn init(props: Props) HomeScreen {
        const font_size: f32 = 16;
        const padding_value = @divFloor(font_size, 2);
        var padding: rl.Vector2 = rl.Vector2.init(padding_value, padding_value);
        // const text_input = TextInput.init(.{ .width = 200, .font = props.font, .initial_value = "", .font_size = font_size, .bg_color = rl.Color.black, .txt_color = rl.Color.white, .allocator = props.allocator, .border_color = rl.Color.green, .placeholder = "Enter text...", .layout_rect = rl.Rectangle.init(props.layout_rect.x + padding.x, props.layout_rect.y + padding.y, props.layout_rect.width, props.layout_rect.height) });
        // padding.y += font_size + padding_value + padding_value;
        // const number_input = NumberInput.init(.{ .min = 0, .step = 1, .max = 100, .width = 200, .initial_value = 0, .font = props.font, .allow_float = true, .font_size = font_size, .bg_color = rl.Color.black, .txt_color = rl.Color.white, .border_color = rl.Color.green, .allocator = props.allocator, .placeholder = "Enter a number...", .layout_rect = rl.Rectangle.init(props.layout_rect.x + padding.x, props.layout_rect.y + padding.y, props.layout_rect.width, props.layout_rect.height) });
        return HomeScreen{
            .font = props.font,
            .font_size = font_size,
            .padding = padding,
            .allocator = props.allocator,
            .layout_rect = props.layout_rect,
            .add_body_item_form = AddBodyItemForm.init(.{
                .font = props.font,
                .font_size = font_size,
                .draw_position = &padding,
                .allocator = props.allocator,
            }),

            // .text_input = text_input,
            // .number_input = number_input,
        };
    }

    pub fn update(self: *HomeScreen) void {
        self.add_body_item_form.update();
        // self.text_input.update();
        // self.number_input.update();
    }
};
