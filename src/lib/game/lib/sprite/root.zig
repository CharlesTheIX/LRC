const std = @import("std");
const rl = @import("raylib");

const Pikachu = struct {
    base_speed: f32 = 100.0,
    sprint_speed: f32 = 200.0,
    texture_path: []const u8 = "./assets/sprites/pikachu.png",

    walk_frame_count: u8 = 4,
    walk_frame_duration: f32 = 0.12,
    rects: Rects = .{
        .core = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 28 },
        .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 12 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
        .lower = rl.Rectangle{ .x = 0, .y = 12, .width = 28, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
        .hitbox = rl.Rectangle{ .x = 7, .y = 17, .width = 13, .height = 7 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
    },

    pub fn init() Pikachu {
        return Pikachu{};
    }
};

const Scyther = struct {
    base_speed: f32 = 100.0,
    sprint_speed: f32 = 200.0,
    texture_path: []const u8 = "./assets/sprites/scyther.png",

    walk_frame_count: u8 = 4,
    walk_frame_duration: f32 = 0.12,
    rects: Rects = .{
        .core = rl.Rectangle{ .x = 0, .y = 0, .width = 34, .height = 31 },
        .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 34, .height = 15 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
        .lower = rl.Rectangle{ .x = 0, .y = 15, .width = 34, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
        .hitbox = rl.Rectangle{ .x = 9, .y = 12, .width = 15, .height = 10 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
    },

    pub fn init() Scyther {
        return Scyther{};
    }
};

const Snorelax = struct {
    base_speed: f32 = 100.0,
    sprint_speed: f32 = 200.0,
    texture_path: []const u8 = "./assets/sprites/snorelax.png",

    walk_frame_count: u8 = 4,
    walk_frame_duration: f32 = 0.12,
    rects: Rects = .{
        .core = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 33 },
        .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 17 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
        .lower = rl.Rectangle{ .x = 0, .y = 17, .width = 28, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
        .hitbox = rl.Rectangle{ .x = 4, .y = 17, .width = 20, .height = 13 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
    },

    pub fn init() Snorelax {
        return Snorelax{};
    }
};

pub const Pokemon = union(enum) {
    Pikachu: Pikachu,
    Scyther: Scyther,
    Snorelax: Snorelax,

    pub fn fromString(s: []const u8) Pokemon {
        if (std.mem.eql(u8, s, "pikachu")) return .{ .Pikachu = Pikachu.init() };
        if (std.mem.eql(u8, s, "scyther")) return .{ .Scyther = Scyther.init() };
        if (std.mem.eql(u8, s, "snorelax")) return .{ .Snorelax = Snorelax.init() };
        return .{ .Pikachu = Pikachu.init() };
    }
};

pub const Action = enum { Idle, Walk, Run };

pub const Direction = enum {
    Down,
    DownRight,
    Right,
    UpRight,
    Up,
    UpLeft,
    Left,
    DownLeft,

    pub fn fromVector(vector: rl.Vector2) Direction {
        if (vector.x > 0 and vector.y < 0) return .UpRight;
        if (vector.x < 0 and vector.y < 0) return .UpLeft;
        if (vector.x > 0 and vector.y > 0) return .DownRight;
        if (vector.x < 0 and vector.y > 0) return .DownLeft;
        if (vector.x > 0) return .Right;
        if (vector.x < 0) return .Left;
        if (vector.y < 0) return .Up;
        return .Down;
    }

    pub fn toString(self: Direction) []const u8 {
        switch (self) {
            .Up => return "Up",
            .Down => return "Down",
            .Left => return "Left",
            .Right => return "Right",
            .UpLeft => return "UpLeft",
            .UpRight => return "UpRight",
            .DownLeft => return "DownLeft",
            .DownRight => return "DownRight",
        }
    }
};

pub const Rects = struct { upper: rl.Rectangle, lower: rl.Rectangle, hitbox: rl.Rectangle, core: rl.Rectangle };

pub const WalkData = struct { current_frame: u8 = 0, frame_count: u8, frame_duration: f32, frame_elapsed: f32 = 0.0 };
