const std = @import("std");
const BabyData = @import("./root.zig").BabyData;
const DateTime = @import("../date_time/root.zig").DateTime;
const createFile = @import("../../utils.zig").createFile;
const readFile = @import("../../utils.zig").readFile;
const writeFile = @import("../../utils.zig").writeFile;

// Enums
pub const Feeder = enum {
    Pavla,
    David,
    Other,
    Invalid,

    pub fn fromSlice(slice: []const u8) Feeder {
        if (std.mem.eql(u8, slice, "Pavla")) return .Pavla;
        if (std.mem.eql(u8, slice, "David")) return .David;
        if (std.mem.eql(u8, slice, "Other")) return .Other;
        return .Invalid;
    }

    pub fn toSlice(self: Feeder) []const u8 {
        switch (self) {
            .Pavla => return "Pavla",
            .David => return "David",
            .Other => return "Other",
            .Invalid => return "N/A",
        }
    }
};

pub const FeedingType = enum {
    Breast,
    Formula,
    BreastAndFormula,
    Invalid,

    pub fn fromSlice(slice: []const u8) FeedingType {
        if (std.mem.eql(u8, slice, "Breast")) return .Breast;
        if (std.mem.eql(u8, slice, "Formula")) return .Formula;
        if (std.mem.eql(u8, slice, "Breast and Formula")) return .BreastAndFormula;
        return .Invalid;
    }

    pub fn toSlice(self: FeedingType) []const u8 {
        switch (self) {
            .Breast => return "Breast",
            .Formula => return "Formula",
            .BreastAndFormula => return "Breast and Formula",
            .Invalid => return "N/A",
        }
    }
};

// Structs
pub const FeedingItem = struct {
    index: ?usize = null,
    amount_ml: ?u32 = null,
    feeder: Feeder = .Invalid,
    duration_sec: ?u32 = null,
    notes: ?[]const u8 = null,
    date_time: ?DateTime = null,
    feeding_type: FeedingType = .Invalid,

    pub fn fromSlice(slice: []const u8) FeedingItem {
        var item = FeedingItem{};
        var slice_it = std.mem.splitSequence(u8, slice, ";");
        while (slice_it.next()) |part| {
            var key_pair = std.mem.splitSequence(u8, part, "=");
            const key = key_pair.next() orelse continue;
            const value = key_pair.next() orelse continue;
            if (std.mem.eql(u8, key, "feeder")) item.feeder = Feeder.fromSlice(value);
            if (std.mem.eql(u8, key, "type")) item.feeding_type = FeedingType.fromSlice(value);
            if (std.mem.eql(u8, key, "notes")) item.notes = if (value.len == 0) null else value;
            if (std.mem.eql(u8, key, "date_time")) item.date_time = DateTime.initFromIsoString(value) catch null;
            if (std.mem.eql(u8, key, "amount_ml")) item.amount_ml = std.fmt.parseInt(u32, value, 10) catch null;
            if (std.mem.eql(u8, key, "duration_sec")) item.duration_sec = std.fmt.parseInt(u32, value, 10) catch null;
        }
        return item;
    }

    pub fn toSlice(self: FeedingItem, allocator: *std.mem.Allocator) ?[]u8 {
        var amount_buffer: [16]u8 = undefined;
        var duration_buffer: [16]u8 = undefined;
        const feeder_str: []const u8 = Feeder.toSlice(self.feeder);
        const notes_str: []const u8 = if (self.notes) |n| n else "N/A";
        const feeding_type_str: []const u8 = FeedingType.toSlice(self.feeding_type);
        const date_time_owned: ?[]u8 = if (self.date_time) |dt| (dt.toIsoString(allocator) catch return null) else null;
        defer if (date_time_owned) |d| allocator.free(d);
        const date_time_str: []const u8 = date_time_owned orelse "N/A";
        const amount_ml_str: []const u8 = if (self.amount_ml) |a| std.fmt.bufPrint(&amount_buffer, "{d}", .{a}) catch "N/A" else "N/A";
        const duration_sec_str: []const u8 = if (self.duration_sec) |d| std.fmt.bufPrint(&duration_buffer, "{d}", .{d}) catch "N/A" else "N/A";
        return std.fmt.allocPrint(
            allocator.*,
            "date_time={s};duration_sec={s};type={s};feeder={s};amount_ml={s};notes={s}",
            .{ date_time_str, duration_sec_str, feeding_type_str, feeder_str, amount_ml_str, notes_str },
        ) catch null;
    }
};

