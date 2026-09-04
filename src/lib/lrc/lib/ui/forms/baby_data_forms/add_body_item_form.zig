const std = @import("std");
const rl = @import("raylib");
const DateTime = @import("../../../date_time/root.zig").DateTime;
const TextInput = @import("../../inputs/text_input.zig").TextInput;
const NumberInput = @import("../../inputs/number_input.zig").NumberInput;
const TextAreaInput = @import("../../inputs/text_area_input.zig").TextAreaInput;

const Props = struct {
    font: rl.Font,
    font_size: i32 = 16,
    draw_position: *rl.Vector2,
    allocator: *std.mem.Allocator,
};

pub const AddBodyItemForm = struct {
    weight_kg: ?f32 = null,
    urinations: ?u32 = null,
    defecations: ?u32 = null,
    notes: ?[]const u8 = null,
    date_time: ?DateTime = null,

    notes_input: TextAreaInput,
    weight_kg_input: NumberInput,
    urinations_input: NumberInput,
    defecations_input: NumberInput,
    date_time_date_input: TextInput,
    date_time_time_input: TextInput,

    pub fn deinit(self: *AddBodyItemForm) void {
        self.notes_input.deinit();
        self.weight_kg_input.deinit();
        self.urinations_input.deinit();
        self.defecations_input.deinit();
        self.date_time_date_input.deinit();
        self.date_time_time_input.deinit();
    }
    pub fn draw(self: *AddBodyItemForm) void {
        self.notes_input.draw();
        self.weight_kg_input.draw();
        self.urinations_input.draw();
        self.defecations_input.draw();
        self.date_time_date_input.draw();
        self.date_time_time_input.draw();
    }

    pub fn init(props: Props) AddBodyItemForm {
        var layout_rect = rl.Rectangle{ .x = props.draw_position.x, .y = props.draw_position.y, .width = @as(f32, @floatFromInt(rl.getScreenWidth())), .height = @as(f32, @floatFromInt(rl.getScreenHeight())) };
        const date_time_date_input = TextInput.init(.{ .width = 200.0, .font = props.font, .initial_value = "", .bg_color = rl.Color.black, .font_size = props.font_size, .txt_color = rl.Color.white, .border_color = rl.Color.green, .layout_rect = layout_rect, .allocator = props.allocator, .placeholder = "Enter date (YYYY-MM-DD)" });
        layout_rect.y += 50.0;
        const date_time_time_input = TextInput.init(.{ .width = 200.0, .font = props.font, .initial_value = "", .bg_color = rl.Color.black, .font_size = props.font_size, .txt_color = rl.Color.white, .border_color = rl.Color.green, .layout_rect = layout_rect, .allocator = props.allocator, .placeholder = "Enter time (HH:MM:SS)" });
        layout_rect.y += 50.0;
        const notes_input = TextAreaInput.init(.{ .font = props.font, .width = 200.0, .bg_color = rl.Color.black, .layout_rect = layout_rect, .txt_color = rl.Color.white, .border_color = rl.Color.green, .initial_value = "", .font_size = props.font_size, .height = @as(f32, @floatFromInt(props.font_size)) * 2.0, .placeholder = "Enter notes", .allocator = props.allocator });
        layout_rect.y += 50.0;
        const weight_kg_input = NumberInput.init(.{ .min = 0.0, .max = 100.0, .step = 0.001, .width = 200.0, .font = props.font, .allow_float = true, .initial_value = 0.0, .bg_color = rl.Color.black, .font_size = props.font_size, .txt_color = rl.Color.white, .border_color = rl.Color.green, .layout_rect = layout_rect, .allocator = props.allocator, .placeholder = "Enter weight in kg" });
        layout_rect.y += 50.0;
        const urinations_input = NumberInput.init(.{ .min = 0.0, .max = 100.0, .step = 1.0, .width = 200.0, .font = props.font, .allow_float = false, .initial_value = 0.0, .bg_color = rl.Color.black, .font_size = props.font_size, .txt_color = rl.Color.white, .border_color = rl.Color.green, .layout_rect = layout_rect, .allocator = props.allocator, .placeholder = "Enter number of urinations" });
        layout_rect.y += 50.0;
        const defecations_input = NumberInput.init(.{ .min = 0.0, .max = 100.0, .step = 1.0, .width = 200.0, .font = props.font, .allow_float = false, .initial_value = 0.0, .bg_color = rl.Color.black, .font_size = props.font_size, .txt_color = rl.Color.white, .border_color = rl.Color.green, .layout_rect = layout_rect, .allocator = props.allocator, .placeholder = "Enter number of defecations" });
        return .{ .notes_input = notes_input, .weight_kg_input = weight_kg_input, .urinations_input = urinations_input, .defecations_input = defecations_input, .date_time_date_input = date_time_date_input, .date_time_time_input = date_time_time_input };
    }

    pub fn update(self: *AddBodyItemForm) void {
        self.notes_input.update();
        self.weight_kg_input.update();
        self.urinations_input.update();
        self.defecations_input.update();
        self.date_time_date_input.update();
        self.date_time_time_input.update();
    }
};
