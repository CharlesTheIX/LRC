const std = @import("std");
const utils = @import("./utils.zig");
const DateTime = @import("../date_time/root.zig").DateTime;
const createFile = @import("../../utils.zig").createFile;
const readFile = @import("../../utils.zig").readFile;
const writeFile = @import("../../utils.zig").writeFile;
const sliceToZSlice = @import("../../utils.zig").sliceToZSlice;

const Props = struct {
    io: *std.Io,
    allocator: *std.mem.Allocator,
    env_map: *std.process.Environ.Map,
    body_items: ?[]utils.BodyItem = null,
    feeding_items: ?[]utils.FeedingItem = null,
    body_items_file_path: []const u8 = ".lrc_database/body_items.z",
    feeding_items_file_path: []const u8 = ".lrc_database/feeding_items.z",
};

pub const BabyData = struct {
    io: *std.Io,
    body_items: ?[]utils.BodyItem,
    allocator: *std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    env_map: *std.process.Environ.Map,
    body_items_file_path: [:0]const u8,
    feeding_items: ?[]utils.FeedingItem,
    feeding_items_file_path: [:0]const u8,

    pub fn addBodyItem(self: *BabyData, item: utils.BodyItem, overwrite: bool) void {
        const arena = self.arena.allocator();
        if (self.body_items) |items| {
            var replaced = false;
            var new_items: std.ArrayList(utils.BodyItem) = .empty;
            for (items) |existing_item| {
                if (utils.sameBodyDateTime(self, existing_item, item)) {
                    if (!overwrite) return;
                    replaced = true;
                    new_items.append(arena, item) catch @panic("Failed to append overwritten body item");
                } else new_items.append(arena, existing_item) catch @panic("Failed to append existing body item");
            }
            if (!replaced) new_items.append(arena, item) catch @panic("Failed to append new body item");
            self.body_items = new_items.toOwnedSlice(arena) catch @panic("Failed to convert body items to owned slice");
        } else {
            var new_items: std.ArrayList(utils.BodyItem) = .empty;
            new_items.append(arena, item) catch @panic("Failed to append new body item");
            self.body_items = new_items.toOwnedSlice(arena) catch @panic("Failed to convert body items to owned slice");
        }
        utils.saveBodyItems(self);
    }

    pub fn addFeedingItem(self: *BabyData, item: utils.FeedingItem, overwrite: bool) void {
        const arena = self.arena.allocator();
        if (self.feeding_items) |items| {
            var replaced = false;
            var new_items: std.ArrayList(utils.FeedingItem) = .empty;
            for (items) |existing_item| {
                if (utils.sameFeedingDateTime(self, existing_item, item)) {
                    if (!overwrite) return;
                    replaced = true;
                    new_items.append(arena, item) catch @panic("Failed to append overwritten feeding item");
                } else new_items.append(arena, existing_item) catch @panic("Failed to append existing feeding item");
            }
            if (!replaced) new_items.append(arena, item) catch @panic("Failed to append new feeding item");
            self.feeding_items = new_items.toOwnedSlice(arena) catch @panic("Failed to convert feeding items to owned slice");
        } else {
            var new_items: std.ArrayList(utils.FeedingItem) = .empty;
            new_items.append(arena, item) catch @panic("Failed to append new feeding item");
            self.feeding_items = new_items.toOwnedSlice(arena) catch @panic("Failed to convert feeding items to owned slice");
        }
        utils.saveFeedingItems(self);
    }

    pub fn deinit(self: *BabyData) void {
        self.arena.deinit();
        self.allocator.free(self.body_items_file_path);
        self.allocator.free(self.feeding_items_file_path);
    }

    pub fn getBodyItemByIndex(self: *BabyData, index: usize) ?[]utils.BodyItem {
        const items = self.body_items orelse return null;
        for (items) |item| {
            if (item.index) |i| {
                if (i == index) return item;
            }
        }
        return null;
    }

    pub fn getBodyItemsByDateTime(self: *BabyData, date_time: utils.DateTime) ?[]utils.BodyItem {
        const arena = self.arena.allocator();
        const items = self.body_items orelse return null;
        var matching_items: std.ArrayList(utils.BodyItem) = .empty;
        for (items) |item| {
            if (item.date_time) |item_date_time| {
                const target_date = date_time.getDate();
                if (std.mem.eql(u8, item_date_time.getDate(), target_date)) matching_items.append(arena, item) catch @panic("Failed to append matching body item");
            }
        }
        if (matching_items.items.len == 0) return null;
        return matching_items.toOwnedSlice(arena) catch @panic("Failed to convert matching body items to owned slice");
    }

    pub fn getFeedingItemByIndex(self: *BabyData, index: usize) ?[]utils.BodyItem {
        const items = self.feeding_items orelse return null;
        for (items) |item| {
            if (item.index) |i| {
                if (i == index) return item;
            }
        }
        return null;
    }

    pub fn getFeedingItemsByDateTime(self: *BabyData, date_time: utils.DateTime) ?[]utils.FeedingItem {
        const arena = self.arena.allocator();
        const items = self.feeding_items orelse return null;
        var matching_items: std.ArrayList(utils.FeedingItem) = .empty;
        for (items) |item| {
            if (item.date_time) |item_date_time| {
                const target_date = date_time.getDate();
                if (std.mem.eql(u8, item_date_time.getDate(), target_date)) matching_items.append(arena, item) catch @panic("Failed to append matching body item");
            }
        }
        if (matching_items.items.len == 0) return null;
        return matching_items.toOwnedSlice(arena) catch @panic("Failed to convert matching feeding items to owned slice");
    }

    pub fn init(props: Props) BabyData {
        const body_items_file_path = sliceToZSlice(props.allocator, props.body_items_file_path) catch @panic("Failed to convert feeding items file path to Z slice");
        const feeding_items_file_path = sliceToZSlice(props.allocator, props.feeding_items_file_path) catch @panic("Failed to convert feeding items file path to Z slice");
        var baby_data = BabyData{
            .io = props.io,
            .env_map = props.env_map,
            .allocator = props.allocator,
            .body_items = props.body_items,
            .feeding_items = props.feeding_items,
            .body_items_file_path = body_items_file_path,
            .feeding_items_file_path = feeding_items_file_path,
            .arena = std.heap.ArenaAllocator.init(props.allocator.*),
        };
        baby_data.load();
        return baby_data;
    }

    pub fn load(self: *BabyData) void {
        utils.loadBodyData(self);
        utils.loadFeedingData(self);
    }

    pub fn logData(self: *BabyData) void {
        std.debug.print("Logging baby data:\n", .{});
        std.debug.print("Body items file path: {s}\n", .{self.body_items_file_path});
        std.debug.print("Feeding items file path: {s}\n", .{self.feeding_items_file_path});
        std.debug.print("Body items:\n", .{});
        if (self.body_items) |items| for (items) |item| std.debug.print("{any}\n", .{item});
        std.debug.print("Feeding items:\n", .{});
        if (self.feeding_items) |items| for (items) |item| std.debug.print("{any}\n", .{item});
    }

    pub fn updateBodyItem(self: *BabyData, index: usize, new_item: utils.BodyItem) void {
        const existing_item = self.getBodyItemByIndex(index);
        if (existing_item) self.body_items[index] = new_item;
    }

    pub fn updateFeedingItem(self: *BabyData, index: usize, new_item: utils.FeedingItem) void {
        const existing_item = self.getFeedingItemByIndex(index);
        if (existing_item) self.feeding_items[index] = new_item;
    }
};
