const std = @import("std");
const rl = @import("raylib");
const utils = @import("../../utils.zig");
const Game = @import("../../root.zig").Game;
const MenuItem = @import("./utils.zig").MenuItem;
const Key = @import("../input_handler/root.zig").Key;
const Click = @import("../input_handler/root.zig").Click;
const max_menu_items = @import("./utils.zig").max_menu_items;
const Cursor = @import("../input_handler/lib/cursor.zig").Cursor;

const Props = struct { font: rl.Font, font_size: u32 = 32, allocator: *std.mem.Allocator, color: rl.Color = .white, active_color: rl.Color = .white };

pub const Menu = struct {
    font: rl.Font,
    font_size: u32,
    color: rl.Color,
    item_count: usize = 0,
    active_color: rl.Color,
    active_index: usize = 0,
    up_active: bool = false,
    down_active: bool = false,
    click_active: bool = false,
    select_active: bool = false,
    allocator: *std.mem.Allocator,
    items: [max_menu_items]MenuItem = undefined,

    // Base methods
    pub fn deinit(self: *Menu) void {
        self.item_count = 0;
        self.items = undefined;
    }

    pub fn draw(self: *Menu) void {
        const spacing = utils.getCharSpacing(self.font_size);
        const font_size_f32 = utils.getFontSizeF32(self.font_size);
        for (0..self.item_count) |index| {
            const rect = self.itemRect(index);
            const is_active = index == self.active_index;
            const color = if (is_active) self.active_color else self.color;
            rl.drawTextEx(self.font, self.items[index].label, rl.Vector2{ .x = rect.x, .y = rect.y }, font_size_f32, spacing, color);
            if (!is_active) continue;
            const underline = rl.Rectangle{ .x = rect.x, .y = rect.y + rect.height + 2, .width = rect.width, .height = 2 };
            rl.drawRectangleRec(underline, color);
        }
    }

    pub fn init(props: Props) Menu {
        return Menu{
            .font = props.font,
            .color = props.color,
            .font_size = props.font_size,
            .allocator = props.allocator,
            .active_color = props.active_color,
        };
    }

    pub fn update(self: *Menu, game: *Game) void {
        if (self.item_count == 0) return;
        const mouse = game.input_handler.mouse;
        const kb = game.input_handler.keyboard;
        const up = kb.activeKeysInclude(&[_]Key{ .W, .Up }, .Or);
        const down = kb.activeKeysInclude(&[_]Key{ .S, .Down }, .Or);
        const select = kb.activeKeysInclude(&[_]Key{ .Enter, .Space }, .Or);
        const clicking = mouse.getActiveClicksInclude(&[_]Click{.Left}, .Or);
        // Keys/clicks stay active while held, so only act on the frame they become active.
        if (up and !self.up_active) self.selectPrevious();
        if (down and !self.down_active) self.selectNext();
        const hovered_index = self.itemAtPos(mouse.pos);
        if (hovered_index) |index| {
            self.active_index = index;
            Cursor.set(.PointingHand);
        }
        const clicked = clicking and !self.click_active and hovered_index != null;
        const key_selected = select and !self.select_active;
        self.up_active = up;
        self.down_active = down;
        self.select_active = select;
        self.click_active = clicking;
        if (clicked or key_selected) self.items[self.active_index].on_select(game);
    }

    // Helper methods
    pub fn addItem(self: *Menu, item: MenuItem) void {
        if (self.item_count >= max_menu_items) return;
        self.items[self.item_count] = item;
        self.item_count += 1;
    }

    pub fn clearItems(self: *Menu) void {
        self.item_count = 0;
        self.active_index = 0;
        // Treat inputs as held so a key/button carried over from the previous screen can't select twice.
        self.up_active = true;
        self.down_active = true;
        self.click_active = true;
        self.select_active = true;
    }

    fn itemAtPos(self: *Menu, pos: rl.Vector2) ?usize {
        for (0..self.item_count) |index| {
            if (rl.checkCollisionPointRec(pos, self.itemRect(index))) return index;
        }
        return null;
    }

    fn itemRect(self: *Menu, index: usize) rl.Rectangle {
        const font_size_f32 = utils.getFontSizeF32(self.font_size);
        const line_height = utils.getFontSizeF32(self.font_size) * 2;
        const center = utils.getCenterVector2OfRect(utils.getWindowRect());
        const total_height = @as(f32, @floatFromInt(self.item_count)) * line_height;
        const y = center.y - total_height / 2 + @as(f32, @floatFromInt(index)) * line_height;
        const size = rl.measureTextEx(self.font, self.items[index].label, font_size_f32, utils.getCharSpacing(self.font_size));
        return rl.Rectangle{ .x = center.x - size.x / 2, .y = y, .width = size.x, .height = font_size_f32 };
    }

    fn selectNext(self: *Menu) void {
        if (self.item_count == 0) return;
        self.active_index = (self.active_index + 1) % self.item_count;
    }

    fn selectPrevious(self: *Menu) void {
        if (self.item_count == 0) return;
        if (self.active_index == 0) {
            self.active_index = self.item_count - 1;
            return;
        }
        self.active_index -= 1;
    }
};
