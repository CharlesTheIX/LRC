const std = @import("std");
const rl = @import("raylib");
const Zoom = @import("./lib/zoom.zig").Zoom;
const Movement = @import("./lib/movement.zig").Movement;
const Rotation = @import("./lib/rotation.zig").Rotation;
const InputHandler = @import("../input_handler/root.zig").InputHandler;

const Props = struct { offset: rl.Vector2 };

pub const Camera = struct {
    zoom: Zoom,
    movement: Movement,
    rotation: Rotation,
    camera2D: rl.Camera2D,
    snap_to_map: bool = false,
    state: CameraState = .Free,

    // Base methods
    pub fn deinit(self: *Camera) void {
        _ = self;
    }

    pub fn init(props: Props) Camera {
        const zoom = Zoom.init();
        const rotation = Rotation.init();
        const movement = Movement.init(rl.Vector2.init(0, 0));
        return .{
            .zoom = zoom,
            .movement = movement,
            .rotation = rotation,
            .camera2D = rl.Camera2D{ .zoom = zoom.target, .rotation = rotation.target, .target = movement.target, .offset = props.offset },
        };
    }

    pub fn update(self: *Camera, ih: *InputHandler, target: ?rl.Vector2, map_rect: ?*rl.Rectangle) void {
        switch (self.state) {
            .Fixed => return,
            .Free => {
                self.zoom.update(&self.camera2D, ih);
                self.movement.update(&self.camera2D, ih);
                if (!self.snap_to_map) {
                    self.rotation.update(&self.camera2D, ih);
                } else {
                    if (map_rect) |rect| self.snapToMap(rect);
                }
                return;
            },
            .Follow => {
                self.zoom.update(&self.camera2D, ih);
                if (target) |t| {
                    self.movement.target = t;
                } else self.movement.target = self.camera2D.target;
                const diff = self.movement.target.subtract(self.camera2D.target);
                const diff_scaled = diff.scale(self.movement.lerp_speed);
                self.camera2D.target = self.camera2D.target.add(diff_scaled);
                if (map_rect) |rect| self.snapToMap(rect);
                return;
            },
        }
    }

    // Helper methods
    pub fn resize(self: *Camera, offset: rl.Vector2) void {
        self.load(offset);
    }

    pub fn setTarget(self: *Camera, target: rl.Vector2) void {
        self.camera2D.target = target;
        self.movement.target = target;
    }

    fn snapToMap(self: *Camera, map_rect: *rl.Rectangle) void {
        if (!self.snap_to_map) return;
        const zoom = @max(self.camera2D.zoom, 0.0001);
        const screen_w = @as(f32, @floatFromInt(rl.getScreenWidth()));
        const screen_h = @as(f32, @floatFromInt(rl.getScreenHeight()));
        const top_extent = self.camera2D.offset.y / zoom;
        const left_extent = self.camera2D.offset.x / zoom;
        const right_extent = (screen_w - self.camera2D.offset.x) / zoom;
        const bottom_extent = (screen_h - self.camera2D.offset.y) / zoom;
        var min_x = map_rect.x + left_extent;
        var min_y = map_rect.y + top_extent;
        var max_x = map_rect.x + map_rect.width - right_extent;
        var max_y = map_rect.y + map_rect.height - bottom_extent;
        if (min_x > max_x) {
            const center_x = map_rect.x + (map_rect.width * 0.5);
            min_x = center_x;
            max_x = center_x;
        }
        if (min_y > max_y) {
            const center_y = map_rect.y + (map_rect.height * 0.5);
            min_y = center_y;
            max_y = center_y;
        }
        self.camera2D.target.x = std.math.clamp(self.camera2D.target.x, min_x, max_x);
        self.camera2D.target.y = std.math.clamp(self.camera2D.target.y, min_y, max_y);
        self.movement.target.x = std.math.clamp(self.movement.target.x, min_x, max_x);
        self.movement.target.y = std.math.clamp(self.movement.target.y, min_y, max_y);
    }
};

pub const CameraState = enum {
    Free,
    Fixed,
    Follow,

    pub fn toString(self: CameraState) []const u8 {
        return switch (self) {
            .Free => "Free",
            .Fixed => "Fixed",
            .Follow => "Follow",
        };
    }
};