pub const BodyItem = struct {
    index: ?usize = null,
    weight_kg: ?f32 = null,
    urinations: ?u32 = null,
    defecations: ?u32 = null,
    notes: ?[]const u8 = null,
    date_time: ?DateTime = null,

    pub fn fromSlice(slice: []const u8) BodyItem {
        var item = BodyItem{};
        var slice_it = std.mem.splitSequence(u8, slice, ";");
        while (slice_it.next()) |part| {
            var key_pair = std.mem.splitSequence(u8, part, "=");
            const key = key_pair.next() orelse continue;
            const value = key_pair.next() orelse continue;
            if (std.mem.eql(u8, key, "notes")) item.notes = if (value.len == 0) null else value;
            if (std.mem.eql(u8, key, "date_time")) item.date_time = DateTime.initFromIsoString(value) catch null;
            if (std.mem.eql(u8, key, "weight_kg")) item.weight_kg = std.fmt.parseFloat(f32, value) catch null;
            if (std.mem.eql(u8, key, "urinations")) item.urinations = std.fmt.parseInt(u32, value, 10) catch null;
            if (std.mem.eql(u8, key, "defecations")) item.defecations = std.fmt.parseInt(u32, value, 10) catch null;
        }
        return item;
    }

    pub fn toSlice(self: BodyItem, allocator: *std.mem.Allocator) ?[]u8 {
        var weight_kg_buffer: [16]u8 = undefined;
        var urinations_buffer: [16]u8 = undefined;
        var defecations_buffer: [16]u8 = undefined;
        const notes_str: []const u8 = if (self.notes) |n| n else "N/A";
        const date_time_owned: ?[]u8 = if (self.date_time) |dt| (dt.toIsoString(allocator) catch return null) else null;
        defer if (date_time_owned) |d| allocator.free(d);
        const date_time_str: []const u8 = date_time_owned orelse "N/A";
        const weight_kg_str: []const u8 = if (self.weight_kg) |w| std.fmt.bufPrint(&weight_kg_buffer, "{.3f}", .{w}) catch "N/A" else "N/A";
        const urination_str: []const u8 = if (self.urinations) |u| std.fmt.bufPrint(&urinations_buffer, "{d}", .{u}) catch "N/A" else "N/A";
        const defecations_str: []const u8 = if (self.defecations) |d| std.fmt.bufPrint(&defecations_buffer, "{d}", .{d}) catch "N/A" else "N/A";
        return std.fmt.allocPrint(
            allocator.*,
            "date_time={s};urinations={s};defecations={s};weight_kg={s};notes={s}",
            .{ date_time_str, urination_str, defecations_str, weight_kg_str, notes_str },
        ) catch null;
    }
};

// Functions
pub fn extractBodyDataFromContent(baby_data: *BabyData, content: []const u8) void {
    var index: usize = 0;
    var entries: std.ArrayList(BodyItem) = .empty;
    const arena = baby_data.arena.allocator();
    var line_it = std.mem.splitSequence(u8, content, "\n");
    while (line_it.next()) |line| {
        if (line.len == 0) continue;
        if (line[0] == '#') continue;
        var entry = BodyItem.fromSlice(line);
        entry.index = index;
        entries.append(arena, entry) catch continue;
        index += 1;
    }
    baby_data.body_items = entries.toOwnedSlice(arena) catch @panic("Failed to convert body items to owned slice");
}

pub fn extractFeedingDataFromContent(baby_data: *BabyData, content: []const u8) void {
    var index: usize = 0;
    var entries: std.ArrayList(FeedingItem) = .empty;
    const arena = baby_data.arena.allocator();
    var line_it = std.mem.splitSequence(u8, content, "\n");
    while (line_it.next()) |line| {
        if (line.len == 0) continue;
        if (line[0] == '#') continue;
        var entry = FeedingItem.fromSlice(line);
        entry.index = index;
        entries.append(arena, entry) catch continue;
        index += 1;
    }
    baby_data.feeding_items = entries.toOwnedSlice(arena) catch @panic("Failed to convert feeding items to owned slice");
}

