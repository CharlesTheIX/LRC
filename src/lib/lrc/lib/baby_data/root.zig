const std = @import("std");
const utils = @import("./utils.zig");
const core_utils = @import("../../utils.zig");

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

    // Base methods
    pub fn deinit(self: *BabyData) void {
        self.arena.deinit();
        self.allocator.free(self.body_items_file_path);
        self.allocator.free(self.feeding_items_file_path);
    }

    pub fn init(props: Props) BabyData {
        const body_items_file_path = core_utils.sliceToZSlice(props.allocator, props.body_items_file_path) catch @panic("Failed to convert feeding items file path to Z slice");
        const feeding_items_file_path = core_utils.sliceToZSlice(props.allocator, props.feeding_items_file_path) catch @panic("Failed to convert feeding items file path to Z slice");
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
        self.loadBodyData();
        self.loadFeedingData();
    }

    // Helper methods
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

    fn extractBodyDataFromContent(self: *BabyData, content: []const u8) void {
        var index: usize = 0;
        var entries: std.ArrayList(utils.BodyItem) = .empty;
        const arena = self.arena.allocator();
        var line_it = std.mem.splitSequence(u8, content, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) continue;
            if (line[0] == '#') continue;
            var entry = utils.BodyItem.fromSlice(line);
            entry.index = index;
            entries.append(arena, entry) catch continue;
            index += 1;
        }
        self.body_items = entries.toOwnedSlice(arena) catch @panic("Failed to convert body items to owned slice");
    }

    fn extractFeedingDataFromContent(self: *BabyData, content: []const u8) void {
        var index: usize = 0;
        var entries: std.ArrayList(utils.FeedingItem) = .empty;
        const arena = self.arena.allocator();
        var line_it = std.mem.splitSequence(u8, content, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) continue;
            if (line[0] == '#') continue;
            var entry = utils.FeedingItem.fromSlice(line);
            entry.index = index;
            entries.append(arena, entry) catch continue;
            index += 1;
        }
        self.feeding_items = entries.toOwnedSlice(arena) catch @panic("Failed to convert feeding items to owned slice");
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

    fn loadBodyData(self: *BabyData) void {
        var body_file_exists = false;
        core_utils.createFile(self.io, self.env_map, self.body_items_file_path) catch |err| switch (err) {
            error.PathAlreadyExists => body_file_exists = true,
            else => @panic("Failed to create body items data file"),
        };
        if (!body_file_exists) {
            const example_content = "# FORMAT: date_time=2026-09-02T00:00:00;urinations=6;defecations=6;weight_kg=3.5;notes=N/A\n";
            core_utils.writeFile(self.io, self.env_map, self.body_items_file_path, example_content) catch @panic("Failed to write initial body items data file");
        }
        var arena_allocator = self.arena.allocator();
        const body_content = core_utils.readFile(self.io, self.env_map, &arena_allocator, self.body_items_file_path) catch @panic("Failed to read body items data file");
        extractBodyDataFromContent(self, body_content);
    }

    fn loadFeedingData(self: *BabyData) void {
        var feeding_file_exists = false;
        core_utils.createFile(self.io, self.env_map, self.feeding_items_file_path) catch |err| switch (err) {
            error.PathAlreadyExists => feeding_file_exists = true,
            else => @panic("Failed to create feeding items data file"),
        };
        if (!feeding_file_exists) {
            const example_content = "# FORMAT: date_time=2026-09-02T00:00:00;duration_sec=30;type=breast;feeder=Pavla;notes=N/A\n";
            core_utils.writeFile(self.io, self.env_map, self.feeding_items_file_path, example_content) catch @panic("Failed to write initial feeding items data file");
        }
        var arena_allocator = self.arena.allocator();
        const feeding_content = core_utils.readFile(self.io, self.env_map, &arena_allocator, self.feeding_items_file_path) catch @panic("Failed to read feeding items data file");
        extractFeedingDataFromContent(self, feeding_content);
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

    fn mergeBodyItemsFromDisk(self: *BabyData) void {
        var arena_allocator = self.arena.allocator();
        const disk_content = core_utils.readFile(self.io, self.env_map, &arena_allocator, self.body_items_file_path) catch return;
        const arena = self.arena.allocator();
        var merged: std.ArrayList(utils.BodyItem) = .empty;
        if (self.body_items) |items| merged.appendSlice(arena, items) catch @panic("Failed to merge body items");
        var line_it = std.mem.splitSequence(u8, disk_content, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) continue;
            if (line[0] == '#') continue;
            const disk_item = utils.BodyItem.fromSlice(line);
            var already_known = false;
            for (merged.items) |existing| {
                if (self.sameBodyDateTime(existing, disk_item)) {
                    already_known = true;
                    break;
                }
            }
            if (!already_known) merged.append(arena, disk_item) catch @panic("Failed to merge body items");
        }
        self.body_items = merged.toOwnedSlice(arena) catch @panic("Failed to convert body items to owned slice");
    }

    fn mergeFeedingItemsFromDisk(self: *BabyData) void {
        var arena_allocator = self.arena.allocator();
        const disk_content = core_utils.readFile(self.io, self.env_map, &arena_allocator, self.feeding_items_file_path) catch return;
        const arena = self.arena.allocator();
        var merged: std.ArrayList(utils.FeedingItem) = .empty;
        if (self.feeding_items) |items| merged.appendSlice(arena, items) catch @panic("Failed to merge feeding items");
        var line_it = std.mem.splitSequence(u8, disk_content, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) continue;
            if (line[0] == '#') continue;
            const disk_item = utils.FeedingItem.fromSlice(line);
            var already_known = false;
            for (merged.items) |existing| {
                if (self.sameFeedingDateTime(existing, disk_item)) {
                    already_known = true;
                    break;
                }
            }
            if (!already_known) merged.append(arena, disk_item) catch @panic("Failed to merge feeding items");
        }
        self.feeding_items = merged.toOwnedSlice(arena) catch @panic("Failed to convert feeding items to owned slice");
    }

    fn sameBodyDateTime(self: *BabyData, a: utils.BodyItem, b: utils.BodyItem) bool {
        const a_dt = a.date_time orelse return false;
        const b_dt = b.date_time orelse return false;
        const a_iso = a_dt.toIsoString(self.allocator) catch @panic("Failed to convert date_time to iso string");
        defer self.allocator.free(a_iso);
        const b_iso = b_dt.toIsoString(self.allocator) catch @panic("Failed to convert date_time to iso string");
        defer self.allocator.free(b_iso);
        return std.mem.eql(u8, a_iso, b_iso);
    }

    fn sameFeedingDateTime(self: *BabyData, a: utils.FeedingItem, b: utils.FeedingItem) bool {
        const a_dt = a.date_time orelse return false;
        const b_dt = b.date_time orelse return false;
        const a_iso = a_dt.toIsoString(self.allocator) catch @panic("Failed to convert date_time to iso string");
        defer self.allocator.free(a_iso);
        const b_iso = b_dt.toIsoString(self.allocator) catch @panic("Failed to convert date_time to iso string");
        defer self.allocator.free(b_iso);
        return std.mem.eql(u8, a_iso, b_iso);
    }

    fn saveBodyItems(self: *BabyData) void {
        self.mergeBodyItemsFromDisk();
        sortBodyItemsByDateTime(self, true);
        const arena = self.arena.allocator();
        var content: std.ArrayList(u8) = .empty;
        content.appendSlice(arena, "# FORMAT: date_time=2026-09-02T00:00:00;urinations=6;defecations=12;weight_kg=10;notes=N/A\n") catch @panic("Failed to build body items file content");
        if (self.body_items) |items| {
            for (items) |item| {
                const line = item.toSlice(self.allocator) orelse continue;
                defer self.allocator.free(line);
                content.appendSlice(arena, line) catch @panic("Failed to build body items file content");
                content.append(arena, '\n') catch @panic("Failed to build body items file content");
            }
        }
        core_utils.writeFile(self.io, self.env_map, self.body_items_file_path, content.items) catch @panic("Failed to write body items data file");
    }

    fn saveFeedingItems(self: *BabyData) void {
        self.mergeFeedingItemsFromDisk();
        sortFeedingItemsByDateTime(self, true);
        const arena = self.arena.allocator();
        var content: std.ArrayList(u8) = .empty;
        content.appendSlice(arena, "# FORMAT: date_time=2026-09-02T00:00:00;duration_sec=30;type=breast;feeder=Pavla;notes=N/A\n") catch @panic("Failed to build feeding items file content");
        if (self.feeding_items) |items| {
            for (items) |item| {
                const line = item.toSlice(self.allocator) orelse continue;
                defer self.allocator.free(line);
                content.appendSlice(arena, line) catch @panic("Failed to build feeding items file content");
                content.append(arena, '\n') catch @panic("Failed to build feeding items file content");
            }
        }
        core_utils.writeFile(self.io, self.env_map, self.feeding_items_file_path, content.items) catch @panic("Failed to write feeding items data file");
    }

    fn sortBodyItemsByDateTime(self: *BabyData, ascending: bool) void {
        if (self.body_items) |items| {
            std.sort.heap(items, ascending, struct {
                fn lessThan(is_ascending: bool, left: utils.BodyItem, right: utils.BodyItem) bool {
                    if (left.date_time == null) return false;
                    if (right.date_time == null) return true;
                    if (is_ascending) return left.date_time.?.unix_seconds < right.date_time.?.unix_seconds;
                    return left.date_time.?.unix_seconds > right.date_time.?.unix_seconds;
                }
            }.lessThan);
        }
    }

    fn sortFeedingItemsByDateTime(self: *BabyData, ascending: bool) void {
        if (self.feeding_items) |items| {
            std.sort.heap(items, ascending, struct {
                fn lessThan(is_ascending: bool, left: utils.FeedingItem, right: utils.FeedingItem) bool {
                    if (left.date_time == null) return false;
                    if (right.date_time == null) return true;
                    if (is_ascending) return left.date_time.?.unix_seconds < right.date_time.?.unix_seconds;
                    return left.date_time.?.unix_seconds > right.date_time.?.unix_seconds;
                }
            }.lessThan);
        }
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
