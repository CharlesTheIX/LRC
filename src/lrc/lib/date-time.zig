const std = @import("std");
const epoch = std.time.epoch;

const Props = struct { year: epoch.Year, month: u4, day: u5, hour: u5 = 0, minute: u6 = 0, second: u6 = 0 };

pub const DateTime = struct {
    unix_seconds: i64,
    time_zone: TimeZone = .UTC,

    pub fn addDays(self: DateTime, days: i64) DateTime {
        return self.addSeconds(days * epoch.secs_per_day);
    }

    pub fn addSeconds(self: DateTime, seconds: i64) DateTime {
        return .{ .unix_seconds = self.unix_seconds + seconds };
    }

    fn epochSeconds(self: DateTime) epoch.EpochSeconds {
        return .{ .secs = @intCast(self.unix_seconds + self.time_zone.offsetSeconds()) };
    }

    pub fn getDate(self: DateTime) u5 {
        const year_day = self.epochSeconds().getEpochDay().calculateYearDay();
        return year_day.calculateMonthDay().day_index + 1;
    }

    /// 0 (Sunday) - 6 (Saturday).
    pub fn getDayOfWeek(self: DateTime) u3 {
        const epoch_day = self.epochSeconds().getEpochDay().day;
        // Jan 1, 1970 was a Thursday (day 4).
        return @intCast((epoch_day + 4) % 7);
    }

    pub fn getDayOfWeekName(self: DateTime) []const u8 {
        const day_of_week = self.getDayOfWeek();
        return switch (day_of_week) {
            0 => "Sunday",
            1 => "Monday",
            2 => "Tuesday",
            3 => "Wednesday",
            4 => "Thursday",
            5 => "Friday",
            6 => "Saturday",
            else => unreachable,
        };
    }

    pub fn getFullYear(self: DateTime) epoch.Year {
        return self.epochSeconds().getEpochDay().calculateYearDay().year;
    }

    pub fn getHours(self: DateTime) u5 {
        return self.epochSeconds().getDaySeconds().getHoursIntoDay();
    }

    pub fn getMinutes(self: DateTime) u6 {
        return self.epochSeconds().getDaySeconds().getMinutesIntoHour();
    }

    pub fn getMonth(self: DateTime) u4 {
        const year_day = self.epochSeconds().getEpochDay().calculateYearDay();
        return year_day.calculateMonthDay().month.numeric();
    }

    pub fn getMonthName(self: DateTime) []const u8 {
        const month = self.getMonth();
        return switch (month) {
            1 => "January",
            2 => "February",
            3 => "March",
            4 => "April",
            5 => "May",
            6 => "June",
            7 => "July",
            8 => "August",
            9 => "September",
            10 => "October",
            11 => "November",
            12 => "December",
            else => unreachable,
        };
    }

    pub fn getSeconds(self: DateTime) u6 {
        return self.epochSeconds().getDaySeconds().getSecondsIntoMinute();
    }

    pub fn getDiffSeconds(self: DateTime, other: DateTime) i64 {
        return self.unix_seconds - other.unix_seconds;
    }

    pub fn getTime(self: DateTime) i64 {
        return self.unix_seconds;
    }

    pub fn getTimeZone(self: DateTime) TimeZone {
        return self.time_zone;
    }

    pub fn init(props: Props) DateTime {
        var days: i64 = 0;
        var year: epoch.Year = epoch.epoch_year;
        while (year < props.year) : (year += 1) days += epoch.getDaysInYear(year);
        var month: u4 = 1;
        while (month < props.month) : (month += 1) days += epoch.getDaysInMonth(props.year, @enumFromInt(month));
        days += props.day - 1;
        const seconds = days * epoch.secs_per_day +
            @as(i64, props.hour) * 3600 +
            @as(i64, props.minute) * 60 +
            @as(i64, props.second);
        return .{ .unix_seconds = seconds };
    }

    pub fn initFromEpochSeconds(unix_seconds: i64) DateTime {
        return .{ .unix_seconds = unix_seconds };
    }

    /// Parses Iso string "YYYY-MM-DD" or "YYYY-MM-DDTHH:MM:SS".
    pub fn initFromIsoString(str: []const u8) !DateTime {
        if (str.len < 10) return error.InvalidFormat;
        const year = std.fmt.parseInt(epoch.Year, str[0..4], 10) catch return error.InvalidFormat;
        const month = std.fmt.parseInt(u4, str[5..7], 10) catch return error.InvalidFormat;
        const day = std.fmt.parseInt(u5, str[8..10], 10) catch return error.InvalidFormat;

        var hour: u5 = 0;
        var minute: u6 = 0;
        var second: u6 = 0;
        if (str.len >= 19) {
            hour = std.fmt.parseInt(u5, str[11..13], 10) catch return error.InvalidFormat;
            minute = std.fmt.parseInt(u6, str[14..16], 10) catch return error.InvalidFormat;
            second = std.fmt.parseInt(u6, str[17..19], 10) catch return error.InvalidFormat;
        }

        return .init(.{ .year = year, .month = month, .day = day, .hour = hour, .minute = minute, .second = second });
    }

    pub fn now() DateTime {
        var ts: std.posix.timespec = undefined;
        switch (std.posix.errno(std.posix.system.clock_gettime(.REALTIME, &ts))) {
            .SUCCESS => return .{ .unix_seconds = @intCast(ts.sec) },
            else => return .{ .unix_seconds = 0 },
        }
    }

    pub fn setTimeZone(self: DateTime, time_zone: TimeZone) DateTime {
        return .{ .unix_seconds = self.unix_seconds, .time_zone = time_zone };
    }

    pub fn toDateString(self: DateTime, allocator: *std.mem.Allocator) ![]u8 {
        return std.fmt.allocPrint(
            allocator.*,
            "{d:0>4}-{d:0>2}-{d:0>2}",
            .{ self.getFullYear(), self.getMonth(), self.getDate() },
        );
    }

    pub fn toIsoString(self: DateTime, allocator: *std.mem.Allocator) ![]u8 {
        const offset_hours = @divTrunc(self.time_zone.offsetSeconds(), 3600);
        return std.fmt.allocPrint(
            allocator.*,
            "{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}{s}{d:0>2}:00",
            .{
                self.getFullYear(),                 self.getMonth(),    self.getDate(),
                self.getHours(),                    self.getMinutes(),  self.getSeconds(),
                if (offset_hours < 0) "-" else "+", @abs(offset_hours),
            },
        );
    }

    pub fn toTimeString(self: DateTime, allocator: *std.mem.Allocator) ![]u8 {
        return std.fmt.allocPrint(
            allocator.*,
            "{d:0>2}:{d:0>2}:{d:0>2}",
            .{ self.getHours(), self.getMinutes(), self.getSeconds() },
        );
    }
};

const Month = enum(u4) {
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

const TimeZone = enum(i32) {
    UTC = 0,
    BST = 1,
    CEST = 2,

    pub fn offsetSeconds(self: TimeZone) i64 {
        return @as(i64, @intFromEnum(self)) * 3600;
    }
};
