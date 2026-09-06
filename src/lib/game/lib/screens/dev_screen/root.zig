const std = @import("std");
const rl = @import("raylib");
const utils = @import("./utils.zig");
const Game = @import("../../../root.zig").Game;
const core_utils = @import("../../../utils.zig");
const Key = @import("../../input_handler/root.zig").Key;
const Click = @import("../../input_handler/root.zig").Click;
const InputHandler = @import("../../input_handler/root.zig").InputHandler;

const Props = struct { font: rl.Font, font_size: u32 = 32, allocator: *std.mem.Allocator };

pub const DevScreen = struct {
    font: rl.Font,
    font_size: u32,
    active: bool = false,
    allocator: *std.mem.Allocator,
    active_sub_screen: utils.DevSubScreen = .Home,
    number_active: [utils.number_keys.len]bool = @splat(false),
    number_pressed: [utils.number_keys.len]bool = @splat(false),

    // Base methods
    pub fn deinit(self: *DevScreen) void {
        _ = self;
    }

    pub fn draw(self: *DevScreen, game: *Game) void {
        if (!self.active) return;
        drawBackground();
        switch (self.active_sub_screen) {
            .Home => self.drawHome(),
            .SaveData => self.drawSaveData(game),
            .CoreGameDetails => self.drawCoreGameDetails(game),
        }
    }

    pub fn init(props: Props) DevScreen {
        return DevScreen{ .font = props.font, .font_size = props.font_size, .allocator = props.allocator };
    }

    pub fn load(self: *DevScreen) void {
        _ = self;
    }

    pub fn update(self: *DevScreen, game: *Game) void {
        self.updateNumberKeys(&game.input_handler);
        self.updateToggle(&game.input_handler);
        if (!self.active) return;
        switch (self.active_sub_screen) {
            .Home => {},
            .SaveData => self.updateSubScreen(game),
            .CoreGameDetails => self.updateSubScreen(game),
        }
    }

    // Helper methods
    fn drawBackground() void {
        const rect = rl.Rectangle.init(0, 0, @as(f32, @floatFromInt(rl.getScreenWidth())), @as(f32, @floatFromInt(rl.getScreenHeight())));
        rl.drawRectangleRec(rect, rl.Color.black.alpha(0.5));
    }

    fn drawCoreGameDetails(self: *DevScreen, game: *Game) void {
        utils.drawCoreGameDetails(self, game);
    }

    fn drawHome(self: *DevScreen) void {
        utils.drawHome(self);
    }

    fn drawSaveData(self: *DevScreen, game: *Game) void {
        utils.drawSaveData(self, game);
    }

    fn numberPressed(self: *DevScreen, key: Key) bool {
        for (utils.number_keys, 0..) |number_key, index| {
            if (number_key == key) return self.number_pressed[index];
        }
        return false;
    }

    fn updateNumberKeys(self: *DevScreen, input_handler: *InputHandler) void {
        const kb = &input_handler.keyboard;
        for (utils.number_keys, 0..) |key, index| {
            const active = kb.activeKeysInclude(&[_]Key{key}, .Or);
            // Keys stay active while held, so only act on the frame they become active.
            self.number_pressed[index] = active and !self.number_active[index];
            self.number_active[index] = active;
        }
    }

    fn updateSubScreen(self: *DevScreen, game: *Game) void {
        if (!self.active) return;
        const kb = game.input_handler.keyboard;
        if (!kb.activeKeysInclude(&[_]Key{ .LeftShift, .RightShift }, .Or)) return;
        switch (self.active_sub_screen) {
            .Home => {},
            .SaveData => {
                const save_data = &game.save_data;
                if (self.numberPressed(.One)) {
                    save_data.tempSave(game);
                    save_data.save();
                }
                if (self.numberPressed(.Two)) save_data.reset();
            },
            .CoreGameDetails => {
                const camera = &game.camera;
                if (self.numberPressed(.One)) {
                    switch (camera.state) {
                        .Free => camera.state = .Fixed,
                        .Follow => camera.state = .Free,
                        .Fixed => camera.state = .Follow,
                    }
                }
                if (self.numberPressed(.Two)) camera.snap_to_map = !camera.snap_to_map;
            },
        }
    }

    fn updateToggle(self: *DevScreen, input_handler: *InputHandler) void {
        const kb = &input_handler.keyboard;
        if (!kb.activeKeysInclude(&[_]Key{ .LeftControl, .RightControl }, .Or)) return;
        if (self.numberPressed(.Zero)) self.active = !self.active;
        if (!self.active) return;
        if (self.numberPressed(.One)) self.active_sub_screen = .Home;
        if (self.numberPressed(.Two)) self.active_sub_screen = .CoreGameDetails;
        if (self.numberPressed(.Three)) self.active_sub_screen = .SaveData;
    }
};
