const std = @import("std");
const rl = @import("raylib");
pub const Key = @import("./key.zig").Key;

pub const Keyboard = struct {
    next_key_press_order: u64,
    active_keys: std.AutoHashMap(Key, u64),

    // Base methods
    pub fn deinit(self: *Keyboard) void {
        self.active_keys.deinit();
        self.next_key_press_order = 0;
    }

    pub fn init(allocator: *std.mem.Allocator) Keyboard {
        const active_keys = std.AutoHashMap(Key, u64).init(allocator.*);
        return Keyboard{
            .next_key_press_order = 0,
            .active_keys = active_keys,
        };
    }

    pub fn update(self: *Keyboard) void {
        var pressed_key = rl.getKeyPressed();
        while (pressed_key != .null) : (pressed_key = rl.getKeyPressed()) {
            const key = Key.fromRL(pressed_key) orelse continue;
            if (self.active_keys.get(key) != null) continue;
            self.next_key_press_order += 1;
            _ = self.active_keys.put(key, self.next_key_press_order) catch {};
        }
        for (Key.array()) |key| {
            const is_down = rl.isKeyDown(key.toRL());
            if (is_down) {
                if (self.active_keys.get(key) == null) {
                    self.next_key_press_order += 1;
                    _ = self.active_keys.put(key, self.next_key_press_order) catch {};
                }
            } else _ = self.active_keys.remove(key);
        }
    }

    // Helper methods
    pub fn activeKeyIndex(self: Keyboard, key: Key) ?u64 {
        return self.active_keys.get(key);
    }

    pub fn activeKeysInclude(self: Keyboard, keys: []const Key, filter: enum { And, Or }) bool {
        switch (filter) {
            .And => {
                for (keys) |key| {
                    if (self.active_keys.get(key) == null) return false;
                }
                return true;
            },
            .Or => {
                for (keys) |key| {
                    if (self.active_keys.get(key) != null) return true;
                }
                return false;
            },
        }
    }

    pub fn mostRecentActiveKey(self: Keyboard) ?Key {
        var most_recent_time: u64 = 0;
        var most_recent_key: ?Key = null;
        var it = self.active_keys.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.* > most_recent_time) {
                most_recent_key = entry.key_ptr.*;
                most_recent_time = entry.value_ptr.*;
            }
        }
        return most_recent_key;
    }
};
