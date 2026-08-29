const std = @import("std");
const rl = @import("raylib");

const Props = struct {};

pub const HomeScreen = struct {
    layout_padding: rl.Vector2 = rl.Vector2.init(20, 20),

    pub fn deinit(self: *HomeScreen) void {
        // No resources to free for now
        _ = self; // Suppress unused variable warning
    }

    pub fn draw(self: *HomeScreen, draw_position: *rl.Vector2) void {
        _ = draw_position.add(self.layout_padding);
        rl.drawText(
            "Welcome to the Home Screen!",
            @as(i32, @intFromFloat(draw_position.x)),
            @as(i32, @intFromFloat(draw_position.y)),
            20,
            rl.Color.dark_gray,
        );
    }

    pub fn init() HomeScreen {
        return HomeScreen{};
    }

    pub fn update(self: *HomeScreen) void {
        // No update logic for now
        _ = self; // Suppress unused variable warning
    }
};
