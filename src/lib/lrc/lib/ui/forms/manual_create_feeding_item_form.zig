const std = @import("std");
const rl = @import("raylib");
const ui_utils = @import("../utils.zig");
const core_utils = @import("../../../utils.zig");
const Button = @import("../buttons/root.zig").Button;
const Feeder = @import("../../baby_data/utils.zig").Feeder;
const DateTime = @import("../../date_time/root.zig").DateTime;
const BabyData = @import("../../baby_data/root.zig").BabyData;
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
    baby_data: *BabyData,
    draw_pos: rl.Vector2,
    color_set: ui_utils.ColorSet,
    allocator: *std.mem.Allocator,
};

pub const ManualCreateFeedingItemForm = struct {
    font: rl.Font,
    font_size: u32,
    baby_data: *BabyData,
    reset_button: Button,
    title: ui_utils.Title,
    date_input: TextInput,
    time_input: TextInput,
    submit_button: Button,
    notes_input: TextAreaInput,
    color_set: ui_utils.ColorSet,
    show_error_msg: bool = false,
    amount_ml_input: NumberInput,
    allocator: *std.mem.Allocator,
    show_success_msg: bool = false,
    duration_sec_input: NumberInput,
    feeder_select_input: SelectInput,
    feeding_type_select_input: SelectInput,

    // Base methods
    pub fn deinit(self: *ManualCreateFeedingItemForm) void {
        self.time_input.deinit();
        self.date_input.deinit();
        self.notes_input.deinit();
        self.reset_button.deinit();
        self.submit_button.deinit();
        self.amount_ml_input.deinit();
        self.duration_sec_input.deinit();
        self.feeder_select_input.deinit();
        self.feeding_type_select_input.deinit();
    }

    pub fn draw(self: *ManualCreateFeedingItemForm) void {
        self.drawTitle();
        if (self.show_success_msg) {
            self.drawSuccessMessage();
            self.reset_button.draw();
            return;
        }
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

    pub fn init(props: Props) ManualCreateFeedingItemForm {
        var draw_pos = props.draw_pos;
        const title = ui_utils.Title{ .pos = draw_pos, .font_size = props.font_size * 2, .text = "Feeding Item Form" };
        draw_pos.y += 3 * @as(f32, @floatFromInt(props.font_size));
        var reset_button_draw_pos = draw_pos;
        const date_input = getDateInput(props, draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + date_input.rect.height;
        const time_input = getTimeInput(props, draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + time_input.rect.height;
        const duration_sec_input = getDurationSecInput(props, draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + duration_sec_input.rect.height;
        const amount_ml_input = getAmountMlInput(props, draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + amount_ml_input.rect.height;
        const feeder_select_input = getFeederSelectInput(props, draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + amount_ml_input.rect.height;
        const feeding_type_select_input = getFeedingTypeSelectInput(props, draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + feeder_select_input.rect.height;
        const notes_input = getNotesInput(props, draw_pos);
        draw_pos.y += 2.5 * @as(f32, @floatFromInt(props.font_size)) + notes_input.rect.height;
        const submit_button = getSubmitButton(props, draw_pos);
        reset_button_draw_pos.y += 2 * @as(f32, @floatFromInt(props.font_size));
        const reset_button = getResetButton(props, reset_button_draw_pos);
        return ManualCreateFeedingItemForm{
            .title = title,
            .font = props.font,
            .font_size = props.font_size,
            .date_input = date_input,
            .time_input = time_input,
            .reset_button = reset_button,
            .color_set = props.color_set,
            .submit_button = submit_button,
            .baby_data = props.baby_data,
            .allocator = props.allocator,
            .notes_input = notes_input,
            .amount_ml_input = amount_ml_input,
            .duration_sec_input = duration_sec_input,
            .feeder_select_input = feeder_select_input,
            .feeding_type_select_input = feeding_type_select_input,
        };
    }

    pub fn update(self: *ManualCreateFeedingItemForm) void {
        self.updateTabFocus();
        self.date_input.update();
        self.time_input.update();
        self.notes_input.update();
        self.reset_button.update();
        self.submit_button.update();
        self.amount_ml_input.update();
        self.duration_sec_input.update();
        self.feeder_select_input.update();
        self.feeding_type_select_input.update();
    }

    // Helper methods
    pub fn bindCallbacks(self: *ManualCreateFeedingItemForm) void {
        self.reset_button.callback_context = self;
        self.submit_button.callback_context = self;
    }

    fn blurById(self: *ManualCreateFeedingItemForm, id: []const u8) void {
        if (std.mem.eql(u8, id, "date_input")) return self.date_input.blur();
        if (std.mem.eql(u8, id, "time_input")) return self.time_input.blur();
        if (std.mem.eql(u8, id, "notes_input")) return self.notes_input.blur();
        if (std.mem.eql(u8, id, "amount_ml_input")) return self.amount_ml_input.blur();
        if (std.mem.eql(u8, id, "duration_sec_input")) return self.duration_sec_input.blur();
        if (std.mem.eql(u8, id, "feeder_select_input")) return self.feeder_select_input.blur();
        if (std.mem.eql(u8, id, "feeding_type_select_input")) return self.feeding_type_select_input.blur();
    }

    fn drawErrorMessage(self: *ManualCreateFeedingItemForm) void {
        const draw_pos = rl.Vector2.init(self.submit_button.rect.x, self.submit_button.rect.y + self.submit_button.rect.height + @as(f32, @floatFromInt(self.font_size)));
        const msg = "An error occurred, please review your inputs and try again.";
        rl.drawTextEx(self.font, msg, draw_pos, @as(f32, @floatFromInt(self.font_size)), ui_utils.getCharSpacing(self.font_size), self.color_set.err);
    }

    fn drawTitle(self: *ManualCreateFeedingItemForm) void {
        const title_str = core_utils.sliceToZSlice(self.allocator, self.title.text) catch @panic("Failed to convert title text to Z slice");
        defer self.allocator.free(title_str);
        rl.drawTextEx(self.font, title_str, self.title.pos, @as(f32, @floatFromInt(self.title.font_size)), ui_utils.getCharSpacing(self.title.font_size), self.color_set.secondary);
    }

    fn drawSuccessMessage(self: *ManualCreateFeedingItemForm) void {
        const draw_pos = rl.Vector2.init(self.title.pos.x, self.title.pos.y + @as(f32, @floatFromInt(self.title.font_size)) + @as(f32, @floatFromInt(self.font_size)));
        const msg = "Feeding item added successfully!";
        rl.drawTextEx(self.font, msg, draw_pos, @as(f32, @floatFromInt(self.font_size)), ui_utils.getCharSpacing(self.font_size), self.color_set.secondary);
    }

    fn focusById(self: *ManualCreateFeedingItemForm, id: []const u8) void {
        if (std.mem.eql(u8, id, "date_input")) return self.date_input.focus();
        if (std.mem.eql(u8, id, "time_input")) return self.time_input.focus();
        if (std.mem.eql(u8, id, "duration_sec_input")) return self.duration_sec_input.focus();
        if (std.mem.eql(u8, id, "amount_ml_input")) return self.amount_ml_input.focus();
        if (std.mem.eql(u8, id, "feeder_select_input")) return self.feeder_select_input.focus();
        if (std.mem.eql(u8, id, "feeding_type_select_input")) return self.feeding_type_select_input.focus();
        if (std.mem.eql(u8, id, "notes_input")) return self.notes_input.focus();
    }

    fn getAmountMlInput(props: Props, draw_pos: rl.Vector2) NumberInput {
        return .init(.{ .min = 0, .width = 400, .initial_value = 0, .font = props.font, .draw_pos = draw_pos, .font_size = props.font_size, .label = "Amount (ml)", .id = "amount_ml_input", .allocator = props.allocator, .placeholder = "Enter amount...", .bg_color = props.color_set.primary, .txt_color = props.color_set.secondary, .border_color = props.color_set.secondary });
    }

    fn getDateInput(props: Props, draw_pos: rl.Vector2) TextInput {
        const initial_value = DateTime.now().addSeconds(60 * 60 * 2).toDateString(props.allocator) catch @panic("Failed to get current time string");
        defer props.allocator.free(initial_value);
        return .init(.{ .width = 400, .font = props.font, .id = "date_input", .draw_pos = draw_pos, .font_size = props.font_size, .allocator = props.allocator, .label = "Date (YYYY-MM-DD)", .placeholder = "Enter date...", .initial_value = initial_value, .bg_color = props.color_set.primary, .txt_color = props.color_set.secondary, .border_color = props.color_set.secondary });
    }

    fn getDurationSecInput(props: Props, draw_pos: rl.Vector2) NumberInput {
        return .init(.{ .min = 0, .width = 400, .initial_value = 0, .font = props.font, .draw_pos = draw_pos, .font_size = props.font_size, .id = "duration_sec_input", .allocator = props.allocator, .label = "Duration (seconds)", .bg_color = props.color_set.primary, .txt_color = props.color_set.secondary, .placeholder = "Enter duration...", .border_color = props.color_set.secondary });
    }

    fn getFeederSelectInput(props: Props, draw_pos: rl.Vector2) SelectInput {
        return .init(.{ .width = 400, .font = props.font, .draw_pos = draw_pos, .label = "Feeder", .font_size = props.font_size, .id = "feeder_select_input", .allocator = props.allocator, .bg_color = props.color_set.primary, .txt_color = props.color_set.secondary, .placeholder = "Select feeder...", .options = &feeder_options, .border_color = props.color_set.secondary });
    }

    fn getFeedingTypeSelectInput(props: Props, draw_pos: rl.Vector2) SelectInput {
        return .init(.{ .width = 400, .font = props.font, .draw_pos = draw_pos, .font_size = props.font_size, .label = "Feeding Type", .allocator = props.allocator, .bg_color = props.color_set.primary, .txt_color = props.color_set.secondary, .id = "feeding_type_select_input", .border_color = props.color_set.secondary, .placeholder = "Select feeding type...", .options = &feeding_type_options });
    }

    fn getNotesInput(props: Props, draw_pos: rl.Vector2) TextAreaInput {
        return .init(.{ .width = 400, .font = props.font, .label = "Notes", .draw_pos = draw_pos, .initial_value = "", .id = "notes_input", .font_size = props.font_size, .allocator = props.allocator, .bg_color = props.color_set.primary, .placeholder = "Enter notes...", .txt_color = props.color_set.secondary, .border_color = props.color_set.secondary });
    }

    fn getResetButton(props: Props, draw_pos: rl.Vector2) Button {
        return .init(.{ .font = props.font, .label = "Reset", .draw_pos = draw_pos, .id = "reset_button", .font_size = props.font_size, .allocator = props.allocator, .bg_color = props.color_set.primary, .txt_color = props.color_set.secondary, .border_color = props.color_set.secondary, .callback = resetButtonCallback });
    }

    fn getSubmitButton(props: Props, draw_pos: rl.Vector2) Button {
        return .init(.{ .font = props.font, .label = "Submit", .draw_pos = draw_pos, .id = "submit_button", .font_size = props.font_size, .allocator = props.allocator, .bg_color = props.color_set.primary, .txt_color = props.color_set.secondary, .border_color = props.color_set.secondary, .callback = submitButtonCallback });
    }

    fn getTitle(props: Props, draw_pos: rl.Vector2) ui_utils.Title {
        return .{ .font_size = props.font_size, .pos = draw_pos, .text = "Test Screen" };
    }

    fn getTimeInput(props: Props, draw_pos: rl.Vector2) TextInput {
        const initial_value = DateTime.now().addSeconds(60 * 60 * 2).toTimeString(props.allocator) catch @panic("Failed to get current time string");
        defer props.allocator.free(initial_value);
        return .init(.{ .width = 400, .font = props.font, .id = "time_input", .draw_pos = draw_pos, .font_size = props.font_size, .label = "Time (HH:MM:SS)", .allocator = props.allocator, .placeholder = "Enter time...", .initial_value = initial_value, .bg_color = props.color_set.primary, .txt_color = props.color_set.secondary, .border_color = props.color_set.secondary });
    }

    fn resetButtonCallback(context: ?*anyopaque) void {
        const self: *ManualCreateFeedingItemForm = @ptrCast(@alignCast(context.?));
        const date_time = DateTime.now().addSeconds(60 * 60 * 2);
        const date_str = date_time.toDateString(self.allocator) catch @panic("Failed to get current date string");
        defer self.allocator.free(date_str);
        const time_str = date_time.toTimeString(self.allocator) catch @panic("Failed to get current time string");
        defer self.allocator.free(time_str);
        self.show_error_msg = false;
        self.show_success_msg = false;
        self.notes_input.setValue("");
        self.amount_ml_input.setValue(0);
        self.date_input.setValue(date_str);
        self.time_input.setValue(time_str);
        self.duration_sec_input.setValue(0);
        self.feeder_select_input.active_index = 0;
        self.feeding_type_select_input.active_index = 0;
    }

    fn showErrorMessage(self: *ManualCreateFeedingItemForm) void {
        self.show_error_msg = true;
        self.show_success_msg = false;
    }

    fn showSuccessMessage(self: *ManualCreateFeedingItemForm) void {
        self.show_error_msg = false;
        self.show_success_msg = true;
    }

    fn submitButtonCallback(context: ?*anyopaque) void {
        var buffer: [64]u8 = undefined;
        const self: *ManualCreateFeedingItemForm = @ptrCast(@alignCast(context.?));
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
        self.baby_data.addFeedingItem(feeding_item, true);
        self.showSuccessMessage();
    }

    const tab_order = [_][]const u8{
        "date_input",
        "time_input",
        "duration_sec_input",
        "amount_ml_input",
        "feeder_select_input",
        "feeding_type_select_input",
        "notes_input",
    };

    fn updateTabFocus(self: *ManualCreateFeedingItemForm) void {
        if (!rl.isKeyPressed(.tab)) return;
        var current_index: ?usize = null;
        const shift_down = rl.isKeyDown(.left_shift) or rl.isKeyDown(.right_shift);
        if (ui_utils.focused_element) |focused_id| {
            for (tab_order, 0..) |id, i| {
                if (std.mem.eql(u8, id, focused_id)) {
                    current_index = i;
                    break;
                }
            }
        }
        var next_index: usize = 0;
        const last_index = tab_order.len - 1;
        if (current_index) |i| {
            if (shift_down) {
                if (i == 0) {
                    next_index = last_index;
                } else next_index = i - 1;
            } else {
                if (i != last_index) next_index = i + 1;
            }
        } else {
            if (shift_down) next_index = last_index;
        }
        if (current_index) |index| self.blurById(tab_order[index]);
        self.focusById(tab_order[next_index]);
    }
};
