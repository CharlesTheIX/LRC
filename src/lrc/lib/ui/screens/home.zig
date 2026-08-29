const std = @import("std");
const rl = @import("raylib");

const Props = struct {};

pub const HomeScreen = struct {
    pub fn deinit(self: *HomeScreen) void {
        // No resources to free for now
        _ = self; // Suppress unused variable warning
    }

    pub fn draw() void {
        rl.drawText("Welcome to the Home Screen!", 20, 20, 20, rl.Color.dark_gray);
    }

    pub fn init() HomeScreen {
        return HomeScreen{};
    }

    pub fn update(self: *HomeScreen) void {
        // No update logic for now
        _ = self; // Suppress unused variable warning
    }
};
