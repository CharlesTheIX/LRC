// 2026-08-21:1700,breast partial,Pavla,First feeding of the day|1800,breast full,Pavla,Second feeding of the day:4:3:This is Les's first day of feeding
const std = @import("std");
const DateTime = @import("../date-time.zig").DateTime;
const createFile = @import("../utils.zig").createFile;
const readFile = @import("../utils.zig").readFile;
const writeFile = @import("../utils.zig").writeFile;

const FeedingType = enum {
    Breast_Partial,
    Breast_Full,
    Bottle_Breast_Partial,
    Bottle_Breast_Full,
    Bottle_Formula_Partial,
    Bottle_Formula_Full,
    Invalid,

    pub fn fromSlice(s: []const u8) FeedingType {
        if (std.mem.eql(u8, s, "breast partial")) return .Breast_Partial;
        if (std.mem.eql(u8, s, "breast full")) return .Breast_Full;
        if (std.mem.eql(u8, s, "bottle breast partial")) return .Bottle_Breast_Partial;
        if (std.mem.eql(u8, s, "bottle breast full")) return .Bottle_Breast_Full;
        if (std.mem.eql(u8, s, "bottle formula partial")) return .Bottle_Formula_Partial;
        if (std.mem.eql(u8, s, "bottle formula full")) return .Bottle_Formula_Full;
        return .Invalid;
    }

    pub fn toSlice(self: FeedingType) []const u8 {
        switch (self) {
            .Breast_Partial => return "breast partial",
            .Breast_Full => return "breast full",
            .Bottle_Breast_Partial => return "bottle breast partial",
            .Bottle_Breast_Full => return "bottle breast full",
            .Bottle_Formula_Partial => return "bottle formula partial",
            .Bottle_Formula_Full => return "bottle formula full",
            .Invalid => return "invalid",
        }
    }
};

const FeedingItem = struct {
    notes: []const u8,
    date_time: DateTime,
    feeding_type: FeedingType,
};

const FeedingData = struct {
    date: []const u8,
    urination_count: u6,
    day_note: []const u8,
    defecation_count: u6,
    feeding_items: []FeedingItem,
};

const FeedingProps = struct {
    io: *std.Io,
    env_map: *std.process.Environ.Map,
};

pub const Feeding = struct {
    io: *std.Io,
    env_map: *std.process.Environ.Map,
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

    pub fn init(props: FeedingProps) Feeding {
        const feeding = Feeding{ .io = props.io, .env_map = props.env_map };
        var file_exists = false;
        createFile(props.io, props.env_map, feeding.file_path) catch |err| switch (err) {
            error.PathAlreadyExists => file_exists = true,
            else => @panic("Failed to create feeding data file"),
        };
        if (!file_exists) {
            const content = "# FORMAT: date;feeding_time,feeding_type,feeding_feeder,feeding_notes;urinations;defecations;day_notes\n2026-08-21:1700,partial,David,First feeding of the day|1800,full,David,Second feeding of the day:4:3:This is Les's first day of feeding";
            writeFile(props.io, props.env_map, feeding.file_path, content) catch @panic("Failed to write initial feeding data file");
        }
        return feeding;
    }

    pub fn readAll(self: *Feeding, allocator: *std.mem.Allocator) ![]u8 {
        const content = readFile(self.io, self.env_map, allocator, self.file_path) catch |err| return err;
        return content;
    }

    pub fn readLine(self: *Feeding, allocator: *std.mem.Allocator, line_number: usize) ![]const u8 {
        const content = self.readAll(allocator) catch |err| return err;
        var content_it = std.mem.splitSequence(u8, content, "\n");
        var current_line: usize = 0;
        while (content_it.next()) |line| {
            if (line.len == 0) continue; // Skip empty lines
            if (line[0] == '#') continue; // Skip comment lines
            if (current_line == line_number) return line;
            current_line += 1;
        }
        return error.LineNotFound;
    }

    // pub fn writeAll(self: *Feeding, data: []const u8) !void {
    //     const cwd = std.Io.Dir.cwd();
    //     const file = cwd.createFile(self.file_path, .{}) catch return error.FileCreateFailed;
    //     file.writeAll(data) catch return error.FileWriteFailed;
    //     file.flush() catch return error.FlushFailed;
    // }

    // pub fn writeToNew(self: *Feeding, io: *std.Io, data: []const u8, file_path: []const u8) !void {
    //     _ = self;
    //     const cwd = std.Io.Dir.cwd();
    //     cwd.createDir(io.*, "data", .default_dir) catch |err| switch (err) {
    //         error.PathAlreadyExists => {},
    //         else => return error.DirCreateFailed,
    //     };
    //     const data_dir = cwd.openDir(io.*, "data", .{}) catch return error.DirCreateFailed;
    //     const file = data_dir.createFile(io.*, file_path, .{ .exclusive = true }) catch return error.FileCreateFailed;
    //     defer file.close(io.*);
    //     file.writeStreamingAll(io.*, data) catch return error.FileWriteFailed;
    // }
};
