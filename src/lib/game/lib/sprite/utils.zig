const std = @import("std");
const rl = @import("raylib");

pub const Action = enum { Idle, Rest, Run, Walk };

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

    pub fn init() ActionData {
        return ActionData{};
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

const SpriteName = enum {
    Snorelax,
    Invalid,

    pub fn fromSlice(slice: []const u8) SpriteName {
        if (std.mem.eql(u8, slice, "Snorelax") or std.mem.eql(u8, slice, "snorelax")) return .Snorelax;
        return .Invalid;
    }

    pub fn getDataPath(self: SpriteName, buffer: []u8) ?[:0]u8 {
        if (self == .Invalid) return null;
        const path = std.fmt.bufPrintZ(buffer, "./assets/sprites/data/{s}.z", .{self.toSlice()}) catch @panic("Failed to format data path");
        return path;
    }

    pub fn getTexturePath(self: SpriteName, buffer: []u8) ?[:0]u8 {
        if (self == .Invalid) return null;
        const path = std.fmt.bufPrintZ(buffer, "./assets/sprites/textures/{s}.png", .{self.toSlice()}) catch @panic("Failed to format texture path");
        return path;
    }

    pub fn toSlice(self: SpriteName) []const u8 {
        return switch (self) {
            .Snorelax => "snorelax",
            .Invalid => "Invalid",
        };
    }
};

fn isDataKey(buf: []u8, key: []const u8, prefix: []const u8, suffix: []const u8) bool {
    const expected = std.fmt.bufPrint(buf, "{s}_{s}", .{ prefix, suffix }) catch return false;
    return std.mem.eql(u8, key, expected);
}

fn extractActionData(data: *ActionData, prefix: []const u8, key: []const u8, value: []const u8) void {
    var field_buf: [32]u8 = undefined;

    if (isDataKey(&field_buf, key, prefix, "speed")) data.speed = std.fmt.parseFloat(f32, value) catch null;
    if (isDataKey(&field_buf, key, prefix, "timeout")) data.timeout = std.fmt.parseFloat(f32, value) catch null;
    if (isDataKey(&field_buf, key, prefix, "frame_duration")) data.frame_duration = std.fmt.parseFloat(f32, value) catch null;
    if (isDataKey(&field_buf, key, prefix, "frame_count")) data.frame_count = std.fmt.parseInt(u8, value, 10) catch null;

    if (isDataKey(&field_buf, key, prefix, "spritesheet_offset")) {
        var values = std.mem.splitSequence(u8, value, ",");
        const x = std.fmt.parseFloat(f32, values.first()) catch 0;
        const y = std.fmt.parseFloat(f32, values.rest()) catch 0;
        data.spritesheet_offset = rl.Vector2.init(x, y);
    }

    if (isDataKey(&field_buf, key, prefix, "direction_offsets")) {
        var directions_it = std.mem.splitSequence(u8, value, ";");
        while (directions_it.next()) |direction| {
            var key_value = std.mem.splitSequence(u8, direction, "=");
            const dir_key = key_value.first();
            var values = std.mem.splitSequence(u8, key_value.rest(), ",");
            const x = std.fmt.parseFloat(f32, values.first()) catch @panic("Failed to parse x value for direction offset");
            const y = std.fmt.parseFloat(f32, values.rest()) catch @panic("Failed to parse y value for direction offset");
            const offset = rl.Vector2.init(x, y);
            if (std.mem.eql(u8, dir_key, "up")) data.directions.up = offset;
            if (std.mem.eql(u8, dir_key, "down")) data.directions.down = offset;
            if (std.mem.eql(u8, dir_key, "left")) data.directions.left = offset;
            if (std.mem.eql(u8, dir_key, "right")) data.directions.right = offset;
            if (std.mem.eql(u8, dir_key, "up_left")) data.directions.up_left = offset;
            if (std.mem.eql(u8, dir_key, "up_right")) data.directions.up_right = offset;
            if (std.mem.eql(u8, dir_key, "down_left")) data.directions.down_left = offset;
            if (std.mem.eql(u8, dir_key, "down_right")) data.directions.down_right = offset;
        }
    }

    if (isDataKey(&field_buf, key, prefix, "rects")) {
        var rects_it = std.mem.splitSequence(u8, value, ";");
        while (rects_it.next()) |rect| {
            var key_value = std.mem.splitSequence(u8, rect, "=");
            const rect_key = key_value.first();
            var values = std.mem.splitSequence(u8, key_value.rest(), ",");
            const x = std.fmt.parseFloat(f32, values.first()) catch 0;
            const y = std.fmt.parseFloat(f32, values.next() orelse "0") catch 0;
            const w = std.fmt.parseFloat(f32, values.next() orelse "0") catch 0;
            const h = std.fmt.parseFloat(f32, values.next() orelse "0") catch 0;
            const rect_val = rl.Rectangle.init(x, y, w, h);
            if (std.mem.eql(u8, rect_key, "core")) data.rects.core = rect_val;
            if (std.mem.eql(u8, rect_key, "upper")) data.rects.upper = rect_val;
            if (std.mem.eql(u8, rect_key, "lower")) data.rects.lower = rect_val;
            if (std.mem.eql(u8, rect_key, "hitbox")) data.rects.hitbox = rect_val;
        }
    }
}
