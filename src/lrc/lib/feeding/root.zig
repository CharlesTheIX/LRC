const std = @import("std");
const utils = @import("./utils.zig");
const DateTime = @import("../date-time.zig").DateTime;
const createFile = @import("../utils.zig").createFile;
const readFile = @import("../utils.zig").readFile;
const writeFile = @import("../utils.zig").writeFile;

const Props = struct {
    io: *std.Io,
    allocator: *std.mem.Allocator,
    env_map: *std.process.Environ.Map,
};

pub const Feeding = struct {
    io: *std.Io,
    allocator: *std.mem.Allocator,
    env_map: *std.process.Environ.Map,
    data: ?[]utils.FeedingData = null,
    file_path: *const [23:0]u8 = ".lrc_database/feeding.z",

    pub fn deinit(self: *Feeding) void {
        _ = self;
    }

    /// Caller owns the returned slice (allocated with `allocator`).
    pub fn formatData(self: *Feeding, allocator: *std.mem.Allocator, data: []const u8) ![]u8 {
        _ = self;
        var arena_state = std.heap.ArenaAllocator.init(allocator.*);
        defer arena_state.deinit();
        const arena = arena_state.allocator();

        var formatted_data: std.ArrayList(u8) = .empty;
        const separator = "\n--------------------\n";
        var buffer_it = std.mem.splitSequence(u8, data, "\n");
        while (buffer_it.next()) |line| {
            if (line.len == 0) continue; // Skip empty lines
            if (line[0] == '#') continue; // Skip comment lines

            formatted_data.appendSlice(arena, separator) catch return error.BufferOverflow;

            var data_it = std.mem.splitSequence(u8, line, ";");
            const date_str = data_it.next() orelse return error.InvalidDataFormat;
            const date = std.mem.trim(u8, date_str, " \t");
            const date_formatted = std.fmt.allocPrint(arena, "\nDate: {s}\n", .{date}) catch return error.AllocFailed;

            const feed_data_str = data_it.next() orelse return error.InvalidDataFormat;
            const feed_data = std.mem.trim(u8, feed_data_str, " \t");

            var feed_data_list: std.ArrayList(u8) = .empty;
            var feed_data_it = std.mem.splitSequence(u8, feed_data, "|");
            while (feed_data_it.next()) |feed_entry| {
                var feed_entry_item_list: std.ArrayList(u8) = .empty;
                const feed_entry_trimmed = std.mem.trim(u8, feed_entry, " \t");
                var feed_entry_item_it = std.mem.splitSequence(u8, feed_entry_trimmed, ",");

                const time_str = feed_entry_item_it.next() orelse return error.InvalidDataFormat;
                const time = std.mem.trim(u8, time_str, " \t");
                const time_formatted = std.fmt.allocPrint(arena, "Time: {s}, ", .{time}) catch return error.AllocFailed;

                const feed_type_str = feed_entry_item_it.next() orelse return error.InvalidDataFormat;
                const feed_type = std.mem.trim(u8, feed_type_str, " \t");
                const feed_type_formatted = std.fmt.allocPrint(arena, "Type: {s}, ", .{feed_type}) catch return error.AllocFailed;

                const feeder_str = feed_entry_item_it.next() orelse return error.InvalidDataFormat;
                const feeder = std.mem.trim(u8, feeder_str, " \t");
                const feeder_formatted = std.fmt.allocPrint(arena, "Feeder: {s}, ", .{feeder}) catch return error.AllocFailed;

                const feed_notes_str = feed_entry_item_it.next() orelse "N/A";
                const feed_notes = std.mem.trim(u8, feed_notes_str, " \t");
                const feed_notes_formatted = std.fmt.allocPrint(arena, "Notes: {s}", .{feed_notes}) catch return error.AllocFailed;

                feed_entry_item_list.appendSlice(arena, time_formatted) catch return error.BufferOverflow;
                feed_entry_item_list.appendSlice(arena, feed_type_formatted) catch return error.BufferOverflow;
                feed_entry_item_list.appendSlice(arena, feeder_formatted) catch return error.BufferOverflow;
                feed_entry_item_list.appendSlice(arena, feed_notes_formatted) catch return error.BufferOverflow;

                const feed_entry_item_slice = feed_entry_item_list.toOwnedSlice(arena) catch return error.AllocFailed;
                const feed_entry_formatted = std.fmt.allocPrint(arena, "\t- {s}\n", .{feed_entry_item_slice}) catch return error.AllocFailed;
                feed_data_list.appendSlice(arena, feed_entry_formatted) catch return error.BufferOverflow;
            }

            const feed_data_slice = feed_data_list.toOwnedSlice(arena) catch return error.AllocFailed;
            const feed_data_formatted = std.fmt.allocPrint(arena, "Feed Data:\n{s}", .{feed_data_slice}) catch return error.AllocFailed;

            const urination_data_str = data_it.next() orelse return error.InvalidDataFormat;
            const urination_data = std.mem.trim(u8, urination_data_str, " \t");
            const urination_data_formatted = std.fmt.allocPrint(arena, "Urination Count: {s}\n", .{urination_data}) catch return error.AllocFailed;

            const defecation_data_str = data_it.next() orelse return error.InvalidDataFormat;
            const defecation_data = std.mem.trim(u8, defecation_data_str, " \t");
            const defecation_data_formatted = std.fmt.allocPrint(arena, "Defecation Count: {s}\n", .{defecation_data}) catch return error.AllocFailed;

            const day_note_str = data_it.next() orelse "N/A";
            const day_note = std.mem.trim(u8, day_note_str, " \t");
            const day_note_formatted = std.fmt.allocPrint(arena, "Day Note: {s}\n", .{day_note}) catch return error.AllocFailed;

            formatted_data.appendSlice(arena, date_formatted) catch return error.BufferOverflow;
            formatted_data.appendSlice(arena, urination_data_formatted) catch return error.BufferOverflow;
            formatted_data.appendSlice(arena, defecation_data_formatted) catch return error.BufferOverflow;
            formatted_data.appendSlice(arena, day_note_formatted) catch return error.BufferOverflow;
            formatted_data.appendSlice(arena, feed_data_formatted) catch return error.BufferOverflow;
            formatted_data.appendSlice(arena, separator) catch return error.BufferOverflow;
        }
        return allocator.dupe(u8, formatted_data.items) catch return error.AllocFailed;
    }

    pub fn init(props: Props) Feeding {
        var file_exists = false;
        var feeding = Feeding{ .io = props.io, .env_map = props.env_map, .allocator = props.allocator };
        createFile(props.io, props.env_map, feeding.file_path) catch |err| switch (err) {
            error.PathAlreadyExists => file_exists = true,
            else => @panic("Failed to create feeding data file"),
        };
        if (!file_exists) {
            const example_content = "# FORMAT: date;feeding_time,feeding_duration,feeding_type,feeding_feeder,feeding_notes;urinations;defecations;water_consumed;day_notes\n";
            writeFile(props.io, props.env_map, feeding.file_path, example_content) catch @panic("Failed to write initial feeding data file");
        }

        const content = readFile(props.io, props.env_map, props.allocator, feeding.file_path) catch @panic("Failed to read feeding data file");
        feeding.extractDataFromFile(content) catch @panic("Failed to parse feeding data file");
        return feeding;
    }

    /// Parses the raw file contents and stores the resulting entries in `self.data`.
    /// Lines that don't match the expected format are skipped rather than aborting the whole parse.
    fn extractDataFromFile(self: *Feeding, data: []const u8) !void {
        var entries: std.ArrayList(utils.FeedingData) = .empty;
        var line_it = std.mem.splitSequence(u8, data, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) continue; // Skip empty lines
            if (line[0] == '#') continue; // Skip comment lines

            const entry = self.parseLine(line) catch |err| {
                std.debug.print("Skipping malformed feeding entry ({}): {s}\n", .{ err, line });
                continue;
            };
            entries.append(self.allocator.*, entry) catch return error.AllocFailed;
        }

        self.data = entries.toOwnedSlice(self.allocator.*) catch return error.AllocFailed;
    }

    fn parseLine(self: *Feeding, line: []const u8) !utils.FeedingData {
        var field_it = std.mem.splitSequence(u8, line, ";");

        const date_str = field_it.next() orelse return error.InvalidDataFormat;
        const date = self.allocator.dupe(u8, std.mem.trim(u8, date_str, " \t")) catch return error.AllocFailed;

        const feed_data_str = field_it.next() orelse return error.InvalidDataFormat;
        const feed_data = std.mem.trim(u8, feed_data_str, " \t");

        var feeding_items: std.ArrayList(utils.FeedingItem) = .empty;
        var feed_entry_it = std.mem.splitSequence(u8, feed_data, "|");
        while (feed_entry_it.next()) |feed_entry| {
            const feed_entry_trimmed = std.mem.trim(u8, feed_entry, " \t");
            if (feed_entry_trimmed.len == 0) continue;

            var item_it = std.mem.splitSequence(u8, feed_entry_trimmed, ",");

            const time_str = item_it.next() orelse return error.InvalidDataFormat;
            const time = DateTime.initFromIsoString(std.mem.trim(u8, time_str, " \t")) catch return error.InvalidDataFormat;

            const duration_str = item_it.next() orelse return error.InvalidDataFormat;
            const duration = std.fmt.parseInt(u6, std.mem.trim(u8, duration_str, " \t"), 10) catch return error.InvalidDataFormat;

            const feed_type_str = item_it.next() orelse return error.InvalidDataFormat;
            const feeding_type = utils.FeedingType.fromSlice(std.mem.trim(u8, feed_type_str, " \t"));

            const feeder_str = item_it.next() orelse return error.InvalidDataFormat;
            const feeder = utils.FeedingFeeder.fromSlice(std.mem.trim(u8, feeder_str, " \t"));

            const notes_str = item_it.next() orelse "N/A";
            const notes = self.allocator.dupe(u8, std.mem.trim(u8, notes_str, " \t")) catch return error.AllocFailed;

            feeding_items.append(self.allocator.*, .{
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
        const day_notes = self.allocator.dupe(u8, std.mem.trim(u8, day_notes_str, " \t")) catch return error.AllocFailed;

        return .{
            .date = date,
            .day_notes = day_notes,
            .water_consumed = water_consumed,
            .urination_count = urination_count,
            .defecation_count = defecation_count,
            .feeding_items = feeding_items.toOwnedSlice(self.allocator.*) catch return error.AllocFailed,
        };
    }
};
