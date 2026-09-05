const std = @import("std");
const rl = @import("raylib");
const Key = @import("../../input_handler/root.zig").Key;
const InputHandler = @import("../../input_handler/root.zig").InputHandler;
const invertScroll = @import("../../../utils.zig").invertScroll;

pub const Zoom = struct {
    min: f32 = 1.0,
    max: f32 = 10.0,
    speed: f32 = 0.1,
    target: f32 = 3.0,
    lerp_speed: f32 = 0.1,

    pub fn init() Zoom {
        return .{};
    }

    pub fn deinit(self: *Zoom) void {
        _ = self;
    }

    fn setTarget(self: *Zoom, value: f32) void {
        self.target = std.math.clamp(value, self.min, self.max);
    }

    pub fn update(self: *Zoom, camera: *rl.Camera2D, ih: *InputHandler) void {
        self.updateFromInput(camera, ih);
        self.updateFromScroll(camera, ih);
    }

    fn updateFromInput(self: *Zoom, camera: *rl.Camera2D, ih: *InputHandler) void {
        const zoom_out = ih.keyboard.activeKeysInclude(&[_]Key{.Minus}, .And);
        const zoom_in = ih.keyboard.activeKeysInclude(&[_]Key{.Equal}, .And);
        if (zoom_in) self.setTarget(self.target + self.speed);
        if (zoom_out) self.setTarget(self.target - self.speed);
        const zoom_diff = self.target - camera.zoom;
        if (@abs(zoom_diff) > 0.001) {
            camera.zoom += zoom_diff * self.lerp_speed;
        } else camera.zoom = self.target;
    }

    fn updateFromScroll(self: *Zoom, camera: *rl.Camera2D, ih: *InputHandler) void {
        if (ih.mouse.scroll.y == 0) return;
        if (ih.keyboard.activeKeysInclude(&[_]Key{ .LeftShift, .RightShift }, .Or)) {
            self.setTarget(self.target + invertScroll(&ih.mouse.scroll).y * self.speed);
            camera.zoom = self.target;
        }
    }
};
