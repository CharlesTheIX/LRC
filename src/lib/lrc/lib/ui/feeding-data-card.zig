const std = @import("std");
const rl = @import("raylib");
const utils = @import("../feeding/utils.zig");
const sliceToZSlice = @import("../utils.zig").sliceToZSlice;

const Props = struct { font: rl.Font, font_size: i32, bg_color: rl.Color, txt_color: rl.Color, position: rl.Vector2, data: utils.FeedingData, allocator: *std.mem.Allocator };

pub const FeedingDataCard = struct {
    font: rl.Font,
    font_size: i32,
    text: []const u8,
    bg_color: rl.Color,
    rect: rl.Rectangle,
    txt_color: rl.Color,
    padding: rl.Vector2,
    visible: bool = true,
    data: utils.FeedingData,
    allocator: *std.mem.Allocator,

    pub fn deinit(self: *FeedingDataCard) void {
        self.allocator.free(self.text);
    }

    pub fn draw(self: *FeedingDataCard) void {
        if (!self.visible) return;
        rl.drawRectangleRec(self.rect, self.bg_color);
        const text_z = sliceToZSlice(self.allocator, self.text) catch "Failed to convert text to Z slice";
        defer self.allocator.free(text_z);
        rl.drawTextEx(self.font, text_z, .init(self.rect.x + self.padding.x, self.rect.y + self.padding.y), @as(f32, @floatFromInt(self.font_size)), 3, self.txt_color);
    }

    pub fn init(props: Props) FeedingDataCard {
        const text = formatFeedingData(props.allocator, props.data) catch @panic("Failed to format feeding data");
        const text_z = sliceToZSlice(props.allocator, text) catch "Failed to convert text to Z slice";
        defer props.allocator.free(text_z);
        const padding = rl.Vector2.init(10, 5);
        const text_size = rl.measureTextEx(props.font, text_z, @as(f32, @floatFromInt(props.font_size)), 3);
        const rect = rl.Rectangle.init(props.position.x, props.position.y, text_size.x + (2 * padding.x), text_size.y + (2 * padding.y));
        return FeedingDataCard{
            .rect = rect,
            .font = props.font,
            .padding = padding,
            .text = text,
            .bg_color = props.bg_color,
            .txt_color = props.txt_color,
            .data = props.data,
            .font_size = props.font_size,
            .allocator = props.allocator,
        };
    }

    pub fn update(self: *FeedingDataCard) void {
        _ = self;
    }
};

/// Caller owns the returned slice (allocated with `allocator`).
fn formatFeedingData(allocator: *std.mem.Allocator, data: utils.FeedingData) ![]u8 {
    var arena_state = std.heap.ArenaAllocator.init(allocator.*);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var text: std.ArrayList(u8) = .empty;
    const header = std.fmt.allocPrint(arena, "Date: {s}\n", .{data.date}) catch return error.AllocFailed;
    text.appendSlice(arena, header) catch return error.BufferOverflow;
    const counts = std.fmt.allocPrint(
        arena,
        "Urinations: {d}  Defecations: {d}  Water: {d}\n",
        .{ data.urination_count, data.defecation_count, data.water_consumed },
    ) catch return error.AllocFailed;
    text.appendSlice(arena, counts) catch return error.BufferOverflow;
    const notes = std.fmt.allocPrint(arena, "Notes: {s}\n", .{data.day_notes}) catch return error.AllocFailed;
    text.appendSlice(arena, notes) catch return error.BufferOverflow;
    text.appendSlice(arena, "Feedings:\n") catch return error.BufferOverflow;
    for (data.feeding_items) |item| {
        const item_line = std.fmt.allocPrint(
            arena,
            "  - {s}  {s}  {s}  {d}m  {s}\n",
            .{ item.time, item.feeding_type.toSlice(), item.feeder.toSlice(), item.duration, item.notes },
        ) catch return error.AllocFailed;
        text.appendSlice(arena, item_line) catch return error.BufferOverflow;
    }
    return allocator.dupe(u8, text.items) catch return error.AllocFailed;
}
