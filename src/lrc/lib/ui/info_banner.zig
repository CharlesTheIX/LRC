const std = @import("std");
const rl = @import("raylib");
const Timer = @import("../timer.zig").Timer;
const Button = @import("./button.zig").Button;
const Dropdown = @import("./dropdown.zig").Dropdown;
const DateTime = @import("../date-time.zig").DateTime;
const Feeding = @import("../feeding/root.zig").Feeding;
const sliceToZSlice = @import("../utils.zig").sliceToZSlice;

const Props = struct { font: rl.Font, allocator: *std.mem.Allocator, feeding: *Feeding };

pub const InfoBanner = struct {
    timer: Timer,
    font: rl.Font,
    button: Button,
    dropdown: Dropdown,
    font_size: f32 = 16,
    last_feed: ?DateTime,
    next_feed_min: ?DateTime,
    next_feed_max: ?DateTime,
    timer_started: bool = false,
    allocator: *std.mem.Allocator,
    padding: rl.Vector2 = rl.Vector2.init(8, 8),

    pub fn deinit(self: *InfoBanner) void {
        self.timer.deinit();
        self.dropdown.deinit();
    }

    pub fn draw(self: *InfoBanner, draw_position: *rl.Vector2) void {
        self.drawBackground(draw_position);
        draw_position.x += self.padding.x; // Move right for padding
        draw_position.y += self.padding.y; // Move down for padding
        self.drawAppName(draw_position);
        draw_position.y += self.font_size; // Move down for the app name
        draw_position.y += self.padding.y; // Move down for the padding
        self.drawLastFeedingTime(draw_position);
        draw_position.y += self.font_size; // Move down for the app name
        draw_position.y += self.padding.y; // Move down for the padding
        self.drawNextFeedingTime(draw_position);
        draw_position.y += self.font_size; // Move down for the app name
        draw_position.y += self.padding.y; // Move down for the padding
        self.drawTimer(draw_position);

        draw_position.x = 0; // Reset x position for the next line
        draw_position.y += self.font_size; // Move down for the app name
        draw_position.y += self.padding.y; // Move down for the padding
        // self.dropdown.draw();
    }

    fn drawAppName(self: *InfoBanner, draw_position: *rl.Vector2) void {
        const app_name = "BABY TRACKER!";
        const app_name_slice = sliceToZSlice(self.allocator, app_name) catch @panic("Failed to convert app_name to zslice");
        defer self.allocator.free(app_name_slice);
        rl.drawTextEx(self.font, app_name_slice, draw_position.*, self.font_size, 2.0, rl.Color.white);
    }

    fn drawBackground(self: *InfoBanner, draw_position: *rl.Vector2) void {
        const banner_height = self.padding.y * 5 + self.font_size * 4; // Adjust height based on padding and font size
        const banner_rect = rl.Rectangle.init(draw_position.x, draw_position.y, @as(f32, @floatFromInt(rl.getScreenWidth())), banner_height);
        rl.drawRectangleRec(banner_rect, rl.Color.dark_gray.alpha(0.3));
    }

    fn drawLastFeedingTime(self: *InfoBanner, draw_position: *rl.Vector2) void {
        if (self.last_feed) |lf| {
            var buffer: [128]u8 = undefined;
            const last_feed_date = lf.toDateString(self.allocator) catch @panic("Failed to convert last feeding date time to date string");
            defer self.allocator.free(last_feed_date);
            const last_feed_time = lf.toTimeString(self.allocator) catch @panic("Failed to convert last feeding date time to time string");
            defer self.allocator.free(last_feed_time);
            const last_feeding_time_msg = std.fmt.bufPrint(&buffer, "Last feed: {s} {s}", .{ last_feed_date, last_feed_time }) catch @panic("Failed to format last feeding message");
            const last_feeding_time_msg_slice = sliceToZSlice(self.allocator, last_feeding_time_msg) catch @panic("Failed to convert last_feeding_msg to zslice");
            defer self.allocator.free(last_feeding_time_msg_slice);
            rl.drawTextEx(self.font, last_feeding_time_msg_slice, draw_position.*, self.font_size, 2.0, rl.Color.white);
        } else return self.drawNotFoundMessage(draw_position, self.font_size);
    }

    fn drawNextFeedingTime(self: *InfoBanner, draw_position: *rl.Vector2) void {
        if (self.next_feed_min) |nf_min| {
            if (self.next_feed_max) |nf_max| {
                var buffer: [128]u8 = undefined;
                const next_feed_max_date = nf_max.toDateString(self.allocator) catch @panic("Failed to convert next feeding max date time to date string");
                defer self.allocator.free(next_feed_max_date);
                const next_feed_max_time = nf_max.toTimeString(self.allocator) catch @panic("Failed to convert next feeding max date time to time string");
                defer self.allocator.free(next_feed_max_time);
                const next_feed_min_date = nf_min.toDateString(self.allocator) catch @panic("Failed to convert next feeding min date time to date string");
                defer self.allocator.free(next_feed_min_date);
                const next_feed_min_time = nf_min.toTimeString(self.allocator) catch @panic("Failed to convert next feeding min date time to time string");
                defer self.allocator.free(next_feed_min_time);
                const next_feeding_time_msg = std.fmt.bufPrint(&buffer, "Next feed (min / max): {s} {s} / {s} {s}", .{ next_feed_min_date, next_feed_min_time, next_feed_max_date, next_feed_max_time }) catch @panic("Failed to format next feeding message");
                const next_feeding_time_msg_slice = sliceToZSlice(self.allocator, next_feeding_time_msg) catch @panic("Failed to convert next_feeding_time_msg to zslice");
                defer self.allocator.free(next_feeding_time_msg_slice);
                rl.drawTextEx(self.font, next_feeding_time_msg_slice, draw_position.*, self.font_size, 2.0, rl.Color.white);
            } else return self.drawNotFoundMessage(draw_position, self.font_size);
        } else return self.drawNotFoundMessage(draw_position, self.font_size);
    }

    fn drawNotFoundMessage(self: *InfoBanner, draw_position: *rl.Vector2, font_size: f32) void {
        const not_found_str = "No feeding data available";
        const not_found_width = @divFloor(rl.measureTextEx(self.font, not_found_str, font_size, 2.0).x, 2);
        const window_centre_x = @as(f32, @floatFromInt(rl.getScreenWidth())) / 2;
        const print_pos_x = window_centre_x - not_found_width;
        draw_position.x = print_pos_x;
        rl.drawTextEx(self.font, not_found_str, draw_position.*, font_size, 2.0, rl.Color.white);
    }

    fn drawTimer(self: *InfoBanner, draw_position: *rl.Vector2) void {
        const timer_current_time_str = self.timer.formatTime(.HoursMinutesSeconds, self.allocator);
        defer self.allocator.free(timer_current_time_str);
        const timer_current_time_zstr = sliceToZSlice(self.allocator, timer_current_time_str) catch @panic("Failed to convert timer_current_time to zslice");
        defer self.allocator.free(timer_current_time_zstr);
        var timer_color = rl.Color.white;
        if (self.next_feed_min) |nfm| {
            if (self.timer.current_time >= @as(f64, @floatFromInt(nfm.unix_seconds))) timer_color = rl.Color.red;
        }
        if (self.next_feed_max) |nfm| {
            if (self.timer.current_time >= @as(f64, @floatFromInt(nfm.unix_seconds))) timer_color = rl.Color.red;
        }
        rl.drawTextEx(self.font, timer_current_time_zstr, draw_position.*, self.font_size, 2.0, timer_color);
    }

    pub fn init(props: Props) InfoBanner {
        const last_feed = props.feeding.getLastFeedingDateTime();
        const next_feed_min = if (last_feed) |lf| lf.addSeconds(@as(i64, @intCast(60 * 60 * 2))) else null;
        const next_feed_max = if (last_feed) |lf| lf.addSeconds(@as(i64, @intCast(60 * 60 * 3))) else null;
        const diff_secs = if (next_feed_max) |nfm| nfm.getDiffSeconds(DateTime.now().addSeconds(6 * 1200)) else 0;
        std.debug.print("{d}\n", .{diff_secs});
        const timer_target_time = @as(f64, @floatFromInt(diff_secs));
        const timer = Timer.init(.{ .timer_type = .Countdown, .allocator = props.allocator, .target_time = timer_target_time });
        const dropdown = Dropdown.init(.{
            .font_size = 18,
            .font = props.font,
            .txt_color = rl.Color.black,
            .border_color = rl.Color.gray,
            .bg_color = rl.Color.light_gray,
            .allocator = props.allocator,
            .highlight_color = rl.Color.sky_blue,
            .position = rl.Vector2.init(20, 90),
            .options = &.{ "Pavla", "David", "Other" },
        });
        const button = Button.init(.{
            .font_size = 16,
            .font = props.font,
            .label = "Click Me",
            .bg_color = rl.Color.blue,
            .txt_color = rl.Color.white,
            .callback = null,
            .allocator = props.allocator,
            .position = rl.Vector2.init(10, 50),
        });
        return InfoBanner{
            .timer = timer,
            .font = props.font,
            .button = button,
            .dropdown = dropdown,
            .last_feed = last_feed,
            .allocator = props.allocator,
            .next_feed_min = next_feed_min,
            .next_feed_max = next_feed_max,
        };
    }

    pub fn update(self: *InfoBanner) void {
        if (!self.timer_started) {
            self.timer.start();
            self.timer_started = true;
        }
        self.button.update();
        self.dropdown.update();
        self.timer.update(rl.getFrameTime());
    }
};
