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

    pub fn deinit(self: *BabyData) void {
        self.arena.deinit();
        self.allocator.free(self.body_items_file_path);
        self.allocator.free(self.feeding_items_file_path);
    }

    fn extractBodyDataFromContent(self: *BabyData, content: []const u8) void {
        const arena = self.arena.allocator();
        var entries: std.ArrayList(utils.BodyItem) = .empty;
        var line_it = std.mem.splitSequence(u8, content, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) continue;
            if (line[0] == '#') continue;
            const entry = utils.BodyItem.fromSlice(line);
            entries.append(arena, entry) catch continue;
        }
        self.body_items = entries.toOwnedSlice(arena) catch @panic("Failed to convert body items to owned slice");
    }

    fn extractFeedingDataFromContent(self: *BabyData, content: []const u8) void {
        const arena = self.arena.allocator();
        var entries: std.ArrayList(utils.FeedingItem) = .empty;
        var line_it = std.mem.splitSequence(u8, content, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) continue;
            if (line[0] == '#') continue;
            const entry = utils.FeedingItem.fromSlice(line);
            entries.append(arena, entry) catch continue;
        }
        self.feeding_items = entries.toOwnedSlice(arena) catch @panic("Failed to convert feeding items to owned slice");
    }

    pub fn init(props: Props) BabyData {
        var body_file_exists = false;
        var feeding_file_exists = false;
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

        createFile(baby_data.io, baby_data.env_map, baby_data.body_items_file_path) catch |err| switch (err) {
            error.PathAlreadyExists => body_file_exists = true,
            else => @panic("Failed to create body items data file"),
        };
        if (!body_file_exists) {
            const example_content = "# FORMAT: date_time=2026-09-02T00:00:00;urinations=6;defecations=6;weight_kg=3.5;notes=N/A\n";
            writeFile(baby_data.io, baby_data.env_map, baby_data.body_items_file_path, example_content) catch @panic("Failed to write initial body items data file");
        }
        var arena_allocator = baby_data.arena.allocator();
        const body_content = readFile(baby_data.io, baby_data.env_map, &arena_allocator, body_items_file_path) catch @panic("Failed to read body items data file");
        baby_data.extractBodyDataFromContent(body_content);

        createFile(baby_data.io, baby_data.env_map, baby_data.feeding_items_file_path) catch |err| switch (err) {
            error.PathAlreadyExists => feeding_file_exists = true,
            else => @panic("Failed to create feeding items data file"),
        };
        if (!feeding_file_exists) {
            const example_content = "# FORMAT: date_time=2026-09-02T00:00:00;duration_sec=30;type=breast;feeder=Pavla;notes=N/A\n";
            writeFile(baby_data.io, baby_data.env_map, baby_data.feeding_items_file_path, example_content) catch @panic("Failed to write initial feeding items data file");
        }
        const feeding_content = readFile(baby_data.io, baby_data.env_map, &arena_allocator, feeding_items_file_path) catch @panic("Failed to read feeding items data file");
        baby_data.extractFeedingDataFromContent(feeding_content);

        return baby_data;
    }
};
