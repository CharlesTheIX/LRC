const std = @import("std");
const rl = @import("raylib");
const Button = @import("../buttons/root.zig").Button;
const TextInput = @import("../inputs/text_input.zig").TextInput;
const NumberInput = @import("../inputs/number_input.zig").NumberInput;

const Props = struct { font: rl.Font, allocator: *std.mem.Allocator, font_size: u32 = 16 };

pub const TestScreen = struct {
    font: rl.Font,
    font_size: u32,
    date_input: TextInput,
    time_input: TextInput,
    submit_button: Button,
    duration_input: NumberInput,
    show_error_msg: bool = false,
    allocator: *std.mem.Allocator,

    // Base methods
    pub fn deinit(self: *TestScreen) void {
        self.date_input.deinit();
        self.time_input.deinit();
        self.submit_button.deinit();
        self.duration_input.deinit();
    }

    pub fn draw(self: *TestScreen) void {
        self.date_input.draw();
        self.time_input.draw();
        self.duration_input.draw();
        self.submit_button.draw();
        if (self.show_error_msg) {
            var draw_pos = rl.Vector2.init(self.submit_button.rect.x, self.submit_button.rect.y + self.submit_button.rect.height + @as(f32, @floatFromInt(self.font_size)));
            self.drawErrorMessage(&draw_pos);
        }
    }

    pub fn init(props: Props) TestScreen {
        var draw_pos = rl.Vector2.init(@as(f32, @floatFromInt(props.font_size)), @as(f32, @floatFromInt(props.font_size))).scale(2.0);
        const date_input = getDateInput(props, &draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + date_input.rect.height;
        const time_input = getTimeInput(props, &draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + time_input.rect.height;
        const duration_input = getDurationInput(props, &draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + time_input.rect.height;
        const submit_button = getSubmitButton(props, &draw_pos);
        return TestScreen{
            .font = props.font,
            .font_size = props.font_size,
            .date_input = date_input,
            .time_input = time_input,
            .submit_button = submit_button,
            .allocator = props.allocator,
            .duration_input = duration_input,
        };
    }

    pub fn update(self: *TestScreen) void {
        self.date_input.update();
        self.time_input.update();
        self.submit_button.update();
        self.duration_input.update();
    }

    // Helper methods
    // Must be called once the TestScreen is at its final address so the button's callback context stays valid (Zig has no bound-method closures).
    pub fn bindCallbacks(self: *TestScreen) void {
        self.submit_button.callback_context = self;
    }

    fn drawErrorMessage(self: *TestScreen, draw_pos: *rl.Vector2) void {
        _ = self;
        _ = draw_pos;
    }

    fn getDateInput(props: Props, draw_pos: *rl.Vector2) TextInput {
        return .init(.{ .id = "date_input", .width = 200, .font = props.font, .draw_pos = draw_pos, .initial_value = "", .font_size = props.font_size, .bg_color = rl.Color.black, .txt_color = rl.Color.white, .border_color = rl.Color.green, .allocator = props.allocator, .label = "Date (YYYY-MM-DD)", .placeholder = "Enter date..." });
    }

    fn getDurationInput(props: Props, draw_pos: *rl.Vector2) NumberInput {
        return .init(.{ .width = 200, .initial_value = 0, .font = props.font, .draw_pos = draw_pos, .bg_color = rl.Color.black, .font_size = props.font_size, .id = "duration_input", .txt_color = rl.Color.white, .border_color = rl.Color.green, .allocator = props.allocator, .label = "Duration (seconds)", .placeholder = "Enter duration..." });
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
        const duration = self.duration_input.getValue();
        const duration_text = self.duration_input.getValueText();
        std.debug.print("date: {s}, time: {s}, duration: {d}, duration_text: {s}\n", .{ date, time, duration, duration_text });
    }
};
