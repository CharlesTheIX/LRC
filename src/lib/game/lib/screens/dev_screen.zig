const std = @import("std");
const rl = @import("raylib");
const Game = @import("../../root.zig").Game;
const core_utils = @import("../../utils.zig");
const Timer = @import("../timer/root.zig").Timer;
const Key = @import("../input_handler/root.zig").Key;
const Click = @import("../input_handler/root.zig").Click;
const InputHandler = @import("../input_handler/root.zig").InputHandler;

const Props = struct { font: rl.Font, font_size: u32 = 32, allocator: *std.mem.Allocator };

const DevSubScreen = enum { Home, CoreGameDetails };

pub const DevScreen = struct {
    font: rl.Font,
    font_size: u32,
    input_timer: Timer,
    active: bool = false,
    allocator: *std.mem.Allocator,
    active_sub_screen: DevSubScreen = .Home,

    // Base methods
    pub fn deinit(self: *DevScreen) void {
        self.input_timer.deinit();
    }

    pub fn draw(self: *DevScreen, game: *Game) void {
        if (!self.active) return;
        self.drawBackground();
        switch (self.active_sub_screen) {
            .Home => self.drawHome(),
            .CoreGameDetails => self.drawCoreGameDetails(game),
        }
    }

    pub fn init(props: Props) DevScreen {
        const input_timer_timeout = 0.2;
        var input_timer = Timer.init(.{ .timer_type = .Countdown, .allocator = props.allocator, .target_time = input_timer_timeout });
        input_timer.finished = true; // Start the timer in a finished state so that it can be started on the first input
        return DevScreen{ .font = props.font, .font_size = props.font_size, .input_timer = input_timer, .allocator = props.allocator };
    }

    pub fn load(self: *DevScreen) void {
        _ = self;
    }

    pub fn update(self: *DevScreen, game: *Game) void {
        self.updateToggle(&game.input_handler);
        if (!self.active) return;
        switch (self.active_sub_screen) {
            .Home => {},
            .CoreGameDetails => {},
        }
    }

    // Helper methods
    fn drawBackground(self: *DevScreen) void {
        _ = self;
        const rect = rl.Rectangle.init(0, 0, @as(f32, @floatFromInt(rl.getScreenWidth())), @as(f32, @floatFromInt(rl.getScreenHeight())));
        rl.drawRectangleRec(rect, rl.Color.black.alpha(0.5));
    }

    fn drawCoreGameDetails(self: *DevScreen, game: *Game) void {
        var buffer: [128]u8 = undefined;
        const mouse = &game.input_handler.mouse;
        const kb = &game.input_handler.keyboard;
        var font_size_f32 = core_utils.getFontSizeF32(self.font_size);
        var draw_pos = rl.Vector2.init(font_size_f32, font_size_f32);
        rl.drawTextEx(self.font, "Core Game Details", draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        font_size_f32 /= 2;
        draw_pos.y += font_size_f32;
        self.drawInstructions(&draw_pos);
        // Draw Mouse Screen Position
        draw_pos.y += font_size_f32 * 2;
        const mouse_pos = mouse.pos;
        const mouse_pos_content = std.fmt.bufPrint(&buffer, "Mouse Screen Position: ({d}, {d})", .{ mouse_pos.x, mouse_pos.y }) catch "";
        const mouse_pos_content_str = core_utils.sliceToZSlice(self.allocator, mouse_pos_content) catch @panic("Failed to allocate memory for mouse_pos_content_str");
        defer self.allocator.free(mouse_pos_content_str);
        rl.drawTextEx(self.font, mouse_pos_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Mouse World Position
        draw_pos.y += font_size_f32;
        const mouse_world_pos = rl.getScreenToWorld2D(mouse.pos, game.camera.camera2D);
        const mouse_world_pos_content = std.fmt.bufPrint(&buffer, "Mouse World Position: ({d:.2}, {d:.2})", .{ mouse_world_pos.x, mouse_world_pos.y }) catch "";
        const mouse_world_pos_content_str = core_utils.sliceToZSlice(self.allocator, mouse_world_pos_content) catch @panic("Failed to allocate memory for mouse_world_pos_content_str");
        defer self.allocator.free(mouse_world_pos_content_str);
        rl.drawTextEx(self.font, mouse_world_pos_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Mouse Scroll
        draw_pos.y += font_size_f32;
        const mouse_scroll = mouse.scroll;
        const mouse_scroll_content = std.fmt.bufPrint(&buffer, "Mouse Scroll: ({d}, {d})", .{ mouse_scroll.x, mouse_scroll.y }) catch "";
        const mouse_scroll_content_str = core_utils.sliceToZSlice(self.allocator, mouse_scroll_content) catch @panic("Failed to allocate memory for mouse_scroll_content_str");
        defer self.allocator.free(mouse_scroll_content_str);
        rl.drawTextEx(self.font, mouse_scroll_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Mouse Cursor
        draw_pos.y += font_size_f32;
        const mouse_cursor = mouse.cursor;
        const mouse_cursor_content = std.fmt.bufPrint(&buffer, "Mouse Cursor: {s}", .{mouse_cursor.toString()}) catch "";
        const mouse_cursor_content_str = core_utils.sliceToZSlice(self.allocator, mouse_cursor_content) catch @panic("Failed to allocate memory for mouse_cursor_content_str");
        defer self.allocator.free(mouse_cursor_content_str);
        rl.drawTextEx(self.font, mouse_cursor_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Mouse Active Clicks
        draw_pos.y += font_size_f32;
        var active_clicks_buffer: [64]u8 = undefined;
        var active_clicks_len: usize = 0;
        for (Click.array()) |click| {
            if (mouse.getClickPressOrderIndex(click) == null) continue;
            const written = std.fmt.bufPrint(active_clicks_buffer[active_clicks_len..], "{s} ", .{click.toString()}) catch break;
            active_clicks_len += written.len;
        }
        const active_clicks_content = std.fmt.bufPrint(&buffer, "Mouse Active Clicks: {s}", .{if (active_clicks_len == 0) "None" else active_clicks_buffer[0..active_clicks_len]}) catch "";
        const active_clicks_content_str = core_utils.sliceToZSlice(self.allocator, active_clicks_content) catch @panic("Failed to allocate memory for active_clicks_content_str");
        defer self.allocator.free(active_clicks_content_str);
        rl.drawTextEx(self.font, active_clicks_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Mouse Most Recently Pressed Click
        draw_pos.y += font_size_f32;
        const most_recent_click = mouse.getMostRecentlyPressedClick();
        const most_recent_click_content = std.fmt.bufPrint(&buffer, "Mouse Most Recently Pressed Click: {s}", .{if (most_recent_click) |click| click.toString() else "None"}) catch "";
        const most_recent_click_content_str = core_utils.sliceToZSlice(self.allocator, most_recent_click_content) catch @panic("Failed to allocate memory for most_recent_click_content_str");
        defer self.allocator.free(most_recent_click_content_str);
        rl.drawTextEx(self.font, most_recent_click_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Keyboard Active Keys
        draw_pos.y += font_size_f32;
        var active_keys_buffer: [256]u8 = undefined;
        var active_keys_len: usize = 0;
        for (Key.array()) |key| {
            if (kb.activeKeyIndex(key) == null) continue;
            const written = std.fmt.bufPrint(active_keys_buffer[active_keys_len..], "{s} ", .{key.toString(.Upper)}) catch break;
            active_keys_len += written.len;
        }
        const active_keys_content = std.fmt.bufPrint(&buffer, "Keyboard Active Keys: {s}", .{if (active_keys_len == 0) "None" else active_keys_buffer[0..active_keys_len]}) catch "";
        const active_keys_content_str = core_utils.sliceToZSlice(self.allocator, active_keys_content) catch @panic("Failed to allocate memory for active_keys_content_str");
        defer self.allocator.free(active_keys_content_str);
        rl.drawTextEx(self.font, active_keys_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Keyboard Most Recently Pressed Key
        draw_pos.y += font_size_f32;
        const most_recent_key = kb.mostRecentActiveKey();
        const most_recent_key_content = std.fmt.bufPrint(&buffer, "Keyboard Most Recently Pressed Key: {s}", .{if (most_recent_key) |key| key.toString(.Upper) else "None"}) catch "";
        const most_recent_key_content_str = core_utils.sliceToZSlice(self.allocator, most_recent_key_content) catch @panic("Failed to allocate memory for most_recent_key_content_str");
        defer self.allocator.free(most_recent_key_content_str);
        rl.drawTextEx(self.font, most_recent_key_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
    }

    fn drawHome(self: *DevScreen) void {
        var buffer: [128]u8 = undefined;
        var font_size_f32 = core_utils.getFontSizeF32(self.font_size);
        var draw_pos = rl.Vector2.init(font_size_f32, font_size_f32);
        rl.drawTextEx(self.font, "DEV SCREEN", draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        font_size_f32 /= 2;
        draw_pos.y += font_size_f32;
        self.drawInstructions(&draw_pos);
        // Draw FPS
        draw_pos.y += font_size_f32 * 2;
        const fps = rl.getFPS();
        const fps_content = std.fmt.bufPrint(&buffer, "FPS: {d}", .{fps}) catch "";
        const fps_content_str = core_utils.sliceToZSlice(self.allocator, fps_content) catch @panic("Failed to allocate memory for fps_content_str");
        defer self.allocator.free(fps_content_str);
        rl.drawTextEx(self.font, fps_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Frame Time
        draw_pos.y += font_size_f32;
        const frame_time = rl.getFrameTime();
        const frame_time_content = std.fmt.bufPrint(&buffer, "Frame Time: {d:.3} seconds", .{frame_time}) catch "";
        const frame_time_content_str = core_utils.sliceToZSlice(self.allocator, frame_time_content) catch @panic("Failed to allocate memory for frame_time_content_str");
        defer self.allocator.free(frame_time_content_str);
        rl.drawTextEx(self.font, frame_time_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw App Dir
        draw_pos.y += font_size_f32;
        const app_dir_content = std.fmt.bufPrint(&buffer, "App Dir: {s}", .{rl.getApplicationDirectory()}) catch "";
        const app_dir_content_str = core_utils.sliceToZSlice(self.allocator, app_dir_content) catch @panic("Failed to allocate memory for app_dir_content_str");
        defer self.allocator.free(app_dir_content_str);
        rl.drawTextEx(self.font, app_dir_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Working Directory
        draw_pos.y += font_size_f32;
        const working_dir_content = std.fmt.bufPrint(&buffer, "Working Directory: {s}", .{rl.getWorkingDirectory()}) catch "";
        const working_dir_content_str = core_utils.sliceToZSlice(self.allocator, working_dir_content) catch @panic("Failed to allocate memory for working_dir_content_str");
        defer self.allocator.free(working_dir_content_str);
        rl.drawTextEx(self.font, working_dir_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Screen Size
        draw_pos.y += font_size_f32;
        const screen_width = rl.getScreenWidth();
        const screen_height = rl.getScreenHeight();
        const screen_size_content = std.fmt.bufPrint(&buffer, "Screen Size: {d}x{d}", .{ screen_width, screen_height }) catch "";
        const screen_size_content_str = core_utils.sliceToZSlice(self.allocator, screen_size_content) catch @panic("Failed to allocate memory for screen_size_content_str");
        defer self.allocator.free(screen_size_content_str);
        rl.drawTextEx(self.font, screen_size_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Render Size
        draw_pos.y += font_size_f32;
        const render_width = rl.getRenderWidth();
        const render_height = rl.getRenderHeight();
        const render_size_content = std.fmt.bufPrint(&buffer, "Render Size: {d}x{d}", .{ render_width, render_height }) catch "";
        const render_size_content_str = core_utils.sliceToZSlice(self.allocator, render_size_content) catch @panic("Failed to allocate memory for render_size_content_str");
        defer self.allocator.free(render_size_content_str);
        rl.drawTextEx(self.font, render_size_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Monitor Details
        draw_pos.y += font_size_f32;
        const monitor_count = rl.getMonitorCount();
        const monitor_details_content = std.fmt.bufPrint(&buffer, "Monitor Count: {d}", .{monitor_count}) catch "";
        const monitor_details_content_str = core_utils.sliceToZSlice(self.allocator, monitor_details_content) catch @panic("Failed to allocate memory for monitor_details_content_str");
        defer self.allocator.free(monitor_details_content_str);
        rl.drawTextEx(self.font, monitor_details_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        draw_pos.y += font_size_f32;
        const current_monitor_content = std.fmt.bufPrint(&buffer, "Current Monitor: {d}", .{rl.getCurrentMonitor()}) catch "";
        const current_monitor_content_str = core_utils.sliceToZSlice(self.allocator, current_monitor_content) catch @panic("Failed to allocate memory for current_monitor_content_str");
        defer self.allocator.free(current_monitor_content_str);
        rl.drawTextEx(self.font, current_monitor_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        var monitor_index: i32 = 0;
        while (monitor_index < monitor_count) : (monitor_index += 1) {
            draw_pos.y += font_size_f32;
            const monitor_width = rl.getMonitorWidth(monitor_index);
            const monitor_height = rl.getMonitorHeight(monitor_index);
            const monitor_name = rl.getMonitorName(monitor_index);
            const monitor_content = std.fmt.bufPrint(&buffer, "Monitor {d} ({s}): {d}x{d}", .{ monitor_index, monitor_name, monitor_width, monitor_height }) catch "";
            const monitor_content_str = core_utils.sliceToZSlice(self.allocator, monitor_content) catch @panic("Failed to allocate memory for monitor_content_str");
            defer self.allocator.free(monitor_content_str);
            rl.drawTextEx(self.font, monitor_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
            buffer = undefined;
            draw_pos.y += font_size_f32;
            const monitor_refresh_rate = rl.getMonitorRefreshRate(monitor_index);
            const monitor_refresh_rate_content = std.fmt.bufPrint(&buffer, "Monitor {d} Refresh Rate: {d} Hz", .{ monitor_index, monitor_refresh_rate }) catch "";
            const monitor_refresh_rate_content_str = core_utils.sliceToZSlice(self.allocator, monitor_refresh_rate_content) catch @panic("Failed to allocate memory for monitor_refresh_rate_content_str");
            defer self.allocator.free(monitor_refresh_rate_content_str);
            rl.drawTextEx(self.font, monitor_refresh_rate_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
            buffer = undefined;
        }
        // Draw Time
        draw_pos.y += font_size_f32;
        const time = rl.getTime();
        const time_content = std.fmt.bufPrint(&buffer, "Time: {d:.3} seconds", .{time}) catch "";
        const time_content_str = core_utils.sliceToZSlice(self.allocator, time_content) catch @panic("Failed to allocate memory for time_content_str");
        defer self.allocator.free(time_content_str);
        rl.drawTextEx(self.font, time_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
    }

    fn drawInstructions(self: *DevScreen, draw_pos: *rl.Vector2) void {
        var buffer: [256]u8 = undefined;
        const font_size_f32 = core_utils.getFontSizeF32(self.font_size) / 2;
        const content = std.fmt.bufPrint(&buffer, "Press Ctrl +: 0 - toggle dev screen; 1 - home; 2 - core game details; 3 - null; 4 - null; 5 - null; 6 - null; 7 - null; 8 - null; 9 - null", .{}) catch "";
        const content_str = core_utils.sliceToZSlice(self.allocator, content) catch @panic("Failed to allocate memory for content_str");
        defer self.allocator.free(content_str);
        draw_pos.y += font_size_f32;
        rl.drawTextEx(self.font, content_str, draw_pos.*, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.light_gray);
    }

    fn updateToggle(self: *DevScreen, input_handler: *InputHandler) void {
        if (self.input_timer.running) return self.input_timer.update(rl.getFrameTime());
        const kb = &input_handler.keyboard;
        if (kb.activeKeysInclude(&[_]Key{ .LeftControl, .RightControl }, .Or)) {
            var input = false;
            if (kb.activeKeysInclude(&[_]Key{ .One, .Two, .Three, .Four, .Five, .Six, .Seven, .Eight, .Nine, .Zero }, .Or)) input = true;
            if (kb.activeKeysInclude(&[_]Key{.Zero}, .Or)) self.active = !self.active;
            if (self.active) {
                if (kb.activeKeysInclude(&[_]Key{.One}, .Or)) self.active_sub_screen = .Home;
                if (kb.activeKeysInclude(&[_]Key{.Two}, .Or)) self.active_sub_screen = .CoreGameDetails;
            }
            if (input) self.input_timer.restart();
        }
    }
};
