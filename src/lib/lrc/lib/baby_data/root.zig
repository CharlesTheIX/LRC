const std = @import("std");
const DateTime = @import("../date_time/root.zig").DateTime;
const createFile = @import("../utils.zig").createFile;
const readFile = @import("../utils.zig").readFile;
const writeFile = @import("../utils.zig").writeFile;
const sliceToZSlice = @import("../utils.zig").sliceToZSlice;

const Feeder = enum {
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

const FeedingType = enum {
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

const FeedingItem = struct {
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
        const date_time_str: []const u8 = if (self.date_time) |dt| try dt.toIsoString(allocator) else "N/A";
        const amount_ml_str: []const u8 = if (self.amount_ml) |a| std.fmt.bufPrint(&amount_buffer, "{d}", .{a}) catch "N/A" else "N/A";
        const duration_sec_str: []const u8 = if (self.duration_sec) |d| std.fmt.bufPrint(&duration_buffer, "{d}", .{d}) catch "N/A" else "N/A";
        return std.fmt.allocPrint(
            allocator.*,
            "date_time={s};duration_sec={s};type={s};feeder={s};amount_ml={s};notes={s}",
            .{ date_time_str, duration_sec_str, feeding_type_str, feeder_str, amount_ml_str, notes_str },
        ) catch null;
    }
};

const BodyItem = struct {
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

    pub fn toSlice(self: FeedingItem, allocator: *std.mem.Allocator) ?[]u8 {
        var weight_kg_buffer: [16]u8 = undefined;
        var urinations_buffer: [16]u8 = undefined;
        var defecations_buffer: [16]u8 = undefined;
        const notes_str: []const u8 = if (self.notes) |n| n else "N/A";
        const date_time_str: []const u8 = if (self.date_time) |dt| try dt.toIsoString(allocator) else "N/A";
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

const Props = struct {
    io: *std.Io,
    allocator: *std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    body_items: ?[]BodyItem = null,
    env_map: *std.process.Environ.Map,
    feeding_items: ?[]FeedingItem = null,
    body_items_file_path: []const u8 = ".lrc_database/body_items.z",
    feeding_items_file_path: []const u8 = ".lrc_database/feeding_items.z",
};

const BabyData = struct {
    io: *std.Io,
    body_items: ?[]BodyItem,
    allocator: *std.mem.Allocator,
    feeding_items: ?[]FeedingItem,
    arena: std.heap.ArenaAllocator,
    env_map: *std.process.Environ.Map,
    body_items_file_path: [:0]const u8,
    feeding_items_file_path: [:0]const u8,

    pub fn deinit(self: *BabyData) void {
        self.arena.deinit();
        self.allocator.free(self.body_items_file_path);
        self.allocator.free(self.feeding_items_file_path);
    }

    fn extractBodyDataFromContent(self: *BabyData, content: []const u8) void {
        const arena = self.arena.allocator();
        var entries: std.ArrayList(BodyItem) = .empty;
        var line_it = std.mem.splitSequence(u8, content, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) continue;
            if (line[0] == '#') continue;
            const entry = BodyItem.fromSlice(line);
            if (entry) |e| entries.append(arena, e) catch continue;
        }
        self.body_items = entries.toOwnedSlice(arena) catch @panic("Failed to convert body items to owned slice");
    }

    fn extractFeedingDataFromContent(self: *BabyData, content: []const u8) void {
        const arena = self.arena.allocator();
        var entries: std.ArrayList(FeedingItem) = .empty;
        var line_it = std.mem.splitSequence(u8, content, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) continue;
            if (line[0] == '#') continue;
            const entry = FeedingItem.fromSlice(line);
            entries.append(arena, entry) catch continue;
        }
        self.feeding_items = entries.toOwnedSlice(arena) catch @panic("Failed to convert feeding items to owned slice");
    }

    pub fn init(props: Props) BabyData {
        var body_file_exists = false;
        var feeding_file_exists = false;
        const body_items_file_path = sliceToZSlice(props.allocator, props.body_items_file_path) catch @panic("Failed to convert feeding items file path to Z slice");
        defer props.allocator.free(body_items_file_path);
        const feeding_items_file_path = sliceToZSlice(props.allocator, props.feeding_items_file_path) catch @panic("Failed to convert feeding items file path to Z slice");
        defer props.allocator.free(feeding_items_file_path);
        const baby_data = BabyData{
            .io = props.io,
            .env_map = props.env_map,
            .allocator = props.allocator,
            .body_items = props.body_items,
            .feeding_items = props.feeding_items,
            .body_items_file_path = feeding_items_file_path,
            .feeding_items_file_path = feeding_items_file_path,
            .arena = std.heap.ArenaAllocator.init(props.allocator.*),
        };

        createFile(baby_data.io, baby_data.env_map, baby_data.body_items_file_path) catch |err| switch (err) {
            error.PathAlreadyExists => body_file_exists = true,
            else => @panic("Failed to create body items data file"),
        };
        if (!body_file_exists) {
            const example_content = "# FORMAT: date_time=2026-09-02T00:00:00;urinations=6;defecations=6;weight_kg=3.5;notes=N/A\n";
            writeFile(baby_data.io, baby_data.env_map, baby_data.body_items_file_path, example_content) catch @panic("Failed to write initial body items data file");
        }
        const body_content = readFile(baby_data.io, baby_data.env_map, baby_data.allocator, body_items_file_path) catch @panic("Failed to read body items data file");
        baby_data.extractBodyDataFromContent(body_content) catch @panic("Failed to extract data from body items content");

        createFile(baby_data.io, baby_data.env_map, baby_data.feeding_items_file_path) catch |err| switch (err) {
            error.PathAlreadyExists => feeding_file_exists = true,
            else => @panic("Failed to create feeding items data file"),
        };
        if (!feeding_file_exists) {
            const example_content = "# FORMAT: date_time=2026-09-02T00:00:00;duration_sec=30;type=breast;feeder=Pavla;notes=N/A\n";
            writeFile(baby_data.io, baby_data.env_map, baby_data.feeding_items_file_path, example_content) catch @panic("Failed to write initial feeding items data file");
        }
        const feeding_content = readFile(baby_data.io, baby_data.env_map, baby_data.allocator, feeding_items_file_path) catch @panic("Failed to read feeding items data file");
        baby_data.extractFeedingDataFromContent(feeding_content) catch @panic("Failed to extract data from feeding items content");

        return baby_data;
    }
};
