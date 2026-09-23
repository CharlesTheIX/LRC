const std = @import("std");
const rl = @import("raylib");
const readFile = @import("../../utils.zig").readFile;
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

pub const Action = enum {
    // Idle,
    Run,
    Sleep,
    Walk,
    Wake,
};

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

pub const Pokemon = union(enum) {
    Pikachu: Pikachu,
    Scyther: Scyther,
    Snorelax: Snorelax,

    pub fn actionData(self: *const Pokemon, action: Action) ?ActionData {
        return switch (self.*) {
            .Pikachu => |pokemon| switch (action) {
                .Run => pokemon.run_data,
                .Walk => pokemon.walk_data,
                .Wake => pokemon.wake_data,
                .Sleep => pokemon.sleep_data,
                // .Idle => pokemon.idle_data,
            },
            .Scyther => |pokemon| switch (action) {
                .Wake => null,
                .Sleep => null,
                .Run => pokemon.run_data,
                .Walk => pokemon.walk_data,
                // .Idle => pokemon.idle_data,
            },
            .Snorelax => |pokemon| switch (action) {
                .Run => pokemon.run_data,
                .Walk => pokemon.walk_data,
                .Wake => pokemon.wake_data,
                .Sleep => pokemon.sleep_data,
                // .Idle => pokemon.idle_data,
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

const Pikachu = struct {
    texture_path: []const u8 = "./assets/sprites/textures/pikachu.png",
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
        .frame_duration = 0.5,
        .spritesheet_offset = rl.Vector2.init(0, 224),
        .directions = .{
            .left = rl.Vector2.init(0, 28),
            .right = rl.Vector2.init(0, 0),
        },
        .rects = .{
            .core = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 28 },
            .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 12 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
            .lower = rl.Rectangle{ .x = 0, .y = 12, .width = 28, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
            .hitbox = rl.Rectangle{ .x = 6, .y = 11, .width = 13, .height = 7 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
        },
    },
    wake_data: ?ActionData = .{
        .speed = null,
        .timeout = null,
        .frame_count = 5,
        .frame_duration = 0.5,
        .spritesheet_offset = rl.Vector2.init(0, 280),
        .directions = .{
            .left = rl.Vector2.init(0, 28),
            .right = rl.Vector2.init(0, 0),
        },
        .rects = .{
            .core = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 28 },
            .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 12 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
            .lower = rl.Rectangle{ .x = 0, .y = 12, .width = 28, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
            .hitbox = rl.Rectangle{ .x = 6, .y = 11, .width = 13, .height = 7 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
        },
    },
    // idle_data: ?ActionData = .{
    //     .speed = null,
    //     .timeout = 5.0,
    //     .frame_count = 4,
    //     .frame_duration = 0.12,
    //     .spritesheet_offset = rl.Vector2.init(0, 224),
    //     .directions = .{
    //         .left = rl.Vector2.init(0, 28),
    //         .right = rl.Vector2.init(0, 0),
    //     },
    //     .rects = .{
    //         .core = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 28 },
    //         .upper = rl.Rectangle{ .x = 0, .y = 0, .width = 28, .height = 12 }, // the x and y values are offsets for the upper part of the sprite, relative to the core rectangle
    //         .lower = rl.Rectangle{ .x = 0, .y = 12, .width = 28, .height = 16 }, // the x and y values are offsets for the lower part of the sprite, relative to the core rectangle
    //         .hitbox = rl.Rectangle{ .x = 7, .y = 17, .width = 13, .height = 7 }, // the x and y values are offsets for the hitbox, relative to the core rectangle
    //     },
    // },

    pub fn init() Pikachu {
        return Pikachu{};
    }
};

const Scyther = struct {
    texture_path: []const u8 = "./assets/sprites/textures/scyther.png",
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
    wake_data: ?Action = null,
    // idle_data: ?ActionData = null,

    pub fn init() Scyther {
        return Scyther{};
    }
};

const Snorelax = struct {
    texture_path: []const u8 = "./assets/sprites/textures/snorelax.png",
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
    wake_data: ?ActionData = null,
    // idle_data: ?ActionData = null,

    pub fn init() Snorelax {
        return Snorelax{};
    }
};

const SpriteName = enum {
    Snorelax,
    Invalid,

    pub fn fromSlice(slice: []const u8) SpriteName {
        if (std.mem.eql(u8, slice, "Snorelax") or std.mem.eql(u8, slice, "snorelax")) return .Snorelax;
        return .Invalid;
    }

    pub fn getDataPath(self: SpriteName) ?[]const u8 {
        return switch (self) {
            .Snorelax => "./assets/sprites/data/snorelax.z",
            .Invalid => null,
        };
    }

    pub fn getTexturePath(self: SpriteName) ?[]const u8 {
        return switch (self) {
            .Snorelax => "./assets/sprites/textures/snorelax.png",
            .Invalid => null,
        };
    }
};

const Props = struct { name: []const u8, allocator: *std.mem.Allocator, io: *std.Io, env_map: ?[]const u8 };
const Sprite = struct {
    name: SpriteName,
    texture: ?rl.Texture2D,
    run_data: ?ActionData = null,
    idle_data: ?ActionData = null,
    rest_data: ?ActionData = null,
    walk_data: ?ActionData = null,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *Sprite) void {
        if (self.texture) |tex| {
            rl.unloadTexture(tex);
            self.texture = null;
        }
    }

    pub fn init(props: Props) Sprite {
        const sprite = Sprite{ .name = SpriteName.fromSlice(props.name), .allocator = props.allocator };
        sprite.load(props.io, props.env_map);
        return sprite;
    }

    fn load(self: *Sprite, io: *std.Io, env_map: *std.process.Environ.Map) void {
        const texture_path = self.name.getTexturePath();
        if (texture_path) |path| {
            const texture_path_z = sliceToZSlice(self.allocator, path) catch @panic("Failed to convert texture path to Z slice");
            defer self.allocator.free(texture_path_z);
            self.texture = rl.loadTexture(path) catch @panic("Failed to load texture");
        }

        const data_path = self.name.getDataPath();
        if (data_path) |path| {
            const content = readFile(io, env_map, self.allocator, path) catch @panic("Failed to read file");
            defer self.allocator.free(content);
            self.extractData(content);
        }
    }

    fn extractData(self: *Sprite, content: []const u8) void {
        // Implement data extraction logic here
        _ = self;
        _ = content;
    }
};
