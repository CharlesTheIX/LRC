const std = @import("std");
const rl = @import("raylib");
const Key = @import("../../input_handler/root.zig").Key;
const InputHandler = @import("../../input_handler/root.zig").InputHandler;
const invertScroll = @import("../../../utils.zig").invertScroll;

pub const Rotation = struct {
    speed: f32 = 5.0,
    target: f32 = 0.0,
    lerp_speed: f32 = 0.1,

    // Base methods
    pub fn deinit(self: *Rotation) void {
        _ = self;
    }

    pub fn init() Rotation {
        return .{};
    }

    pub fn update(self: *Rotation, camera: *rl.Camera2D, ih: *InputHandler) void {
        self.updateFromInput(camera, ih);
        self.updateFromScroll(ih);
    }

    // Helper methods
    fn updateFromInput(self: *Rotation, camera: *rl.Camera2D, ih: *InputHandler) void {
        const rotate_left = ih.keyboard.activeKeysInclude(&[_]Key{.RightBracket}, .And);
        const rotate_right = ih.keyboard.activeKeysInclude(&[_]Key{.LeftBracket}, .And);
        if (rotate_left) self.target -= self.speed;
        if (rotate_right) self.target += self.speed;
        const rotation_diff = self.target - camera.rotation;
        if (@abs(rotation_diff) > 0.001) {
            camera.rotation += rotation_diff * self.lerp_speed;
        } else camera.rotation = self.target;
    }

    fn updateFromScroll(self: *Rotation, ih: *InputHandler) void {
        if (ih.mouse.scroll.x == 0 and ih.mouse.scroll.y == 0) return;
        const has_rotation_modifier = ih.keyboard.activeKeysInclude(&[_]Key{ .LeftAlt, .RightAlt }, .Or);
        if (has_rotation_modifier) self.target += invertScroll(&ih.mouse.scroll).y * self.speed;
    }
};
