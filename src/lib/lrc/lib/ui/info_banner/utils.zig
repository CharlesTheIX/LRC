const std = @import("std");
const rl = @import("raylib");
const InfoBanner = @import("./root.zig").InfoBanner;
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

pub fn drawAppName(info_banner: *InfoBanner, draw_position: *rl.Vector2) void {
    const app_name = "BABY TRACKER!";
    const app_name_slice = sliceToZSlice(info_banner.allocator, app_name) catch @panic("Failed to convert app_name to zslice");
    defer info_banner.allocator.free(app_name_slice);
    rl.drawTextEx(info_banner.font, app_name_slice, draw_position.*, info_banner.font_size, 2.0, rl.Color.white);
}

pub fn drawBackground(info_banner: *InfoBanner, draw_position: *rl.Vector2) void {
    const banner_height = info_banner.padding.y * 5 + info_banner.font_size * 4; // Adjust height based on padding and font size
    const banner_rect = rl.Rectangle.init(draw_position.x, draw_position.y, @as(f32, @floatFromInt(rl.getScreenWidth())), banner_height);
    rl.drawRectangleRec(banner_rect, rl.Color.dark_gray.alpha(0.3));
}

pub fn drawLastFeedingTime(info_banner: *InfoBanner, draw_position: *rl.Vector2) void {
    if (info_banner.last_feed) |lf| {
        var buffer: [128]u8 = undefined;
        const last_feed_date = lf.toDateString(info_banner.allocator) catch @panic("Failed to convert last feeding date time to date string");
        defer info_banner.allocator.free(last_feed_date);
        const last_feed_time = lf.toTimeString(info_banner.allocator) catch @panic("Failed to convert last feeding date time to time string");
        defer info_banner.allocator.free(last_feed_time);
        const last_feeding_time_msg = std.fmt.bufPrint(&buffer, "Last feed: {s} {s}", .{ last_feed_date, last_feed_time }) catch @panic("Failed to format last feeding message");
        const last_feeding_time_msg_slice = sliceToZSlice(info_banner.allocator, last_feeding_time_msg) catch @panic("Failed to convert last_feeding_msg to zslice");
        defer info_banner.allocator.free(last_feeding_time_msg_slice);
        rl.drawTextEx(info_banner.font, last_feeding_time_msg_slice, draw_position.*, info_banner.font_size, 2.0, rl.Color.white);
    } else return drawNotFoundMessage(info_banner, draw_position, info_banner.font_size);
}

pub fn drawNextFeedingTime(info_banner: *InfoBanner, draw_position: *rl.Vector2) void {
    if (info_banner.next_feed_min) |nf_min| {
        if (info_banner.next_feed_max) |nf_max| {
            var buffer: [128]u8 = undefined;
            const next_feed_max_date = nf_max.toDateString(info_banner.allocator) catch @panic("Failed to convert next feeding max date time to date string");
            defer info_banner.allocator.free(next_feed_max_date);
            const next_feed_max_time = nf_max.toTimeString(info_banner.allocator) catch @panic("Failed to convert next feeding max date time to time string");
            defer info_banner.allocator.free(next_feed_max_time);
            const next_feed_min_date = nf_min.toDateString(info_banner.allocator) catch @panic("Failed to convert next feeding min date time to date string");
            defer info_banner.allocator.free(next_feed_min_date);
            const next_feed_min_time = nf_min.toTimeString(info_banner.allocator) catch @panic("Failed to convert next feeding min date time to time string");
            defer info_banner.allocator.free(next_feed_min_time);
            const next_feeding_time_msg = std.fmt.bufPrint(&buffer, "Next feed (min / max): {s} {s} / {s} {s}", .{ next_feed_min_date, next_feed_min_time, next_feed_max_date, next_feed_max_time }) catch @panic("Failed to format next feeding message");
            const next_feeding_time_msg_slice = sliceToZSlice(info_banner.allocator, next_feeding_time_msg) catch @panic("Failed to convert next_feeding_time_msg to zslice");
            defer info_banner.allocator.free(next_feeding_time_msg_slice);
            rl.drawTextEx(info_banner.font, next_feeding_time_msg_slice, draw_position.*, info_banner.font_size, 2.0, rl.Color.white);
        } else return drawNotFoundMessage(info_banner, draw_position, info_banner.font_size);
    } else return drawNotFoundMessage(info_banner, draw_position, info_banner.font_size);
}

fn drawNotFoundMessage(info_banner: *InfoBanner, draw_position: *rl.Vector2, font_size: f32) void {
    const not_found_str = "No feeding data available";
    const not_found_width = @divFloor(rl.measureTextEx(info_banner.font, not_found_str, font_size, 2.0).x, 2);
    const window_centre_x = @as(f32, @floatFromInt(rl.getScreenWidth())) / 2;
    const print_pos_x = window_centre_x - not_found_width;
    draw_position.x = print_pos_x;
    rl.drawTextEx(info_banner.font, not_found_str, draw_position.*, font_size, 2.0, rl.Color.white);
}

pub fn drawTimer(info_banner: *InfoBanner, draw_position: *rl.Vector2) void {
    const timer_current_time_str = info_banner.timer.formatTime(.HoursMinutesSeconds, info_banner.allocator);
    defer info_banner.allocator.free(timer_current_time_str);
    const timer_current_time_zstr = sliceToZSlice(info_banner.allocator, timer_current_time_str) catch @panic("Failed to convert timer_current_time to zslice");
    defer info_banner.allocator.free(timer_current_time_zstr);
    var timer_color = rl.Color.white;
    if (info_banner.next_feed_min) |nfm| {
        if (info_banner.timer.current_time >= @as(f64, @floatFromInt(nfm.unix_seconds))) timer_color = rl.Color.red;
    }
    if (info_banner.next_feed_max) |nfm| {
        if (info_banner.timer.current_time >= @as(f64, @floatFromInt(nfm.unix_seconds)) + 30) timer_color = rl.Color.red;
    }
    rl.drawTextEx(info_banner.font, timer_current_time_zstr, draw_position.*, info_banner.font_size, 2.0, timer_color);
}
