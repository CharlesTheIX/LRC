const std = @import("std");
const rl = @import("raylib");

// Consts
pub var focused_element: ?[]const u8 = null;

// Enums
pub const ColorTheme = enum {
    Theme_1,
    Theme_2,
    Invalid,

    pub fn colorSet(self: ColorTheme) ColorSet {
        return switch (self) {
            .Theme_1 => ColorSet{
                .primary = rl.Color.init(24, 58, 55, 255),
                .secondary = rl.Color.init(239, 214, 172, 255),
                .highlight = rl.Color.init(196, 73, 0, 255),
                .err = rl.Color.init(255, 0, 0, 255),
            },
            .Theme_2 => ColorSet{
                .primary = rl.Color.init(24, 58, 55, 255),
                .secondary = rl.Color.init(239, 214, 172, 255),
                .highlight = rl.Color.init(196, 73, 0, 255),
                .err = rl.Color.init(255, 0, 0, 255),
            },
            .Invalid => ColorSet{
                .primary = rl.Color.black,
                .secondary = rl.Color.white,
                .highlight = rl.Color.green,
                .err = rl.Color.red,
            },
        };
    }

    pub fn fromSlice(slice: []const u8) ColorTheme {
        if (std.mem.eql(u8, slice, "theme_1")) return .Theme_1;
        if (std.mem.eql(u8, slice, "theme_2")) return .Theme_2;
        return .Invalid;
    }

    pub fn toSlice(self: ColorTheme) []const u8 {
        return switch (self) {
            .Theme_1 => "theme_1",
            .Theme_2 => "theme_2",
            .Invalid => "invalid",
        };
    }
};

// Structs
pub const ColorSet = struct { primary: rl.Color, secondary: rl.Color, highlight: rl.Color, err: rl.Color };

pub const Title = struct { font_size: u32, pos: rl.Vector2, text: []const u8 };

// Functions
pub fn claimFocus(id: []const u8) void {
    focused_element = id;
}

pub fn clearFocus() void {
    focused_element = null;
}

pub fn getCharSpacing(font_size: u32) f32 {
    var spacing = @divFloor(font_size, 8);
    if (spacing < 1) spacing = 1;
    return @as(f32, @floatFromInt(spacing));
}

pub fn hasFocus(id: []const u8) bool {
    return focused_element != null and std.mem.eql(u8, focused_element.?, id);
}

pub fn isBlockedByFocusedElement(id: []const u8) bool {
    return focused_element != null and !std.mem.eql(u8, focused_element.?, id);
}
