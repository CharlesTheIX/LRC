const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const Button = @import("../button.zig").Button;
const feeding_utils = @import("../../feeding/utils.zig");
const Feeding = @import("../../feeding/root.zig").Feeding;
const DateTime = @import("../../date_time/root.zig").DateTime;
const TextInput = @import("../inputs/text_input.zig").TextInput;
const SelectInput = @import("../inputs/select_input.zig").SelectInput;
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

const Props = struct { font: rl.Font, position: rl.Vector2, feeding: *Feeding, allocator: *std.mem.Allocator, layout_rect: rl.Rectangle };

/// Records a feeding as it happens: start/stop buttons time it and calculate the duration.
pub const TimerFeedingForm = struct {
    font: rl.Font,
    feeding: *Feeding,
    notes_input: TextInput,
    submit_button: Button,
    start_button: Button,
    stop_button: Button,
    status: []const u8 = "",
    start_time: ?DateTime = null,
    duration: ?u6 = null,
    feeder_select: SelectInput,
    allocator: *std.mem.Allocator,
    feeding_type_select: SelectInput,
    layout_rect: rl.Rectangle,

    pub fn deinit(self: *TimerFeedingForm) void {
        self.notes_input.deinit();
        self.submit_button.deinit();
        self.start_button.deinit();
        self.stop_button.deinit();
        self.feeder_select.deinit();
        self.feeding_type_select.deinit();
    }

    pub fn draw(self: *TimerFeedingForm) void {
        self.notes_input.draw();
        self.feeder_select.draw();
        self.feeding_type_select.draw();
        self.start_button.draw();
        self.stop_button.draw();
        self.submit_button.draw();
        if (self.duration) |duration| {
            var buffer: [32]u8 = undefined;
            const duration_z = std.fmt.bufPrintZ(&buffer, "Duration: {d}m", .{duration}) catch "Duration: ?m";
            rl.drawTextEx(self.font, duration_z, .init(self.stop_button.rect.x + self.stop_button.rect.width + 10, self.stop_button.rect.y + 6), 16, 2.0, rl.Color.dark_gray);
        }
        if (self.status.len == 0) return;
        const status_z = sliceToZSlice(self.allocator, self.status) catch return;
        defer self.allocator.free(status_z);
        rl.drawTextEx(self.font, status_z, .init(self.submit_button.rect.x + self.submit_button.rect.width + 10, self.submit_button.rect.y + 6), 16, 2.0, rl.Color.dark_gray);
    }

    pub fn init(props: Props) TimerFeedingForm {
        const spacing: f32 = 40;
        var pos = props.position;
        const field_width: f32 = 200;
        const notes_input = TextInput.init(.{ .font = props.font, .font_size = 16, .width = field_width, .bg_color = rl.Color.white, .txt_color = rl.Color.black, .border_color = rl.Color.gray, .placeholder = "Notes", .allocator = props.allocator, .layout_rect = rl.Rectangle.init(pos.x, pos.y, field_width, 0) });
        pos.y += spacing;
        const feeding_type_select = SelectInput.init(.{
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
        const feeder_select = SelectInput.init(.{
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
        const start_button = Button.init(.{
            .font_size = 16,
            .position = pos,
            .font = props.font,
            .bg_color = rl.Color.green,
            .label = "Start Feeding",
            .txt_color = rl.Color.white,
            .callback = null,
            .allocator = props.allocator,
        });
        var stop_button = Button.init(.{
            .font_size = 16,
            .position = pos,
            .font = props.font,
            .bg_color = rl.Color.red,
            .label = "Stop Feeding",
            .txt_color = rl.Color.white,
            .callback = null,
            .allocator = props.allocator,
        });
        stop_button.visible = false;
        pos.y += spacing;
        const submit_button = Button.init(.{
            .font_size = 16,
            .position = pos,
            .font = props.font,
            .bg_color = rl.Color.blue,
            .label = "Add Feeding",
            .txt_color = rl.Color.white,
            .callback = null,
            .allocator = props.allocator,
        });

        return TimerFeedingForm{
            .font = props.font,
            .feeding = props.feeding,
            .notes_input = notes_input,
            .submit_button = submit_button,
            .start_button = start_button,
            .stop_button = stop_button,
            .allocator = props.allocator,
            .layout_rect = props.layout_rect,
            .feeder_select = feeder_select,
            .feeding_type_select = feeding_type_select,
        };
    }

    /// Validates the current form values and delegates to `Feeding.addFeedingItem`.
    fn submit(self: *TimerFeedingForm) void {
        const start_time = self.start_time orelse {
            self.status = "Start and stop the feeding first";
            return;
        };
        const duration = self.duration orelse {
            self.status = "Stop the feeding to calculate duration";
            return;
        };
        const date = start_time.toDateString(self.allocator) catch {
            self.status = "Failed to format date";
            return;
        };
        defer self.allocator.free(date);
        const time = start_time.toTimeString(self.allocator) catch {
            self.status = "Failed to format time";
            return;
        };
        defer self.allocator.free(time);
        self.feeding.addFeedingItem(.{
            .date = date,
            .time = time,
            .duration = duration,
            .notes = if (self.notes_input.value().len > 0) self.notes_input.value() else "N/A",
            .feeder = feeding_utils.FeedingFeeder.fromSlice(utils.feeder_options[self.feeder_select.selected_index]),
            .feeding_type = feeding_utils.FeedingType.fromSlice(utils.feeding_type_options[self.feeding_type_select.selected_index]),
        }) catch {
            self.status = "Failed to save feeding item";
            return;
        };
        self.status = "Saved!";
        self.start_time = null;
        self.duration = null;
    }

    fn startFeeding(self: *TimerFeedingForm) void {
        self.start_time = DateTime.now();
        self.duration = null;
        self.start_button.visible = false;
        self.stop_button.visible = true;
        self.status = "Feeding started";
    }

    fn stopFeeding(self: *TimerFeedingForm) void {
        const start_time = self.start_time orelse return;
        const seconds = DateTime.now().getDiffSeconds(start_time);
        const minutes = @divFloor(seconds, 60);
        self.duration = std.math.cast(u6, minutes) orelse std.math.maxInt(u6);
        self.stop_button.visible = false;
        self.start_button.visible = true;
        self.status = "Feeding stopped";
    }

    pub fn update(self: *TimerFeedingForm) void {
        self.notes_input.update();
        self.feeder_select.update();
        self.feeding_type_select.update();

        const mouse_pos = rl.getMousePosition();
        if (self.start_button.visible and rl.checkCollisionPointRec(mouse_pos, self.start_button.rect)) {
            rl.setMouseCursor(.pointing_hand);
            if (rl.isMouseButtonPressed(.left)) self.startFeeding();
        }
        if (self.stop_button.visible and rl.checkCollisionPointRec(mouse_pos, self.stop_button.rect)) {
            rl.setMouseCursor(.pointing_hand);
            if (rl.isMouseButtonPressed(.left)) self.stopFeeding();
        }
        if (rl.checkCollisionPointRec(mouse_pos, self.submit_button.rect)) {
            rl.setMouseCursor(.pointing_hand);
            if (rl.isMouseButtonPressed(.left)) self.submit();
        }
    }
};
