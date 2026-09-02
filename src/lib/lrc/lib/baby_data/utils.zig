const std = @import("std");
const DateTime = @import("../date_time/root.zig").DateTime;

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

pub const FeedingItem = struct {
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