pub fn loadBodyData(baby_data: *BabyData) void {
    var body_file_exists = false;
    createFile(baby_data.io, baby_data.env_map, baby_data.body_items_file_path) catch |err| switch (err) {
        error.PathAlreadyExists => body_file_exists = true,
        else => @panic("Failed to create body items data file"),
    };
    if (!body_file_exists) {
        const example_content = "# FORMAT: date_time=2026-09-02T00:00:00;urinations=6;defecations=6;weight_kg=3.5;notes=N/A\n";
        writeFile(baby_data.io, baby_data.env_map, baby_data.body_items_file_path, example_content) catch @panic("Failed to write initial body items data file");
    }
    var arena_allocator = baby_data.arena.allocator();
    const body_content = readFile(baby_data.io, baby_data.env_map, &arena_allocator, baby_data.body_items_file_path) catch @panic("Failed to read body items data file");
    extractBodyDataFromContent(baby_data, body_content);
}

pub fn loadFeedingData(baby_data: *BabyData) void {
    var feeding_file_exists = false;
    createFile(baby_data.io, baby_data.env_map, baby_data.feeding_items_file_path) catch |err| switch (err) {
        error.PathAlreadyExists => feeding_file_exists = true,
        else => @panic("Failed to create feeding items data file"),
    };
    if (!feeding_file_exists) {
        const example_content = "# FORMAT: date_time=2026-09-02T00:00:00;duration_sec=30;type=breast;feeder=Pavla;notes=N/A\n";
        writeFile(baby_data.io, baby_data.env_map, baby_data.feeding_items_file_path, example_content) catch @panic("Failed to write initial feeding items data file");
    }
    var arena_allocator = baby_data.arena.allocator();
    const feeding_content = readFile(baby_data.io, baby_data.env_map, &arena_allocator, baby_data.feeding_items_file_path) catch @panic("Failed to read feeding items data file");
    extractFeedingDataFromContent(baby_data, feeding_content);
}

pub fn mergeBodyItemsFromDisk(baby_data: *BabyData) void {
    var arena_allocator = baby_data.arena.allocator();
    const disk_content = readFile(baby_data.io, baby_data.env_map, &arena_allocator, baby_data.body_items_file_path) catch return;
    const arena = baby_data.arena.allocator();
    var merged: std.ArrayList(BodyItem) = .empty;
    if (baby_data.body_items) |items| merged.appendSlice(arena, items) catch @panic("Failed to merge body items");
    var line_it = std.mem.splitSequence(u8, disk_content, "\n");
    while (line_it.next()) |line| {
        if (line.len == 0) continue;
        if (line[0] == '#') continue;
        const disk_item = BodyItem.fromSlice(line);
        var already_known = false;
        for (merged.items) |existing| {
            if (baby_data.sameBodyDateTime(existing, disk_item)) {
                already_known = true;
                break;
            }
        }
        if (!already_known) merged.append(arena, disk_item) catch @panic("Failed to merge body items");
    }
    baby_data.body_items = merged.toOwnedSlice(arena) catch @panic("Failed to convert body items to owned slice");
}

pub fn mergeFeedingItemsFromDisk(baby_data: *BabyData) void {
    var arena_allocator = baby_data.arena.allocator();
    const disk_content = readFile(baby_data.io, baby_data.env_map, &arena_allocator, baby_data.feeding_items_file_path) catch return;
    const arena = baby_data.arena.allocator();
    var merged: std.ArrayList(FeedingItem) = .empty;
    if (baby_data.feeding_items) |items| merged.appendSlice(arena, items) catch @panic("Failed to merge feeding items");
    var line_it = std.mem.splitSequence(u8, disk_content, "\n");
    while (line_it.next()) |line| {
        if (line.len == 0) continue;
        if (line[0] == '#') continue;
        const disk_item = FeedingItem.fromSlice(line);
        var already_known = false;
        for (merged.items) |existing| {
            if (baby_data.sameFeedingDateTime(existing, disk_item)) {
                already_known = true;
                break;
            }
        }
        if (!already_known) merged.append(arena, disk_item) catch @panic("Failed to merge feeding items");
    }
    baby_data.feeding_items = merged.toOwnedSlice(arena) catch @panic("Failed to convert feeding items to owned slice");
}

