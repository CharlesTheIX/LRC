const std = @import("std");
const rl = @import("raylib");
const ui_utils = @import("../utils.zig");
const core_utils = @import("../../../utils.zig");
const Button = @import("../buttons/root.zig").Button;
const Feeder = @import("../../baby_data/utils.zig").Feeder;
const DateTime = @import("../../date_time/root.zig").DateTime;
const TextInput = @import("../inputs/text_input.zig").TextInput;
const FeedingType = @import("../../baby_data/utils.zig").FeedingType;
const FeedingItem = @import("../../baby_data/utils.zig").FeedingItem;
const NumberInput = @import("../inputs/number_input.zig").NumberInput;
const SelectInput = @import("../inputs/select_input.zig").SelectInput;
const TextAreaInput = @import("../inputs/text_area_input.zig").TextAreaInput;
const feeder_options = @import("../../baby_data/utils.zig").feeder_options;
const feeding_type_options = @import("../../baby_data/utils.zig").feeding_type_options;

const Props = struct {
    font: rl.Font,
    font_size: u32 = 16,
    color_set: ui_utils.ColorSet,
    allocator: *std.mem.Allocator,
};

pub const TestScreen = struct {
    font: rl.Font,
    font_size: u32,
    title: ui_utils.Title,
    date_input: TextInput,
    time_input: TextInput,
    submit_button: Button,
    notes_input: TextAreaInput,
    color_set: ui_utils.ColorSet,
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
        self.drawBackground();
        self.drawTitle();
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
        const title = ui_utils.Title{ .pos = draw_pos, .font_size = props.font_size * 2, .text = "Feeding Item Form" };
        draw_pos.y += 3 * @as(f32, @floatFromInt(props.font_size));
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
            .title = title,
            .font = props.font,
            .font_size = props.font_size,
            .date_input = date_input,
            .time_input = time_input,
            .color_set = props.color_set,
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

    fn drawBackground(self: *TestScreen) void {
        const rect = rl.Rectangle.init(0, 0, @as(f32, @floatFromInt(rl.getScreenWidth())), @as(f32, @floatFromInt(rl.getScreenHeight())));
        rl.drawRectangleRec(rect, self.color_set.primary);
    }

    fn drawErrorMessage(self: *TestScreen) void {
        const draw_pos = rl.Vector2.init(self.submit_button.rect.x, self.submit_button.rect.y + self.submit_button.rect.height + @as(f32, @floatFromInt(self.font_size)));
        const error_msg = "An error occurred, please review your inputs and try again.";
        rl.drawTextEx(self.font, error_msg, draw_pos, @as(f32, @floatFromInt(self.font_size)), ui_utils.getCharSpacing(self.font_size), self.color_set.err);
    }

    fn drawTitle(self: *TestScreen) void {
        const title_str = core_utils.sliceToZSlice(self.allocator, self.title.text) catch @panic("Failed to convert title text to Z slice");
        defer self.allocator.free(title_str);
        rl.drawTextEx(self.font, title_str, self.title.pos, @as(f32, @floatFromInt(self.title.font_size)), ui_utils.getCharSpacing(self.title.font_size), self.color_set.secondary);
    }

    fn getAmountMlInput(props: Props, draw_pos: *rl.Vector2) NumberInput {
        return .init(.{
            .min = 0,
            .width = 400,
            .initial_value = 0,
            .font = props.font,
            .draw_pos = draw_pos,
            .font_size = props.font_size,
            .label = "Amount (ml)",
            .id = "amount_ml_input",
            .allocator = props.allocator,
            .placeholder = "Enter amount...",
            .bg_color = props.color_set.primary,
            .txt_color = props.color_set.secondary,
            .border_color = props.color_set.highlight,
        });
    }

    fn getDateInput(props: Props, draw_pos: *rl.Vector2) TextInput {
        return .init(.{
            .width = 400,
            .font = props.font,
            .id = "date_input",
            .draw_pos = draw_pos,
            .initial_value = "",
            .font_size = props.font_size,
            .allocator = props.allocator,
            .label = "Date (YYYY-MM-DD)",
            .placeholder = "Enter date...",
            .bg_color = props.color_set.primary,
            .txt_color = props.color_set.secondary,
            .border_color = props.color_set.highlight,
        });
    }

    fn getDurationSecInput(props: Props, draw_pos: *rl.Vector2) NumberInput {
        return .init(.{
            .min = 0,
            .width = 400,
            .initial_value = 0,
            .font = props.font,
            .draw_pos = draw_pos,
            .font_size = props.font_size,
            .id = "duration_sec_input",
            .allocator = props.allocator,
            .label = "Duration (seconds)",
            .bg_color = props.color_set.primary,
            .txt_color = props.color_set.secondary,
            .placeholder = "Enter duration...",
            .border_color = props.color_set.highlight,
        });
    }

    fn getFeederSelectInput(props: Props, draw_pos: *rl.Vector2) SelectInput {
        return .init(.{
            .width = 400,
            .font = props.font,
            .draw_pos = draw_pos,
            .label = "Feeder",
            .font_size = props.font_size,
            .id = "feeder_select_input",
            .allocator = props.allocator,
            .bg_color = props.color_set.primary,
            .txt_color = props.color_set.secondary,
            .placeholder = "Select feeder...",
            .options = &feeder_options,
            .border_color = props.color_set.highlight,
        });
    }

    fn getFeedingTypeSelectInput(props: Props, draw_pos: *rl.Vector2) SelectInput {
        return .init(.{
            .width = 400,
            .font = props.font,
            .draw_pos = draw_pos,
            .font_size = props.font_size,
            .label = "Feeding Type",
            .allocator = props.allocator,
            .bg_color = props.color_set.primary,
            .txt_color = props.color_set.secondary,
            .id = "feeding_type_select_input",
            .border_color = props.color_set.highlight,
            .placeholder = "Select feeding type...",
            .options = &feeding_type_options,
        });
    }

    fn getNotesInput(props: Props, draw_pos: *rl.Vector2) TextAreaInput {
        return .init(.{
            .width = 400,
            .font = props.font,
            .label = "Notes",
            .draw_pos = draw_pos,
            .initial_value = "",
            .id = "notes_input",
            .font_size = props.font_size,
            .allocator = props.allocator,
            .bg_color = props.color_set.primary,
            .placeholder = "Enter notes...",
            .txt_color = props.color_set.secondary,
            .border_color = props.color_set.highlight,
        });
    }

    fn getSubmitButton(props: Props, draw_pos: *rl.Vector2) Button {
        return .init(.{
            .font = props.font,
            .label = "Submit",
            .draw_pos = draw_pos,
            .id = "submit_button",
            .font_size = props.font_size,
            .allocator = props.allocator,
            .bg_color = props.color_set.primary,
            .txt_color = props.color_set.secondary,
            .border_color = props.color_set.highlight,
            .callback = submitButtonCallback,
        });
    }

    fn getTitle(props: Props, draw_pos: *rl.Vector2) ui_utils.Title {
        return .{ .font_size = props.font_size, .pos = draw_pos.*, .text = "Test Screen" };
    }

    fn getTimeInput(props: Props, draw_pos: *rl.Vector2) TextInput {
        return .init(.{
            .width = 400,
            .font = props.font,
            .id = "time_input",
            .draw_pos = draw_pos,
            .initial_value = "",
            .font_size = props.font_size,
            .label = "Time (HH:MM:SS)",
            .allocator = props.allocator,
            .placeholder = "Enter time...",
            .bg_color = props.color_set.primary,
            .txt_color = props.color_set.secondary,
            .border_color = props.color_set.highlight,
        });
    }

    fn showErrorMessage(self: *TestScreen) void {
        self.show_error_msg = true;
    }

    fn submitButtonCallback(context: ?*anyopaque) void {
        var buffer: [64]u8 = undefined;
        const self: *TestScreen = @ptrCast(@alignCast(context.?));
        self.show_error_msg = false;
        const feeder = Feeder.fromSlice(self.feeder_select_input.getValue());
        const feeding_type = FeedingType.fromSlice(self.feeding_type_select_input.getValue());
        const date_time_str = std.fmt.bufPrint(&buffer, "{s}T{s}", .{ self.date_input.getValue(), self.time_input.getValue() }) catch @panic("Failed to format date and time");
        const date_time = DateTime.initFromIsoString(date_time_str) catch return self.showErrorMessage();
        if (feeder == .Invalid) return self.showErrorMessage();
        if (feeding_type == .Invalid) return self.showErrorMessage();
        const feeding_item = FeedingItem{
            .feeder = feeder,
            .date_time = date_time,
            .feeding_type = feeding_type,
            .amount_ml = @as(u32, @intFromFloat(self.amount_ml_input.getValue())),
            .duration_sec = @as(u32, @intFromFloat(self.duration_sec_input.getValue())),
            .notes = if (self.notes_input.getValue().len == 0) null else self.notes_input.getValue(),
        };
        std.debug.print("Feeding Item {any}\n", .{feeding_item});
    }
};
