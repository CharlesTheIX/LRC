const rl = @import("raylib");

pub const Cursor = enum {
    Arrow,
    Ibeam,
    Default,
    ResizeEW,
    ResizeNS,
    Crosshair,
    ResizeALL,
    ResizeNWSE,
    ResizeNESW,
    NotAllowed,
    PointingHand,

    pub fn array() []const Cursor {
        return &[_]Cursor{ .Arrow, .Ibeam, .Default, .ResizeEW, .ResizeNS, .Crosshair, .ResizeALL, .ResizeNWSE, .ResizeNESW, .NotAllowed, .PointingHand };
    }

    pub fn fromInt(value: u8) ?Cursor {
        return switch (value) {
            0 => .Arrow,
            1 => .Ibeam,
            2 => .Default,
            3 => .ResizeEW,
            4 => .ResizeNS,
            5 => .Crosshair,
            6 => .ResizeALL,
            7 => .ResizeNWSE,
            8 => .ResizeNESW,
            9 => .NotAllowed,
            10 => .PointingHand,
            else => null,
        };
    }

    pub fn fromRL(rlCursor: rl.MouseCursor) ?Cursor {
        return switch (rlCursor) {
            .arrow => .Arrow,
            .ibeam => .Ibeam,
            .default => .Default,
            .resize_ew => .ResizeEW,
            .resize_ns => .ResizeNS,
            .crosshair => .Crosshair,
            .resize_all => .ResizeALL,
            .resize_nwse => .ResizeNWSE,
            .resize_nesw => .ResizeNESW,
            .not_allowed => .NotAllowed,
            .pointing_hand => .PointingHand,
            else => null,
        };
    }

    pub fn hide() void {
        rl.hideCursor();
    }

    pub fn set(cursor: Cursor) void {
        rl.setMouseCursor(cursor.toRL());
    }

    pub fn show() void {
        rl.showCursor();
    }

    pub fn toInt(self: Cursor) u8 {
        return @intFromEnum(self);
    }

    pub fn toRL(self: Cursor) rl.MouseCursor {
        return switch (self) {
            .Arrow => .arrow,
            .Ibeam => .ibeam,
            .Default => .default,
            .ResizeEW => .resize_ew,
            .ResizeNS => .resize_ns,
            .Crosshair => .crosshair,
            .ResizeALL => .resize_all,
            .ResizeNWSE => .resize_nwse,
            .ResizeNESW => .resize_nesw,
            .NotAllowed => .not_allowed,
            .PointingHand => .pointing_hand,
        };
    }

    pub fn toString(self: Cursor) []const u8 {
        return switch (self) {
            .Arrow => "Arrow",
            .Ibeam => "I-beam",
            .Default => "Default",
            .ResizeEW => "Resize EW",
            .ResizeNS => "Resize NS",
            .Crosshair => "Crosshair",
            .ResizeALL => "Resize All",
            .ResizeNWSE => "Resize NW-SE",
            .ResizeNESW => "Resize NE-SW",
            .NotAllowed => "Not Allowed",
            .PointingHand => "Pointing Hand",
        };
    }
};
