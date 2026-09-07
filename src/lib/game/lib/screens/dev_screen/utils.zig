const std = @import("std");
const rl = @import("raylib");
const Game = @import("../../../root.zig").Game;
const core_utils = @import("../../../utils.zig");
const DevScreen = @import("./root.zig").DevScreen;
const Key = @import("../../input_handler/root.zig").Key;
const Click = @import("../../input_handler/root.zig").Click;

pub const DevSubScreen = enum { Home, CoreGameDetails, SaveData, PlayerDetails };

pub fn drawCoreGameDetails(self: *DevScreen, game: *Game) void {
    var buffer: [128]u8 = undefined;
    const camera = &game.camera;
    const mouse = &game.input_handler.mouse;
    const kb = &game.input_handler.keyboard;
    var font_size_f32 = core_utils.getFontSizeF32(self.font_size);
    var draw_pos = rl.Vector2.init(font_size_f32, font_size_f32);
    rl.drawTextEx(self.font, "CORE GAME DETAILS", draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    font_size_f32 /= 2;
    draw_pos.y += font_size_f32;
    drawToggleInstructions(self, &draw_pos);
    drawCoreGameDetailsInstructions(self, &draw_pos);
    // Draw Current Game State
    draw_pos.y += font_size_f32 * 2;
    const game_state_content = std.fmt.bufPrint(&buffer, "Current Game State: {s}", .{game.game_state.toString()}) catch "";
    const game_state_content_str = core_utils.sliceToZSlice(self.allocator, game_state_content) catch @panic("Failed to allocate memory for game_state_content_str");
    defer self.allocator.free(game_state_content_str);
    rl.drawTextEx(self.font, game_state_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
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
    draw_pos.y += font_size_f32 * 2;
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
    // Draw Camera State
    draw_pos.y += font_size_f32 * 2;
    const camera_state_content = std.fmt.bufPrint(&buffer, "Camera State: {s}", .{camera.state.toString()}) catch "";
    const camera_state_content_str = core_utils.sliceToZSlice(self.allocator, camera_state_content) catch @panic("Failed to allocate memory for camera_state_content_str");
    defer self.allocator.free(camera_state_content_str);
    rl.drawTextEx(self.font, camera_state_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    // Draw Camera Snap to Map
    draw_pos.y += font_size_f32;
    const camera_snap_to_map_content = std.fmt.bufPrint(&buffer, "Camera Snap to Map: {s}", .{if (camera.snap_to_map) "Enabled" else "Disabled"}) catch "";
    const camera_snap_to_map_content_str = core_utils.sliceToZSlice(self.allocator, camera_snap_to_map_content) catch @panic("Failed to allocate memory for camera_snap_to_map_content_str");
    defer self.allocator.free(camera_snap_to_map_content_str);
    rl.drawTextEx(self.font, camera_snap_to_map_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Offset
    draw_pos.y += font_size_f32;
    const camera_offset_content = std.fmt.bufPrint(&buffer, "Camera Offset: ({d:.2}, {d:.2})", .{ camera.camera2D.offset.x, camera.camera2D.offset.y }) catch "";
    const camera_offset_content_str = core_utils.sliceToZSlice(self.allocator, camera_offset_content) catch @panic("Failed to allocate memory for camera_offset_content_str");
    defer self.allocator.free(camera_offset_content_str);
    rl.drawTextEx(self.font, camera_offset_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Position
    draw_pos.y += font_size_f32;
    const camera_position_content = std.fmt.bufPrint(&buffer, "Camera Position: ({d:.2}, {d:.2})", .{ camera.camera2D.target.x, camera.camera2D.target.y }) catch "";
    const camera_position_content_str = core_utils.sliceToZSlice(self.allocator, camera_position_content) catch @panic("Failed to allocate memory for camera_position_content_str");
    defer self.allocator.free(camera_position_content_str);
    rl.drawTextEx(self.font, camera_position_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Zoom
    draw_pos.y += font_size_f32 * 2;
    const camera_zoom_content = std.fmt.bufPrint(&buffer, "Camera Zoom: {d:.2}", .{camera.camera2D.zoom}) catch "";
    const camera_zoom_content_str = core_utils.sliceToZSlice(self.allocator, camera_zoom_content) catch @panic("Failed to allocate memory for camera_zoom_content_str");
    defer self.allocator.free(camera_zoom_content_str);
    rl.drawTextEx(self.font, camera_zoom_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Zoom Target
    draw_pos.y += font_size_f32;
    const camera_zoom_target_content = std.fmt.bufPrint(&buffer, "Camera Zoom Target: {d:.2}", .{camera.zoom.target}) catch "";
    const camera_zoom_target_content_str = core_utils.sliceToZSlice(self.allocator, camera_zoom_target_content) catch @panic("Failed to allocate memory for camera_zoom_target_content_str");
    defer self.allocator.free(camera_zoom_target_content_str);
    rl.drawTextEx(self.font, camera_zoom_target_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Zoom Min
    draw_pos.y += font_size_f32;
    const camera_zoom_min_content = std.fmt.bufPrint(&buffer, "Camera Zoom Min: {d:.2}", .{camera.zoom.min}) catch "";
    const camera_zoom_min_content_str = core_utils.sliceToZSlice(self.allocator, camera_zoom_min_content) catch @panic("Failed to allocate memory for camera_zoom_min_content_str");
    defer self.allocator.free(camera_zoom_min_content_str);
    rl.drawTextEx(self.font, camera_zoom_min_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Zoom Max
    draw_pos.y += font_size_f32;
    const camera_zoom_max_content = std.fmt.bufPrint(&buffer, "Camera Zoom Max: {d:.2}", .{camera.zoom.max}) catch "";
    const camera_zoom_max_content_str = core_utils.sliceToZSlice(self.allocator, camera_zoom_max_content) catch @panic("Failed to allocate memory for camera_zoom_max_content_str");
    defer self.allocator.free(camera_zoom_max_content_str);
    rl.drawTextEx(self.font, camera_zoom_max_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Zoom Speed
    draw_pos.y += font_size_f32;
    const camera_zoom_speed_content = std.fmt.bufPrint(&buffer, "Camera Zoom Speed: {d:.2}", .{camera.zoom.speed}) catch "";
    const camera_zoom_speed_content_str = core_utils.sliceToZSlice(self.allocator, camera_zoom_speed_content) catch @panic("Failed to allocate memory for camera_zoom_speed_content_str");
    defer self.allocator.free(camera_zoom_speed_content_str);
    rl.drawTextEx(self.font, camera_zoom_speed_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Zoom Lerp Speed
    draw_pos.y += font_size_f32;
    const camera_zoom_lerp_speed_content = std.fmt.bufPrint(&buffer, "Camera Zoom Lerp Speed: {d:.2}", .{camera.zoom.lerp_speed}) catch "";
    const camera_zoom_lerp_speed_content_str = core_utils.sliceToZSlice(self.allocator, camera_zoom_lerp_speed_content) catch @panic("Failed to allocate memory for camera_zoom_lerp_speed_content_str");
    defer self.allocator.free(camera_zoom_lerp_speed_content_str);
    rl.drawTextEx(self.font, camera_zoom_lerp_speed_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Rotation
    draw_pos.y += font_size_f32 * 2;
    const camera_rotation_content = std.fmt.bufPrint(&buffer, "Camera Rotation: {d:.2}", .{camera.camera2D.rotation}) catch "";
    const camera_rotation_content_str = core_utils.sliceToZSlice(self.allocator, camera_rotation_content) catch @panic("Failed to allocate memory for camera_rotation_content_str");
    defer self.allocator.free(camera_rotation_content_str);
    rl.drawTextEx(self.font, camera_rotation_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Target Rotation
    draw_pos.y += font_size_f32;
    const camera_target_rotation_content = std.fmt.bufPrint(&buffer, "Camera Rotation Target: {d:.2}", .{camera.rotation.target}) catch "";
    const camera_target_rotation_content_str = core_utils.sliceToZSlice(self.allocator, camera_target_rotation_content) catch @panic("Failed to allocate memory for camera_target_rotation_content_str");
    defer self.allocator.free(camera_target_rotation_content_str);
    rl.drawTextEx(self.font, camera_target_rotation_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Rotation Speed
    draw_pos.y += font_size_f32;
    const camera_rotation_speed_content = std.fmt.bufPrint(&buffer, "Camera Rotation Speed: {d:.2}", .{camera.rotation.speed}) catch "";
    const camera_rotation_speed_content_str = core_utils.sliceToZSlice(self.allocator, camera_rotation_speed_content) catch @panic("Failed to allocate memory for camera_rotation_speed_content_str");
    defer self.allocator.free(camera_rotation_speed_content_str);
    rl.drawTextEx(self.font, camera_rotation_speed_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Rotation Lerp Speed
    draw_pos.y += font_size_f32;
    const camera_rotation_lerp_speed_content = std.fmt.bufPrint(&buffer, "Camera Rotation Lerp Speed: {d:.2}", .{camera.rotation.lerp_speed}) catch "";
    const camera_rotation_lerp_speed_content_str = core_utils.sliceToZSlice(self.allocator, camera_rotation_lerp_speed_content) catch @panic("Failed to allocate memory for camera_rotation_lerp_speed_content_str");
    defer self.allocator.free(camera_rotation_lerp_speed_content_str);
    rl.drawTextEx(self.font, camera_rotation_lerp_speed_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Movement Target Position
    draw_pos.y += font_size_f32 * 2;
    const camera_movement_target_position_content = std.fmt.bufPrint(&buffer, "Camera Movement Target Position: ({d:.2}, {d:.2})", .{ camera.movement.target.x, camera.movement.target.y }) catch "";
    const camera_movement_target_position_content_str = core_utils.sliceToZSlice(self.allocator, camera_movement_target_position_content) catch @panic("Failed to allocate memory for camera_movement_target_position_content_str");
    defer self.allocator.free(camera_movement_target_position_content_str);
    rl.drawTextEx(self.font, camera_movement_target_position_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Movement Speed
    draw_pos.y += font_size_f32;
    const camera_movement_speed_content = std.fmt.bufPrint(&buffer, "Camera Movement Speed: {d:.2}", .{camera.movement.speed}) catch "";
    const camera_movement_speed_content_str = core_utils.sliceToZSlice(self.allocator, camera_movement_speed_content) catch @panic("Failed to allocate memory for camera_movement_speed_content_str");
    defer self.allocator.free(camera_movement_speed_content_str);
    rl.drawTextEx(self.font, camera_movement_speed_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Mouse Pan Active
    draw_pos.y += font_size_f32;
    const camera_mouse_pan_active_content = std.fmt.bufPrint(&buffer, "Camera Movement Mouse Pan Active: {s}", .{if (camera.movement.mouse_pan_active) "Yes" else "No"}) catch "";
    const camera_mouse_pan_active_content_str = core_utils.sliceToZSlice(self.allocator, camera_mouse_pan_active_content) catch @panic("Failed to allocate memory for camera_mouse_pan_active_content_str");
    defer self.allocator.free(camera_mouse_pan_active_content_str);
    rl.drawTextEx(self.font, camera_mouse_pan_active_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Mouse Pan Start Position
    draw_pos.y += font_size_f32;
    const camera_mouse_pan_start_position_content = std.fmt.bufPrint(&buffer, "Camera Movement Mouse Pan Start Position: ({d:.2}, {d:.2})", .{ camera.movement.mouse_pan_start.x, camera.movement.mouse_pan_start.y }) catch "";
    const camera_mouse_pan_start_position_content_str = core_utils.sliceToZSlice(self.allocator, camera_mouse_pan_start_position_content) catch @panic("Failed to allocate memory for camera_mouse_pan_start_position_content_str");
    defer self.allocator.free(camera_mouse_pan_start_position_content_str);
    rl.drawTextEx(self.font, camera_mouse_pan_start_position_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Mouse Pan Target Position
    draw_pos.y += font_size_f32;
    const camera_mouse_pan_target_position_content = std.fmt.bufPrint(&buffer, "Camera Movement Mouse Pan Target Position: ({d:.2}, {d:.2})", .{ camera.movement.mouse_pan_target.x, camera.movement.mouse_pan_target.y }) catch "";
    const camera_mouse_pan_target_position_content_str = core_utils.sliceToZSlice(self.allocator, camera_mouse_pan_target_position_content) catch @panic("Failed to allocate memory for camera_mouse_pan_target_position_content_str");
    defer self.allocator.free(camera_mouse_pan_target_position_content_str);
    rl.drawTextEx(self.font, camera_mouse_pan_target_position_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Camera Lerp Speed
    draw_pos.y += font_size_f32;
    const camera_lerp_speed_content = std.fmt.bufPrint(&buffer, "Camera Movement Lerp Speed: {d:.2}", .{camera.movement.lerp_speed}) catch "";
    const camera_lerp_speed_content_str = core_utils.sliceToZSlice(self.allocator, camera_lerp_speed_content) catch @panic("Failed to allocate memory for camera_lerp_speed_content_str");
    defer self.allocator.free(camera_lerp_speed_content_str);
    rl.drawTextEx(self.font, camera_lerp_speed_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
}

pub fn drawCoreGameDetailsInstructions(self: *DevScreen, draw_pos: *rl.Vector2) void {
    var buffer: [256]u8 = undefined;
    const font_size_f32 = core_utils.getFontSizeF32(self.font_size) / 2;
    const content = std.fmt.bufPrint(&buffer, "Press Shift +: 1 - shift camera state; 2 - toggle camera snap to map", .{}) catch "";
    const content_str = core_utils.sliceToZSlice(self.allocator, content) catch @panic("Failed to allocate memory for content_str");
    defer self.allocator.free(content_str);
    draw_pos.y += font_size_f32;
    rl.drawTextEx(self.font, content_str, draw_pos.*, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.light_gray);
}

pub fn drawHome(self: *DevScreen) void {
    var buffer: [128]u8 = undefined;
    var font_size_f32 = core_utils.getFontSizeF32(self.font_size);
    var draw_pos = rl.Vector2.init(font_size_f32, font_size_f32);
    rl.drawTextEx(self.font, "DEV SCREEN", draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    font_size_f32 /= 2;
    draw_pos.y += font_size_f32;
    drawToggleInstructions(self, &draw_pos);
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
    draw_pos.y += font_size_f32 * 2;
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
    draw_pos.y += font_size_f32 * 2;
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
    draw_pos.y += font_size_f32 * 2;
    const monitor_count = rl.getMonitorCount();
    const monitor_details_content = std.fmt.bufPrint(&buffer, "Monitor Count: {d}", .{monitor_count}) catch "";
    const monitor_details_content_str = core_utils.sliceToZSlice(self.allocator, monitor_details_content) catch @panic("Failed to allocate memory for monitor_details_content_str");
    defer self.allocator.free(monitor_details_content_str);
    rl.drawTextEx(self.font, monitor_details_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    draw_pos.y += font_size_f32;
    const current_monitor_content = std.fmt.bufPrint(&buffer, "Monitor Active: {d}", .{rl.getCurrentMonitor()}) catch "";
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
    draw_pos.y += font_size_f32 * 2;
    const time = rl.getTime();
    const time_content = std.fmt.bufPrint(&buffer, "Time since application start: {d:.3} seconds", .{time}) catch "";
    const time_content_str = core_utils.sliceToZSlice(self.allocator, time_content) catch @panic("Failed to allocate memory for time_content_str");
    defer self.allocator.free(time_content_str);
    rl.drawTextEx(self.font, time_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
}

pub fn drawPlayerDetails(self: *DevScreen, game: *Game) void {
    const play_screen = game.play_screen;
    if (play_screen) |ps| {
        var buffer: [128]u8 = undefined;
        const player = ps.player;
        var font_size_f32 = core_utils.getFontSizeF32(self.font_size);
        var draw_pos = rl.Vector2.init(font_size_f32, font_size_f32);
        rl.drawTextEx(self.font, "PLAYER DETAILS", draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        font_size_f32 /= 2;
        draw_pos.y += font_size_f32;
        drawToggleInstructions(self, &draw_pos);
        drawPlayerDetailsInstructions(self, &draw_pos);
        // Draw Player Name
        draw_pos.y += font_size_f32 * 2;
        const player_name = std.fmt.bufPrint(&buffer, "Player Name: {s}", .{player.name}) catch "";
        const player_name_str = core_utils.sliceToZSlice(self.allocator, player_name) catch @panic("Failed to allocate memory for player_name_str");
        defer self.allocator.free(player_name_str);
        rl.drawTextEx(self.font, player_name_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Player Target Position
        draw_pos.y += font_size_f32 * 2;
        const target_position = player.target_position;
        const target_position_content = std.fmt.bufPrint(&buffer, "Target Position: ({d}, {d})", .{ target_position.x, target_position.y }) catch "";
        const target_position_content_str = core_utils.sliceToZSlice(self.allocator, target_position_content) catch @panic("Failed to allocate memory for target_position_content_str");
        defer self.allocator.free(target_position_content_str);
        rl.drawTextEx(self.font, target_position_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Position
        draw_pos.y += font_size_f32 * 2;
        const position = player.position;
        const position_content = std.fmt.bufPrint(&buffer, "Position: ({d}, {d})", .{ position.x, position.y }) catch "";
        const position_content_str = core_utils.sliceToZSlice(self.allocator, position_content) catch @panic("Failed to allocate memory for position_content_str");
        defer self.allocator.free(position_content_str);
        rl.drawTextEx(self.font, position_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Is Moving
        draw_pos.y += font_size_f32 * 2;
        const is_moving_content = std.fmt.bufPrint(&buffer, "Is Moving: {s}", .{if (player.is_moving) "Yes" else "No"}) catch "";
        const is_moving_content_str = core_utils.sliceToZSlice(self.allocator, is_moving_content) catch @panic("Failed to allocate memory for is_moving_content_str");
        defer self.allocator.free(is_moving_content_str);
        rl.drawTextEx(self.font, is_moving_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Is Sprinting
        draw_pos.y += font_size_f32 * 2;
        const is_sprinting_content = std.fmt.bufPrint(&buffer, "Is Sprinting: {s}", .{if (player.is_sprinting) "Yes" else "No"}) catch "";
        const is_sprinting_content_str = core_utils.sliceToZSlice(self.allocator, is_sprinting_content) catch @panic("Failed to allocate memory for is_sprinting_content_str");
        defer self.allocator.free(is_sprinting_content_str);
        rl.drawTextEx(self.font, is_sprinting_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Speed
        draw_pos.y += font_size_f32 * 2;
        const speed_content = std.fmt.bufPrint(&buffer, "Speed: {d:.2}", .{player.speed}) catch "";
        const speed_content_str = core_utils.sliceToZSlice(self.allocator, speed_content) catch @panic("Failed to allocate memory for speed_content_str");
        defer self.allocator.free(speed_content_str);
        rl.drawTextEx(self.font, speed_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Base Speed
        draw_pos.y += font_size_f32 * 2;
        const base_speed_content = std.fmt.bufPrint(&buffer, "Base Speed: {d:.2}", .{player.base_speed}) catch "";
        const base_speed_content_str = core_utils.sliceToZSlice(self.allocator, base_speed_content) catch @panic("Failed to allocate memory for base_speed_content_str");
        defer self.allocator.free(base_speed_content_str);
        rl.drawTextEx(self.font, base_speed_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Sprint Speed
        draw_pos.y += font_size_f32 * 2;
        const sprint_speed_content = std.fmt.bufPrint(&buffer, "Sprint Speed: {d:.2}", .{player.sprint_speed}) catch "";
        const sprint_speed_content_str = core_utils.sliceToZSlice(self.allocator, sprint_speed_content) catch @panic("Failed to allocate memory for sprint_speed_content_str");
        defer self.allocator.free(sprint_speed_content_str);
        rl.drawTextEx(self.font, sprint_speed_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Direction
        draw_pos.y += font_size_f32 * 2;
        const direction_content = std.fmt.bufPrint(&buffer, "Direction: {s}", .{player.direction.toString()}) catch "";
        const direction_content_str = core_utils.sliceToZSlice(self.allocator, direction_content) catch @panic("Failed to allocate memory for direction_content_str");
        defer self.allocator.free(direction_content_str);
        rl.drawTextEx(self.font, direction_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Core Rect
        draw_pos.y += font_size_f32 * 2;
        const core_rect_content = std.fmt.bufPrint(&buffer, "Core Rect: ({d}, {d}, {d}, {d})", .{ player.rects.core.x, player.rects.core.y, player.rects.core.width, player.rects.core.height }) catch "";
        const core_rect_content_str = core_utils.sliceToZSlice(self.allocator, core_rect_content) catch @panic("Failed to allocate memory for core_rect_content_str");
        defer self.allocator.free(core_rect_content_str);
        rl.drawTextEx(self.font, core_rect_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Upper Rect
        draw_pos.y += font_size_f32 * 2;
        const upper_rect_content = std.fmt.bufPrint(&buffer, "Upper Rect: ({d}, {d}, {d}, {d})", .{ player.rects.upper.x, player.rects.upper.y, player.rects.upper.width, player.rects.upper.height }) catch "";
        const upper_rect_content_str = core_utils.sliceToZSlice(self.allocator, upper_rect_content) catch @panic("Failed to allocate memory for upper_rect_content_str");
        defer self.allocator.free(upper_rect_content_str);
        rl.drawTextEx(self.font, upper_rect_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Lower Rect
        draw_pos.y += font_size_f32 * 2;
        const lower_rect_content = std.fmt.bufPrint(&buffer, "Lower Rect: ({d}, {d}, {d}, {d})", .{ player.rects.lower.x, player.rects.lower.y, player.rects.lower.width, player.rects.lower.height }) catch "";
        const lower_rect_content_str = core_utils.sliceToZSlice(self.allocator, lower_rect_content) catch @panic("Failed to allocate memory for lower_rect_content_str");
        defer self.allocator.free(lower_rect_content_str);
        rl.drawTextEx(self.font, lower_rect_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
        // Draw Hitbox Rect
        draw_pos.y += font_size_f32 * 2;
        const hitbox_rect_content = std.fmt.bufPrint(&buffer, "Hitbox Rect: ({d}, {d}, {d}, {d})", .{ player.rects.hitbox.x, player.rects.hitbox.y, player.rects.hitbox.width, player.rects.hitbox.height }) catch "";
        const hitbox_rect_content_str = core_utils.sliceToZSlice(self.allocator, hitbox_rect_content) catch @panic("Failed to allocate memory for hitbox_rect_content_str");
        defer self.allocator.free(hitbox_rect_content_str);
        rl.drawTextEx(self.font, hitbox_rect_content_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
        buffer = undefined;
    }
}

pub fn drawPlayerDetailsInstructions(self: *DevScreen, draw_pos: *rl.Vector2) void {
    var buffer: [256]u8 = undefined;
    const font_size_f32 = core_utils.getFontSizeF32(self.font_size) / 2;
    const content = std.fmt.bufPrint(&buffer, "Press Shift +: 1 - null; 2 - null", .{}) catch "";
    const content_str = core_utils.sliceToZSlice(self.allocator, content) catch @panic("Failed to allocate memory for content_str");
    defer self.allocator.free(content_str);
    draw_pos.y += font_size_f32;
    rl.drawTextEx(self.font, content_str, draw_pos.*, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.light_gray);
}

pub fn drawSaveData(self: *DevScreen, game: *Game) void {
    var buffer: [128]u8 = undefined;
    var font_size_f32 = core_utils.getFontSizeF32(self.font_size);
    var draw_pos = rl.Vector2.init(font_size_f32, font_size_f32);
    rl.drawTextEx(self.font, "SAVE DATA", draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    font_size_f32 /= 2;
    draw_pos.y += font_size_f32;
    drawToggleInstructions(self, &draw_pos);
    drawSaveDataInstructions(self, &draw_pos);
    // Draw time
    draw_pos.y += font_size_f32 * 2;
    const time = std.fmt.bufPrint(&buffer, "Time: {d}", .{game.save_data.time}) catch "";
    const time_str = core_utils.sliceToZSlice(self.allocator, time) catch @panic("Failed to allocate memory for time_str");
    defer self.allocator.free(time_str);
    rl.drawTextEx(self.font, time_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
    // Draw Name
    draw_pos.y += font_size_f32;
    const name = std.fmt.bufPrint(&buffer, "Name: {s}", .{game.save_data.name}) catch "";
    const name_str = core_utils.sliceToZSlice(self.allocator, name) catch @panic("Failed to allocate memory for name_str");
    defer self.allocator.free(name_str);
    rl.drawTextEx(self.font, name_str, draw_pos, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.white);
    buffer = undefined;
}

pub fn drawSaveDataInstructions(self: *DevScreen, draw_pos: *rl.Vector2) void {
    var buffer: [256]u8 = undefined;
    const font_size_f32 = core_utils.getFontSizeF32(self.font_size) / 2;
    const content = std.fmt.bufPrint(&buffer, "Press Shift +: 1 - save; 2 - reset", .{}) catch "";
    const content_str = core_utils.sliceToZSlice(self.allocator, content) catch @panic("Failed to allocate memory for content_str");
    defer self.allocator.free(content_str);
    draw_pos.y += font_size_f32;
    rl.drawTextEx(self.font, content_str, draw_pos.*, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.light_gray);
}

pub fn drawToggleInstructions(self: *DevScreen, draw_pos: *rl.Vector2) void {
    var buffer: [256]u8 = undefined;
    const font_size_f32 = core_utils.getFontSizeF32(self.font_size) / 2;
    const content = std.fmt.bufPrint(&buffer, "Press Ctrl +: 0 - toggle dev screen; 1 - home; 2 - core game details; 3 - save data; 4 - player details; 5 - null; 6 - null; 7 - null; 8 - null; 9 - null", .{}) catch "";
    const content_str = core_utils.sliceToZSlice(self.allocator, content) catch @panic("Failed to allocate memory for content_str");
    defer self.allocator.free(content_str);
    draw_pos.y += font_size_f32;
    rl.drawTextEx(self.font, content_str, draw_pos.*, font_size_f32, core_utils.getCharSpacing(self.font_size), rl.Color.light_gray);
}

pub const number_keys = [_]Key{ .Zero, .One, .Two, .Three, .Four, .Five, .Six, .Seven, .Eight, .Nine };
