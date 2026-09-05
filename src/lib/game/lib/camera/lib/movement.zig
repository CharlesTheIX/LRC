const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../../utils.zig");
const Key = @import("../../input_handler/root.zig").Key;
const Click = @import("../../input_handler/root.zig").Click;
const InputHandler = @import("../../input_handler/root.zig").InputHandler;

pub const Movement = struct {
    lerp_speed: f32 = 0.1,
    movement_speed: f32 = 32.0,
    target_position: rl.Vector2,
    mouse_pan_start: rl.Vector2,
    mouse_pan_target: rl.Vector2,
    mouse_pan_active: bool = false,

    pub fn init(v: rl.Vector2) Movement {
        return .{ .target_position = v, .mouse_pan_start = v, .mouse_pan_target = v };
    }

    pub fn deinit(self: *Movement) void {
        _ = self;
    }

    pub fn update(self: *Movement, camera: *rl.Camera2D, ih: *InputHandler) void {
        self.updateFromScroll(camera, ih);
        self.updateFromClick(camera, ih);
        if (!self.mouse_pan_active) self.updateFromInput(camera, ih);
    }

    fn updateFromClick(self: *Movement, camera: *rl.Camera2D, ih: *InputHandler) void {
        const mouse = ih.mouse;
        const kb = ih.keyboard;
        if (mouse.getActiveClicksInclude(&[_]Click{.Left}, .And)) {
            if (!kb.activeKeysInclude(&[_]Key{ .LeftShift, .RightShift }, .Or)) return;
            const mouse_pos = mouse.pos;
            if (!self.mouse_pan_active) {
                self.mouse_pan_active = true;
                self.mouse_pan_start = mouse_pos;
                self.mouse_pan_target = camera.target;
            } else {
                var delta = mouse_pos.subtract(self.mouse_pan_start);
                delta = utils.rotateVector(delta, -camera.rotation);
                self.target_position = self.mouse_pan_target.subtract(delta.scale(1.0 / camera.zoom));
            }
        } else self.mouse_pan_active = false;

        const diff = self.target_position.subtract(camera.target);
        camera.target = camera.target.add(diff.scale(self.lerp_speed));
    }

    fn updateFromInput(self: *Movement, camera: *rl.Camera2D, ih: *InputHandler) void {
        const kb = ih.keyboard;
        var speed = self.movement_speed;
        var movement = rl.Vector2.zero();
        if (kb.activeKeysInclude(&[_]Key{ .LeftShift, .RightShift }, .Or)) speed *= 4;
        if (kb.activeKeysInclude(&[_]Key{ .W, .Up }, .Or)) movement.y -= 1;
        if (kb.activeKeysInclude(&[_]Key{ .S, .Down }, .Or)) movement.y += 1;
        if (kb.activeKeysInclude(&[_]Key{ .A, .Left }, .Or)) movement.x -= 1;
        if (kb.activeKeysInclude(&[_]Key{ .D, .Right }, .Or)) movement.x += 1;
        if (movement.x == 0 and movement.y == 0) return;
        movement = utils.rotateVector(movement, -camera.rotation);
        movement = movement.scale(speed * self.lerp_speed / camera.zoom);
        self.target_position = self.target_position.add(movement);
    }

    fn updateFromScroll(self: *Movement, camera: *rl.Camera2D, ih: *InputHandler) void {
        const kb = ih.keyboard;
        if (kb.activeKeysInclude(&[_]Key{ .LeftShift, .RightShift }, .Or)) return;
        var movement = utils.invertScroll(&ih.mouse.scroll);
        movement = utils.rotateVector(movement, -camera.rotation);
        movement = movement.scale(self.movement_speed * self.lerp_speed / camera.zoom);
        self.target_position = self.target_position.add(movement);
    }
};
