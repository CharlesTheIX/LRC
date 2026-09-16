const std = @import("std");
const rl = @import("raylib");

pub const Action = enum { Idle, Run, Sleep, Walk };

pub const ActionDirectionOffsets = struct {
    up: ?rl.Vector2 = null,
    down: ?rl.Vector2 = null,
    left: ?rl.Vector2 = null,
    right: ?rl.Vector2 = null,
    up_left: ?rl.Vector2 = null,
    up_right: ?rl.Vector2 = null,
    down_left: ?rl.Vector2 = null,
    down_right: ?rl.Vector2 = null,
};

pub const ActionRects = struct { core: ?rl.Rectangle = null, upper: ?rl.Rectangle = null, lower: ?rl.Rectangle = null, hitbox: ?rl.Rectangle = null };

pub const ActionData = struct {
    speed: ?f32 = null,
    timeout: ?f32 = null,
    frame_count: ?u8 = null,
    rects: ActionRects = .{},
    frame_duration: ?f32 = null,
    spritesheet_offset: ?rl.Vector2 = null,
    directions: ActionDirectionOffsets = .{},
};

const Pikachu = struct {
    texture_path: []const u8 = "./assets/sprites/pikachu.png",
    walk_data: ?ActionData = .{
        .speed = 100.0,
        .timeout = 5.0,
        .frame_count = 4,
        .frame_duration = 0.12,
        .spritesheet_offset = rl.Vector2.zero(),
        .directions = .{
            .up = rl.Vector2.init(0, 112),
            .down = rl.Vector2.init(0, 0),
            .left = rl.Vector2.init(0, 168),
            .right = rl.Vector2.init(0, 56),
            .up_left = rl.Vector2.init(0, 140),
            .up_right = rl.Vector2.init(0, 84),
            .down_left = rl.Vector2.init(0, 196),
            .down_right = rl.Vector2.init(0, 28),
        },
        .rects = .{
            .core = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 28 },
            .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 12 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
            .lower = rl.Rectangle{ .x = 0, .y = 12, .width = 28, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
            .hitbox = rl.Rectangle{ .x = 7, .y = 17, .width = 13, .height = 7 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
        },
    },
    run_data: ?ActionData = .{
        .speed = 200.0,
        .timeout = null,
        .frame_count = 4,
        .frame_duration = 0.12,
        .spritesheet_offset = rl.Vector2.zero(),
        .directions = .{
            .up = rl.Vector2.init(0, 112),
            .down = rl.Vector2.init(0, 0),
            .left = rl.Vector2.init(0, 168),
            .right = rl.Vector2.init(0, 56),
            .up_left = rl.Vector2.init(0, 140),
            .up_right = rl.Vector2.init(0, 84),
            .down_left = rl.Vector2.init(0, 196),
            .down_right = rl.Vector2.init(0, 28),
        },
        .rects = .{
            .core = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 28 },
            .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 12 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
            .lower = rl.Rectangle{ .x = 0, .y = 12, .width = 28, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
            .hitbox = rl.Rectangle{ .x = 7, .y = 17, .width = 13, .height = 7 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
        },
    },
    sleep_data: ?ActionData = .{
        .speed = null,
        .timeout = null,
        .frame_count = 4,
        .frame_duration = 0.05,
        .spritesheet_offset = rl.Vector2.init(0, 224),
        .directions = .{
            .left = rl.Vector2.init(0, 28),
            .right = rl.Vector2.init(0, 0),
        },
        .rects = .{
            .core = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 28 },
            .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 12 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
            .lower = rl.Rectangle{ .x = 0, .y = 12, .width = 28, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
            .hitbox = rl.Rectangle{ .x = 7, .y = 17, .width = 13, .height = 7 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
        },
    },
    idle_data: ?ActionData = .{
        .speed = null,
        .timeout = 5.0,
        .frame_count = 4,
        .frame_duration = 0.12,
        .spritesheet_offset = rl.Vector2.init(0, 224),
        .directions = .{
            .left = rl.Vector2.init(0, 28),
            .right = rl.Vector2.init(0, 0),
        },
        .rects = .{
            .core = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 28 },
            .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 12 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
            .lower = rl.Rectangle{ .x = 0, .y = 12, .width = 28, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
            .hitbox = rl.Rectangle{ .x = 7, .y = 17, .width = 13, .height = 7 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
        },
    },

    pub fn init() Pikachu {
        return Pikachu{};
    }
};

const Scyther = struct {
    texture_path: []const u8 = "./assets/sprites/scyther.png",
    walk_data: ActionData = .{
        .speed = 100.0,
        .timeout = null,
        .frame_count = 4,
        .frame_duration = 0.12,
        .spritesheet_offset = rl.Vector2.zero(),
        .directions = .{
            .up = rl.Vector2.init(0, 112),
            .down = rl.Vector2.init(0, 0),
            .left = rl.Vector2.init(0, 168),
            .right = rl.Vector2.init(0, 56),
            .up_left = rl.Vector2.init(0, 140),
            .up_right = rl.Vector2.init(0, 84),
            .down_left = rl.Vector2.init(0, 196),
            .down_right = rl.Vector2.init(0, 28),
        },
        .rects = .{
            .core = rl.Rectangle{ .x = 0, .y = 0, .width = 34, .height = 31 },
            .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 34, .height = 15 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
            .lower = rl.Rectangle{ .x = 0, .y = 15, .width = 34, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
            .hitbox = rl.Rectangle{ .x = 9, .y = 12, .width = 15, .height = 10 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
        },
    },
    run_data: ActionData = .{
        .speed = 200.0,
        .timeout = null,
        .frame_count = 4,
        .frame_duration = 0.12,
        .spritesheet_offset = rl.Vector2.zero(),
        .directions = .{
            .up = rl.Vector2.init(0, 112),
            .down = rl.Vector2.init(0, 0),
            .left = rl.Vector2.init(0, 168),
            .right = rl.Vector2.init(0, 56),
            .up_left = rl.Vector2.init(0, 140),
            .up_right = rl.Vector2.init(0, 84),
            .down_left = rl.Vector2.init(0, 196),
            .down_right = rl.Vector2.init(0, 28),
        },
        .rects = .{
            .core = rl.Rectangle{ .x = 0, .y = 0, .width = 34, .height = 31 },
            .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 34, .height = 15 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
            .lower = rl.Rectangle{ .x = 0, .y = 15, .width = 34, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
            .hitbox = rl.Rectangle{ .x = 9, .y = 12, .width = 15, .height = 10 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
        },
    },
    sleep_data: ?Action = null,
    idle_data: ?ActionData = null,

    pub fn init() Scyther {
        return Scyther{};
    }
};

const Snorelax = struct {
    texture_path: []const u8 = "./assets/sprites/snorelax.png",
    walk_data: ?ActionData = .{
        .speed = 100.0,
        .timeout = null,
        .frame_count = 4,
        .frame_duration = 0.12,
        .spritesheet_offset = rl.Vector2.zero(),
        .directions = .{
            .up = rl.Vector2.init(0, 112),
            .down = rl.Vector2.init(0, 0),
            .left = rl.Vector2.init(0, 168),
            .right = rl.Vector2.init(0, 56),
            .up_left = rl.Vector2.init(0, 140),
            .up_right = rl.Vector2.init(0, 84),
            .down_left = rl.Vector2.init(0, 196),
            .down_right = rl.Vector2.init(0, 28),
        },
        .rects = .{
            .core = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 33 },
            .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 17 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
            .lower = rl.Rectangle{ .x = 0, .y = 17, .width = 28, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
            .hitbox = rl.Rectangle{ .x = 4, .y = 17, .width = 20, .height = 13 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
        },
    },
    run_data: ?ActionData = .{
        .speed = 200.0,
        .timeout = null,
        .frame_count = 4,
        .frame_duration = 0.12,
        .spritesheet_offset = rl.Vector2.zero(),
        .directions = .{
            .up = rl.Vector2.init(0, 112),
            .down = rl.Vector2.init(0, 0),
            .left = rl.Vector2.init(0, 168),
            .right = rl.Vector2.init(0, 56),
            .up_left = rl.Vector2.init(0, 140),
            .up_right = rl.Vector2.init(0, 84),
            .down_left = rl.Vector2.init(0, 196),
            .down_right = rl.Vector2.init(0, 28),
        },
        .rects = .{
            .core = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 33 },
            .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 17 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
            .lower = rl.Rectangle{ .x = 0, .y = 17, .width = 28, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
            .hitbox = rl.Rectangle{ .x = 4, .y = 17, .width = 20, .height = 13 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
        },
    },
    sleep_data: ?ActionData = null,
    idle_data: ?ActionData = null,

    pub fn init() Snorelax {
        return Snorelax{};
    }
};

pub const Pokemon = union(enum) {
    Pikachu: Pikachu,
    Scyther: Scyther,
    Snorelax: Snorelax,

    pub fn actionData(self: *const Pokemon, action: Action) ?ActionData {
        return switch (self.*) {
            .Pikachu => |pokemon| switch (action) {
                .Walk => pokemon.walk_data,
                .Run => pokemon.run_data,
                .Sleep => pokemon.sleep_data,
                else => pokemon.walk_data,
            },
            .Scyther => |pokemon| switch (action) {
                .Walk => pokemon.walk_data,
                .Run => pokemon.run_data,
                .Sleep => null,
                else => pokemon.walk_data,
            },
            .Snorelax => |pokemon| switch (action) {
                .Walk => pokemon.walk_data,
                .Run => pokemon.run_data,
                .Sleep => pokemon.sleep_data,
                else => pokemon.walk_data,
            },
        };
    }

    pub fn fromString(s: []const u8) Pokemon {
        if (std.mem.eql(u8, s, "pikachu")) return .{ .Pikachu = Pikachu.init() };
        if (std.mem.eql(u8, s, "scyther")) return .{ .Scyther = Scyther.init() };
        if (std.mem.eql(u8, s, "snorelax")) return .{ .Snorelax = Snorelax.init() };
        return .{ .Pikachu = Pikachu.init() };
    }
};

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
