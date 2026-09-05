const std = @import("std");
const rl = @import("raylib");
const m = @import("./lib/mouse.zig");
const kb = @import("./lib/keyboard.zig");

pub const Key = kb.Key;
pub const Click = m.Click;
pub const Mouse = m.Mouse;
pub const Keyboard = kb.Keyboard;

const Props = struct { allocator: *std.mem.Allocator };

pub const InputHandler = struct {
    mouse: Mouse,
    keyboard: Keyboard,

    // Base methods
    pub fn init(props: Props) InputHandler {
        const mouse = Mouse.init(props.allocator);
        const keyboard = Keyboard.init(props.allocator);
        return InputHandler{ .mouse = mouse, .keyboard = keyboard };
    }

    pub fn deinit(self: *InputHandler) void {
        self.mouse.deinit();
        self.keyboard.deinit();
    }

    pub fn update(self: *InputHandler) void {
        self.mouse.update();
        self.keyboard.update();
    }
};
