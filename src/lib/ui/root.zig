const std = @import("std");
const rl = @import("raylib");

const Props = struct {};

pub const UI = struct {
    pub fn deinit(self: *UI) void {
        _ = self;
    }

    pub fn init(props: Props) UI {
        _ = props;
        return UI{};
    }

    pub fn run(self: *UI) void {
        _ = self;
        rl.initWindow(800, 600, "LRC");
        defer rl.closeWindow();

        while (!rl.windowShouldClose()) {
            rl.beginDrawing();
            rl.clearBackground(rl.Color.white);
            rl.drawText("Hello, LRC!", 10, 10, 20, rl.Color.black);
            rl.endDrawing();
        }
    }
};
