const std = @import("std");
const DateTime = @import("../date-time.zig").DateTime;

pub const FeedingData = struct { date: []const u8, water_consumed: u6, urination_count: u6, defecation_count: u6, day_notes: []const u8, feeding_items: []FeedingItem };

pub const FeedingFeeder = enum {
    Pavla,
    David,
    Other,
    Invalid,

    pub fn fromSlice(s: []const u8) FeedingFeeder {
        if (std.mem.eql(u8, s, "Pavla")) return .Pavla;
        if (std.mem.eql(u8, s, "David")) return .David;
        if (std.mem.eql(u8, s, "Other")) return .Other;
        return .Invalid;
    }

    pub fn toSlice(self: FeedingFeeder) []const u8 {
        switch (self) {
            .Pavla => return "Pavla",
            .David => return "David",
            .Other => return "Other",
            .Invalid => return "invalid",
        }
    }
};

pub const FeedingItem = struct { duration: u6, time: []const u8, notes: []const u8, feeder: FeedingFeeder, feeding_type: FeedingType };

pub const FeedingType = enum {
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
