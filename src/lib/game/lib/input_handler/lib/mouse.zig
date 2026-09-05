const std = @import("std");
const rl = @import("raylib");
pub const Click = @import("./click.zig").Click;
pub const Cursor = @import("./cursor.zig").Cursor;

pub const Mouse = struct {
    pos: rl.Vector2,
    scroll: rl.Vector2,
    cursor: Cursor = .Default,
    next_click_press_order: u64,
    active_clicks: std.AutoHashMap(Click, u64),

    // Base methods
    pub fn deinit(self: *Mouse) void {
        self.active_clicks.deinit();
        self.next_click_press_order = 0;
    }

    pub fn init(allocator: *std.mem.Allocator) Mouse {
        const active_clicks = std.AutoHashMap(Click, u64).init(allocator.*);
        return Mouse{
            .next_click_press_order = 0,
            .pos = rl.getMousePosition(),
            .scroll = rl.getMouseWheelMoveV(),
            .active_clicks = active_clicks,
        };
    }

    pub fn update(self: *Mouse) void {
        self.pos = rl.getMousePosition();
        self.scroll = rl.getMouseWheelMoveV();
        for (Click.array()) |click| {
            const is_down = rl.isMouseButtonDown(click.toRL());
            if (is_down) {
                if (self.active_clicks.get(click) == null) {
                    self.next_click_press_order += 1;
                    _ = self.active_clicks.put(click, self.next_click_press_order) catch {};
                }
            } else _ = self.active_clicks.remove(click);
        }
    }

    // Helper methods
    pub fn getActiveClicksInclude(self: Mouse, clicks: []const Click, filter: enum { And, Or }) bool {
        switch (filter) {
            .And => {
                for (clicks) |click| {
                    if (self.active_clicks.get(click) == null) return false;
                }
                return true;
            },
            .Or => {
                for (clicks) |click| {
                    if (self.active_clicks.get(click) != null) return true;
                }
                return false;
            },
        }
    }

    pub fn getClickPressOrderIndex(self: Mouse, click: Click) ?u64 {
        return self.active_clicks.get(click);
    }

    pub fn getMostRecentlyPressedClick(self: Mouse) ?Click {
        var most_recent_time: u64 = 0;
        var most_recent_click: ?Click = null;
        var it = self.active_clicks.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.* > most_recent_time) {
                most_recent_click = entry.key_ptr.*;
                most_recent_time = entry.value_ptr.*;
            }
        }
        return most_recent_click;
    }
};
