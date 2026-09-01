const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const Button = @import("../button.zig").Button;
const feeding_utils = @import("../../feeding/utils.zig");
const Feeding = @import("../../feeding/root.zig").Feeding;
const Dropdown = @import("../inputs/dropdown.zig").Dropdown;
const DateTime = @import("../../date_time/root.zig").DateTime;
const TextInput = @import("../inputs/text_input.zig").TextInput;
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

const Props = struct { font: rl.Font, position: rl.Vector2, feeding: *Feeding, allocator: *std.mem.Allocator, layout_rect: rl.Rectangle };

/// Records a feeding that already happened, with manually entered date, time and duration.
pub const HistoricFeedingForm = struct {
    font: rl.Font,
    feeding: *Feeding,
    date_input: TextInput,
    time_input: TextInput,
    duration_input: TextInput,
    notes_input: TextInput,
    submit_button: Button,
    status: []const u8 = "",
    feeder_dropdown: Dropdown,
    allocator: *std.mem.Allocator,
    feeding_type_dropdown: Dropdown,
    layout_rect: rl.Rectangle,

    pub fn deinit(self: *HistoricFeedingForm) void {
        self.date_input.deinit();
        self.time_input.deinit();
        self.duration_input.deinit();
        self.notes_input.deinit();
        self.submit_button.deinit();
        self.feeder_dropdown.deinit();
        self.feeding_type_dropdown.deinit();
    }

    pub fn draw(self: *HistoricFeedingForm) void {
        self.date_input.draw();
        self.time_input.draw();
        self.duration_input.draw();
        self.notes_input.draw();
        self.feeder_dropdown.draw();
        self.feeding_type_dropdown.draw();
        self.submit_button.draw();
        if (self.status.len == 0) return;
        const status_z = sliceToZSlice(self.allocator, self.status) catch return;
        defer self.allocator.free(status_z);
        rl.drawTextEx(self.font, status_z, .init(self.submit_button.rect.x + self.submit_button.rect.width + 10, self.submit_button.rect.y + 6), 16, 2.0, rl.Color.dark_gray);
    }

    pub fn init(props: Props) HistoricFeedingForm {
        const spacing: f32 = 40;
        var pos = props.position;
        const field_width: f32 = 200;
        const now = DateTime.now();
        const date = now.toDateString(props.allocator) catch "";
        defer props.allocator.free(date);
        const time = now.toTimeString(props.allocator) catch "";
        defer props.allocator.free(time);
        const date_input = TextInput.init(.{ .font = props.font, .font_size = 16, .width = field_width, .bg_color = rl.Color.white, .txt_color = rl.Color.black, .border_color = rl.Color.gray, .placeholder = "Date (YYYY-MM-DD)", .initial_value = date, .allocator = props.allocator, .layout_rect = rl.Rectangle.init(pos.x, pos.y, field_width, 0) });
        pos.y += spacing;
        const time_input = TextInput.init(.{ .font = props.font, .font_size = 16, .width = field_width, .bg_color = rl.Color.white, .txt_color = rl.Color.black, .border_color = rl.Color.gray, .placeholder = "Time (HH:MM:SS)", .initial_value = time, .allocator = props.allocator, .layout_rect = rl.Rectangle.init(pos.x, pos.y, field_width, 0) });
        pos.y += spacing;
        const duration_input = TextInput.init(.{ .font = props.font, .font_size = 16, .width = field_width, .bg_color = rl.Color.white, .txt_color = rl.Color.black, .border_color = rl.Color.gray, .placeholder = "Duration (minutes)", .allocator = props.allocator, .layout_rect = rl.Rectangle.init(pos.x, pos.y, field_width, 0) });
        pos.y += spacing;
        const notes_input = TextInput.init(.{ .font = props.font, .font_size = 16, .width = field_width, .bg_color = rl.Color.white, .txt_color = rl.Color.black, .border_color = rl.Color.gray, .placeholder = "Notes", .allocator = props.allocator, .layout_rect = rl.Rectangle.init(pos.x, pos.y, field_width, 0) });
        pos.y += spacing;
        const feeding_type_dropdown = Dropdown.init(.{
            .font_size = 16,
            .position = pos,
            .font = props.font,
            .bg_color = rl.Color.white,
            .txt_color = rl.Color.black,
            .border_color = rl.Color.gray,
            .allocator = props.allocator,
            .highlight_color = rl.Color.sky_blue,
            .options = &utils.feeding_type_options,
        });
        pos.y += spacing;
        const feeder_dropdown = Dropdown.init(.{
            .font_size = 16,
            .position = pos,
            .font = props.font,
            .bg_color = rl.Color.white,
            .txt_color = rl.Color.black,
            .border_color = rl.Color.gray,
            .allocator = props.allocator,
            .highlight_color = rl.Color.sky_blue,
            .options = &utils.feeder_options,
        });
        pos.y += spacing;
        const submit_button = Button.init(.{
            .font_size = 16,
            .position = pos,
            .font = props.font,
            .bg_color = rl.Color.blue,
            .label = "Add Historic Feeding",
            .txt_color = rl.Color.white,
            .callback = null,
            .allocator = props.allocator,
        });

        return HistoricFeedingForm{
            .font = props.font,
            .feeding = props.feeding,
            .date_input = date_input,
            .time_input = time_input,
            .duration_input = duration_input,
            .notes_input = notes_input,
            .submit_button = submit_button,
            .allocator = props.allocator,
            .feeder_dropdown = feeder_dropdown,
            .feeding_type_dropdown = feeding_type_dropdown,
            .layout_rect = props.layout_rect,
        };
    }

    /// Validates the current form values and delegates to `Feeding.addFeedingItem`.
    fn submit(self: *HistoricFeedingForm) void {
        if (self.date_input.value().len == 0 or self.time_input.value().len == 0) {
            self.status = "Date and time are required";
            return;
        }
        const duration = std.fmt.parseInt(u6, self.duration_input.value(), 10) catch {
            self.status = "Invalid duration";
            return;
        };
        self.feeding.addFeedingItem(.{
            .duration = duration,
            .date = self.date_input.value(),
            .time = self.time_input.value(),
            .notes = if (self.notes_input.value().len > 0) self.notes_input.value() else "N/A",
            .feeder = feeding_utils.FeedingFeeder.fromSlice(utils.feeder_options[self.feeder_dropdown.selected_index]),
            .feeding_type = feeding_utils.FeedingType.fromSlice(utils.feeding_type_options[self.feeding_type_dropdown.selected_index]),
        }) catch {
            self.status = "Failed to save feeding item";
            return;
        };
        self.status = "Saved!";
    }

    pub fn update(self: *HistoricFeedingForm) void {
        self.date_input.update();
        self.time_input.update();
        self.duration_input.update();
        self.notes_input.update();
        self.feeder_dropdown.update();
        self.feeding_type_dropdown.update();
        const mouse_pos = rl.getMousePosition();
        if (rl.checkCollisionPointRec(mouse_pos, self.submit_button.rect)) {
            rl.setMouseCursor(.pointing_hand);
            if (rl.isMouseButtonPressed(.left)) self.submit();
        }
    }
};
