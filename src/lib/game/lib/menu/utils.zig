const Game = @import("../../root.zig").Game;

pub const max_menu_items: usize = 12;

pub const MenuItem = struct {
    label: [:0]const u8,
    on_select: *const fn (game: *Game) void,
};
