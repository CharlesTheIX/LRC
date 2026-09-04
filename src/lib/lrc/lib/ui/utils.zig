const std = @import("std");

pub fn claimFocus(id: []const u8) void {
    focused_element = id;
}

pub fn clearFocus() void {
    focused_element = null;
}

pub var focused_element: ?[]const u8 = null;

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
