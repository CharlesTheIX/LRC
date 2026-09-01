pub const Month = enum(u4) {
    January = 1,
    February = 2,
    March = 3,
    April = 4,
    May = 5,
    June = 6,
    July = 7,
    August = 8,
    September = 9,
    October = 10,
    November = 11,
    December = 12,

    pub fn numeric(self: Month) u4 {
        return @as(u4, @intFromEnum(self));
    }

    pub fn fromNumeric(n: u4) !Month {
        switch (n) {
            1 => return .January,
            2 => return .February,
            3 => return .March,
            4 => return .April,
            5 => return .May,
            6 => return .June,
            7 => return .July,
            8 => return .August,
            9 => return .September,
            10 => return .October,
            11 => return .November,
            12 => return .December,
            else => return error.InvalidMonthNumber,
        }
    }
};
