const std = @import("std");
const utils = @import("./utils.zig");
const DateTime = @import("../date_time/root.zig").DateTime;
const createFile = @import("../utils.zig").createFile;
const readFile = @import("../utils.zig").readFile;
const writeFile = @import("../utils.zig").writeFile;

const Props = struct { io: *std.Io, allocator: *std.mem.Allocator, env_map: *std.process.Environ.Map };

pub const Feeding = struct {
    io: *std.Io,
    allocator: *std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    env_map: *std.process.Environ.Map,
    data: ?[]utils.FeedingData = null,
    file_path: *const [23:0]u8 = ".lrc_database/feeding.z",

    pub fn deinit(self: *Feeding) void {
        self.arena.deinit();
    }

    pub fn init(props: Props) Feeding {
        var file_exists = false;
        var feeding = Feeding{ .io = props.io, .env_map = props.env_map, .allocator = props.allocator, .arena = std.heap.ArenaAllocator.init(props.allocator.*) };
        createFile(props.io, props.env_map, feeding.file_path) catch |err| switch (err) {
            error.PathAlreadyExists => file_exists = true,
            else => @panic("Failed to create feeding data file"),
        };
        if (!file_exists) {
            const example_content = "# FORMAT: date;feeding_time,feeding_duration,feeding_type,feeding_feeder,feeding_notes;urinations;defecations;water_consumed;day_notes\n";
            writeFile(props.io, props.env_map, feeding.file_path, example_content) catch @panic("Failed to write initial feeding data file");
        }
        const content = readFile(props.io, props.env_map, props.allocator, feeding.file_path) catch @panic("Failed to read feeding data file");
        defer props.allocator.free(content);
        feeding.extractDataFromFile(content) catch @panic("Failed to parse feeding data file");
        return feeding;
    }

    fn extractDataFromFile(self: *Feeding, data: []const u8) !void {
        const arena = self.arena.allocator();
        var entries: std.ArrayList(utils.FeedingData) = .empty;
        var line_it = std.mem.splitSequence(u8, data, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) continue; // Skip empty lines
            if (line[0] == '#') continue; // Skip comment lines
            const entry = parseLine(arena, line) catch continue;
            entries.append(arena, entry) catch return error.AllocFailed;
        }
        self.data = entries.toOwnedSlice(arena) catch return error.AllocFailed;
    }

    pub fn getLastFeedingDateTime(self: *Feeding) ?DateTime {
        if (self.data) |data| {
            if (data.len == 0) return null;
            const last_entry = data[data.len - 1];
            const last_feeding_item = self.getLastFeedingItem() orelse return null;
            var buffer: [64]u8 = undefined;
            const last_feeding_time_date = last_entry.date;
            const last_feeding_time = last_feeding_item.time;
            const last_feeding_time_date_str = std.fmt.bufPrint(&buffer, "{s}T{s}", .{ last_feeding_time_date, last_feeding_time }) catch return null;
            const date_time = DateTime.initFromIsoString(last_feeding_time_date_str) catch return null;
            return date_time;
        }
        return null;
    }

    fn getLastFeedingItem(self: *Feeding) ?utils.FeedingItem {
        if (self.data) |data| {
            if (data.len == 0) return null;
            const last_entry = data[data.len - 1];
            const last_entry_feeding_items = last_entry.feeding_items;
            if (last_entry_feeding_items.len == 0) return null;
            return last_entry_feeding_items[last_entry_feeding_items.len - 1];
        }
        return null;
    }

    fn parseLine(arena: std.mem.Allocator, line: []const u8) !utils.FeedingData {
        var field_it = std.mem.splitSequence(u8, line, ";");
        const date_str = field_it.next() orelse return error.InvalidDataFormat;
        const date = arena.dupe(u8, std.mem.trim(u8, date_str, " \t")) catch return error.AllocFailed;
        const feed_data_str = field_it.next() orelse return error.InvalidDataFormat;
        const feed_data = std.mem.trim(u8, feed_data_str, " \t");
        var feeding_items: std.ArrayList(utils.FeedingItem) = .empty;
        var feed_entry_it = std.mem.splitSequence(u8, feed_data, "|");
        while (feed_entry_it.next()) |feed_entry| {
            const feed_entry_trimmed = std.mem.trim(u8, feed_entry, " \t");
            if (feed_entry_trimmed.len == 0) continue;
            var item_it = std.mem.splitSequence(u8, feed_entry_trimmed, ",");
            const time_str = item_it.next() orelse return error.InvalidDataFormat;
            const time = arena.dupe(u8, std.mem.trim(u8, time_str, " \t")) catch return error.AllocFailed;
            const duration_str = item_it.next() orelse return error.InvalidDataFormat;
            const duration = std.fmt.parseInt(u6, std.mem.trim(u8, duration_str, " \t"), 10) catch return error.InvalidDataFormat;
            const feed_type_str = item_it.next() orelse return error.InvalidDataFormat;
            const feeding_type = utils.FeedingType.fromSlice(std.mem.trim(u8, feed_type_str, " \t"));
            const feeder_str = item_it.next() orelse return error.InvalidDataFormat;
            const feeder = utils.FeedingFeeder.fromSlice(std.mem.trim(u8, feeder_str, " \t"));
            const notes_str = item_it.next() orelse "N/A";
            const notes = arena.dupe(u8, std.mem.trim(u8, notes_str, " \t")) catch return error.AllocFailed;
            feeding_items.append(arena, .{
                .duration = duration,
                .time = time,
                .notes = notes,
                .feeder = feeder,
                .feeding_type = feeding_type,
            }) catch return error.AllocFailed;
        }
        const urination_str = field_it.next() orelse return error.InvalidDataFormat;
        const urination_count = std.fmt.parseInt(u6, std.mem.trim(u8, urination_str, " \t"), 10) catch return error.InvalidDataFormat;
        const defecation_str = field_it.next() orelse return error.InvalidDataFormat;
        const defecation_count = std.fmt.parseInt(u6, std.mem.trim(u8, defecation_str, " \t"), 10) catch return error.InvalidDataFormat;
        const water_str = field_it.next() orelse return error.InvalidDataFormat;
        const water_consumed = std.fmt.parseInt(u6, std.mem.trim(u8, water_str, " \t"), 10) catch return error.InvalidDataFormat;
        const day_notes_str = field_it.next() orelse "N/A";
        const day_notes = arena.dupe(u8, std.mem.trim(u8, day_notes_str, " \t")) catch return error.AllocFailed;
        return .{
            .date = date,
            .day_notes = day_notes,
            .water_consumed = water_consumed,
            .urination_count = urination_count,
            .defecation_count = defecation_count,
            .feeding_items = feeding_items.toOwnedSlice(arena) catch return error.AllocFailed,
        };
    }
};