pub fn sameBodyDateTime(baby_data: *BabyData, a: BodyItem, b: BodyItem) bool {
    const a_dt = a.date_time orelse return false;
    const b_dt = b.date_time orelse return false;
    const a_iso = a_dt.toIsoString(baby_data.allocator) catch @panic("Failed to convert date_time to iso string");
    defer baby_data.allocator.free(a_iso);
    const b_iso = b_dt.toIsoString(baby_data.allocator) catch @panic("Failed to convert date_time to iso string");
    defer baby_data.allocator.free(b_iso);
    return std.mem.eql(u8, a_iso, b_iso);
}

pub fn sameFeedingDateTime(baby_data: *BabyData, a: FeedingItem, b: FeedingItem) bool {
    const a_dt = a.date_time orelse return false;
    const b_dt = b.date_time orelse return false;
    const a_iso = a_dt.toIsoString(baby_data.allocator) catch @panic("Failed to convert date_time to iso string");
    defer baby_data.allocator.free(a_iso);
    const b_iso = b_dt.toIsoString(baby_data.allocator) catch @panic("Failed to convert date_time to iso string");
    defer baby_data.allocator.free(b_iso);
    return std.mem.eql(u8, a_iso, b_iso);
}

pub fn saveBodyItems(baby_data: *BabyData) void {
    baby_data.mergeBodyItemsFromDisk();
    sortBodyItemsByDateTime(baby_data, true);
    const arena = baby_data.arena.allocator();
    var content: std.ArrayList(u8) = .empty;
    content.appendSlice(arena, "# FORMAT: date_time=2026-09-02T00:00:00;urinations=6;defecations=12;weight_kg=10;notes=N/A\n") catch @panic("Failed to build body items file content");
    if (baby_data.body_items) |items| {
        for (items) |item| {
            const line = item.toSlice(baby_data.allocator) orelse continue;
            defer baby_data.allocator.free(line);
            content.appendSlice(arena, line) catch @panic("Failed to build body items file content");
            content.append(arena, '\n') catch @panic("Failed to build body items file content");
        }
    }
    writeFile(baby_data.io, baby_data.env_map, baby_data.body_items_file_path, content.items) catch @panic("Failed to write body items data file");
}

pub fn saveFeedingItems(baby_data: *BabyData) void {
    baby_data.mergeFeedingItemsFromDisk();
    sortFeedingItemsByDateTime(baby_data, true);
    const arena = baby_data.arena.allocator();
    var content: std.ArrayList(u8) = .empty;
    content.appendSlice(arena, "# FORMAT: date_time=2026-09-02T00:00:00;duration_sec=30;type=breast;feeder=Pavla;notes=N/A\n") catch @panic("Failed to build feeding items file content");
    if (baby_data.feeding_items) |items| {
        for (items) |item| {
            const line = item.toSlice(baby_data.allocator) orelse continue;
            defer baby_data.allocator.free(line);
            content.appendSlice(arena, line) catch @panic("Failed to build feeding items file content");
            content.append(arena, '\n') catch @panic("Failed to build feeding items file content");
        }
    }
    writeFile(baby_data.io, baby_data.env_map, baby_data.feeding_items_file_path, content.items) catch @panic("Failed to write feeding items data file");
}

pub fn sortBodyItemsByDateTime(baby_data: *BabyData, ascending: bool) void {
    if (baby_data.body_items) |items| {
        std.sort.heap(items, ascending, struct {
            fn lessThan(is_ascending: bool, left: BodyItem, right: BodyItem) bool {
                if (left.date_time == null) return false;
                if (right.date_time == null) return true;
                if (is_ascending) return left.date_time.?.unix_seconds < right.date_time.?.unix_seconds;
                return left.date_time.?.unix_seconds > right.date_time.?.unix_seconds;
            }
        }.lessThan);
    }
}

pub fn sortFeedingItemsByDateTime(baby_data: *BabyData, ascending: bool) void {
    if (baby_data.feeding_items) |items| {
        std.sort.heap(items, ascending, struct {
            fn lessThan(is_ascending: bool, left: FeedingItem, right: FeedingItem) bool {
                if (left.date_time == null) return false;
                if (right.date_time == null) return true;
                if (is_ascending) return left.date_time.?.unix_seconds < right.date_time.?.unix_seconds;
                return left.date_time.?.unix_seconds > right.date_time.?.unix_seconds;
            }
        }.lessThan);
    }
}
