const std = @import("std");
const rl = @import("raylib");
const ui_utils = @import("../utils.zig");
const Button = @import("../buttons/root.zig").Button;
const Feeder = @import("../../baby_data/utils.zig").Feeder;
const TextInput = @import("../inputs/text_input.zig").TextInput;
const FeedingType = @import("../../baby_data/utils.zig").FeedingType;
const NumberInput = @import("../inputs/number_input.zig").NumberInput;
const SelectInput = @import("../inputs/select_input.zig").SelectInput;
const TextAreaInput = @import("../inputs/text_area_input.zig").TextAreaInput;

const Props = struct {
    font: rl.Font,
    font_size: u32 = 16,
    allocator: *std.mem.Allocator,
};

pub const TestScreen = struct {
    font: rl.Font,
    font_size: u32,
    date_input: TextInput,
    time_input: TextInput,
    submit_button: Button,
    notes_input: TextAreaInput,
    show_error_msg: bool = false,
    amount_ml_input: NumberInput,
    allocator: *std.mem.Allocator,
    duration_sec_input: NumberInput,
    feeder_select_input: SelectInput,
    feeding_type_select_input: SelectInput,

    // Base methods
    pub fn deinit(self: *TestScreen) void {
        self.time_input.deinit();
        self.date_input.deinit();
        self.notes_input.deinit();
        self.submit_button.deinit();
        self.amount_ml_input.deinit();
        self.duration_sec_input.deinit();
        self.feeder_select_input.deinit();
        self.feeding_type_select_input.deinit();
    }

    pub fn draw(self: *TestScreen) void {
        if (self.show_error_msg) self.drawErrorMessage();
        self.submit_button.draw();
        self.notes_input.draw();
        self.feeding_type_select_input.draw();
        self.feeder_select_input.draw();
        self.duration_sec_input.draw();
        self.amount_ml_input.draw();
        self.time_input.draw();
        self.date_input.draw();
    }

    pub fn init(props: Props) TestScreen {
        var draw_pos = rl.Vector2.init(@as(f32, @floatFromInt(props.font_size)), @as(f32, @floatFromInt(props.font_size))).scale(2.0);
        const date_input = getDateInput(props, &draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + date_input.rect.height;
        const time_input = getTimeInput(props, &draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + time_input.rect.height;
        const duration_sec_input = getDurationSecInput(props, &draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + duration_sec_input.rect.height;
        const amount_ml_input = getAmountMlInput(props, &draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + amount_ml_input.rect.height;
        const feeder_select_input = getFeederSelectInput(props, &draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + amount_ml_input.rect.height;
        const feeding_type_select_input = getFeedingTypeSelectInput(props, &draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + feeder_select_input.rect.height;
        const notes_input = getNotesInput(props, &draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + notes_input.rect.height;
        const submit_button = getSubmitButton(props, &draw_pos);
        return TestScreen{
            .font = props.font,
            .font_size = props.font_size,
            .date_input = date_input,
            .time_input = time_input,
            .submit_button = submit_button,
            .allocator = props.allocator,
            .notes_input = notes_input,
            .amount_ml_input = amount_ml_input,
            .duration_sec_input = duration_sec_input,
            .feeder_select_input = feeder_select_input,
            .feeding_type_select_input = feeding_type_select_input,
        };
    }

    pub fn update(self: *TestScreen) void {
        self.date_input.update();
        self.time_input.update();
        self.notes_input.update();
        self.submit_button.update();
        self.amount_ml_input.update();
        self.duration_sec_input.update();
        self.feeder_select_input.update();
        self.feeding_type_select_input.update();
    }

    // Helper methods
    // Must be called once the TestScreen is at its final address so the button's callback context stays valid (Zig has no bound-method closures).
    pub fn bindCallbacks(self: *TestScreen) void {
        self.submit_button.callback_context = self;
    }

    fn drawErrorMessage(self: *TestScreen) void {
        const draw_pos = rl.Vector2.init(self.submit_button.rect.x, self.submit_button.rect.y + self.submit_button.rect.height + @as(f32, @floatFromInt(self.font_size)));
        const error_msg = "An error occurred, please review your inputs and try again.";
        rl.drawTextEx(self.font, error_msg, draw_pos, @as(f32, @floatFromInt(self.font_size)), ui_utils.getCharSpacing(self.font_size), rl.Color.red);
    }

    fn getAmountMlInput(props: Props, draw_pos: *rl.Vector2) NumberInput {
        return .init(.{ .width = 200, .initial_value = 0, .font = props.font, .draw_pos = draw_pos, .bg_color = rl.Color.black, .font_size = props.font_size, .id = "amount_ml_input", .txt_color = rl.Color.white, .border_color = rl.Color.green, .allocator = props.allocator, .label = "Amount (ml)", .placeholder = "Enter amount..." });
    }

    fn getDateInput(props: Props, draw_pos: *rl.Vector2) TextInput {
        return .init(.{ .id = "date_input", .width = 200, .font = props.font, .draw_pos = draw_pos, .initial_value = "", .font_size = props.font_size, .bg_color = rl.Color.black, .txt_color = rl.Color.white, .border_color = rl.Color.green, .allocator = props.allocator, .label = "Date (YYYY-MM-DD)", .placeholder = "Enter date..." });
    }

    fn getDurationSecInput(props: Props, draw_pos: *rl.Vector2) NumberInput {
        return .init(.{ .width = 200, .initial_value = 0, .font = props.font, .draw_pos = draw_pos, .bg_color = rl.Color.black, .font_size = props.font_size, .id = "duration_sec_input", .txt_color = rl.Color.white, .border_color = rl.Color.green, .allocator = props.allocator, .label = "Duration (seconds)", .placeholder = "Enter duration..." });
    }

    fn getFeederSelectInput(props: Props, draw_pos: *rl.Vector2) SelectInput {
        return SelectInput.init(.{
            .width = 200,
            .font = props.font,
            .draw_pos = draw_pos,
            .label = "Feeder",
            .bg_color = rl.Color.black,
            .font_size = props.font_size,
            .txt_color = rl.Color.white,
            .border_color = rl.Color.green,
            .id = "feeder_select_input",
            .allocator = props.allocator,
            .placeholder = "Select feeder...",
            .options = &[3][]const u8{
                Feeder.David.toSlice(),
                Feeder.Pavla.toSlice(),
                Feeder.Other.toSlice(),
            },
        });
    }

    fn getFeedingTypeSelectInput(props: Props, draw_pos: *rl.Vector2) SelectInput {
        return SelectInput.init(.{ .width = 200, .font = props.font, .draw_pos = draw_pos, .bg_color = rl.Color.black, .font_size = props.font_size, .txt_color = rl.Color.white, .label = "Feeding Type", .border_color = rl.Color.green, .allocator = props.allocator, .id = "feeding_type_select_input", .placeholder = "Select feeding type...", .options = &[_][]const u8{ FeedingType.Breast.toSlice(), FeedingType.BreastAndFormula.toSlice(), FeedingType.Formula.toSlice() } });
    }

    fn getNotesInput(props: Props, draw_pos: *rl.Vector2) TextAreaInput {
        return .init(.{ .width = 400, .font = props.font, .label = "Notes", .draw_pos = draw_pos, .initial_value = "", .id = "notes_input", .font_size = props.font_size, .bg_color = rl.Color.black, .txt_color = rl.Color.white, .border_color = rl.Color.green, .allocator = props.allocator, .placeholder = "Enter notes..." });
    }

    fn getSubmitButton(props: Props, draw_pos: *rl.Vector2) Button {
        return Button.init(.{ .id = "submit_button", .font = props.font, .label = "Submit", .draw_pos = draw_pos, .bg_color = rl.Color.black, .font_size = props.font_size, .txt_color = rl.Color.white, .callback = submitButtonCallback, .border_color = rl.Color.green, .allocator = props.allocator });
    }

    fn getTimeInput(props: Props, draw_pos: *rl.Vector2) TextInput {
        return .init(.{ .id = "time_input", .width = 200, .font = props.font, .initial_value = "", .draw_pos = draw_pos, .bg_color = rl.Color.black, .label = "Time (HH:MM:SS)", .txt_color = rl.Color.white, .font_size = props.font_size, .allocator = props.allocator, .border_color = rl.Color.green, .placeholder = "Enter time..." });
    }

    fn submitButtonCallback(context: ?*anyopaque) void {
        const self: *TestScreen = @ptrCast(@alignCast(context.?));
        const date = self.date_input.getValue();
        const time = self.time_input.getValue();
        const duration_sec = self.duration_sec_input.getValue();
        const duration_sec_text = self.duration_sec_input.getValueText();
        const amount_ml = self.amount_ml_input.getValue();
        const amount_ml_text = self.amount_ml_input.getValueText();
        const feeder = self.feeder_select_input.getValue();
        const feeding_type = self.feeding_type_select_input.getValue();
        const notes = self.notes_input.getValue();
        std.debug.print(
            "date: {s}, time: {s}, duration: {d}s, duration_text: {s} seconds, amount: {d}ml, amount_text: {s}, feeder: {s}, feeding_type: {s}, notes: {s}\n",
            .{ date, time, duration_sec, duration_sec_text, amount_ml, amount_ml_text, feeder, feeding_type, notes },
        );
    }
};
