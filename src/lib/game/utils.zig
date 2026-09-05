const std = @import("std");
const rl = @import("raylib");

const Io = std.Io;
const Map = std.process.Environ.Map;
const Allocator = std.mem.Allocator;

// Functions
pub fn appendFile(io: *Io, env_map: *Map, file_path: []const u8, data: []const u8) !void {
    const home_dir = getHomeDirectory(io, env_map) catch |err| return err;
    const file = home_dir.openFile(io.*, file_path, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => {
            const new_file = home_dir.createFile(io.*, file_path, .{ .exclusive = true }) catch return error.FileCreateFailed;
            defer new_file.close(io.*);
            new_file.writeStreamingAll(io.*, data) catch return error.FileWriteFailed;
            return;
        },
        else => return err,
    };
    defer file.close(io.*);
    const current_size = file.length(io.*) catch return error.FileReadFailed;
    file.writePositionalAll(io.*, data, current_size) catch return error.FileWriteFailed;
}

pub fn createDirectory(io: *Io, env_map: *Map, dir_path: []const u8) !void {
    const home_dir = getHomeDirectory(io, env_map) catch |err| return err;
    home_dir.createDir(io.*, dir_path, .default_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
}

pub fn createFile(io: *Io, env_map: *Map, file_path: []const u8) !void {
    const home_dir = getHomeDirectory(io, env_map) catch |err| return err;
    const file = home_dir.createFile(io.*, file_path, .{ .exclusive = true }) catch |err| return err;
    defer file.close(io.*);
}

pub fn degToRad(degrees: f32) f32 {
    return degrees * std.math.pi / 180.0;
}

pub fn deleteFile(io: *Io, env_map: *Map, file_path: []const u8) !void {
    const home_dir = getHomeDirectory(io, env_map) catch |err| return err;
    home_dir.deleteFile(io.*, file_path) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
}

pub fn getCharSpacing(font_size: u32) f32 {
    var spacing = @divFloor(font_size, 8);
    if (spacing < 1) spacing = 1;
    return @as(f32, @floatFromInt(spacing));
}

pub fn getFontSizeF32(font_size: u32) f32 {
    return @as(f32, @floatFromInt(font_size));
}

fn getHomeDirectory(io: *Io, env_map: *Map) !std.Io.Dir {
    const home_path = env_map.get("HOME") orelse return error.HomeDirectoryNotFound;
    return std.Io.Dir.cwd().openDir(io.*, home_path, .{}) catch return error.HomeDirectoryNotFound;
}

pub fn invertScroll(scroll: *rl.Vector2) rl.Vector2 {
    return rl.Vector2{ .x = scroll.x * -1, .y = scroll.y * -1 };
}

pub fn nowEpochYearSeconds() i64 {
    var ts: std.posix.timespec = undefined;
    switch (std.posix.errno(std.posix.system.clock_gettime(.REALTIME, &ts))) {
        .SUCCESS => {
            const unix_secs = @as(i64, @intCast(ts.sec));
            const ios_offset = @as(i64, @intCast(std.time.epoch.epoch_year));
            return unix_secs - ios_offset;
        },
        else => return 0,
    }
}

pub fn readFile(io: *Io, env_map: *Map, allocator: *Allocator, file_path: []const u8) ![]u8 {
    const home_dir = getHomeDirectory(io, env_map) catch |err| return err;
    const file = home_dir.openFile(io.*, file_path, .{}) catch return error.FileOpenFailed;
    defer file.close(io.*);
    const size = file.length(io.*) catch return error.FileReadFailed;
    const buffer = allocator.*.alloc(u8, size) catch return error.OutOfMemory;
    errdefer allocator.*.free(buffer);
    const read_bytes = file.readPositionalAll(io.*, buffer, 0) catch return error.FileReadFailed;
    return buffer[0..read_bytes];
}

pub fn rotateVector(v: rl.Vector2, angle_degrees: f32) rl.Vector2 {
    const angle_radians = angle_degrees * std.math.pi / 180.0;
    const cos_a = @cos(angle_radians);
    const sin_a = @sin(angle_radians);
    return .{ .x = v.x * cos_a - v.y * sin_a, .y = v.x * sin_a + v.y * cos_a };
}

pub fn sliceToZSlice(allocator: *std.mem.Allocator, slice: []const u8) ![:0]const u8 {
    return allocator.dupeZ(u8, slice) catch return error.OutOfMemory;
}

pub fn writeFile(io: *Io, env_map: *Map, file_path: []const u8, data: []const u8) !void {
    const home_dir = getHomeDirectory(io, env_map) catch |err| return err;
    const file = home_dir.openFile(io.*, file_path, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => {
            const new_file = home_dir.createFile(io.*, file_path, .{ .exclusive = true }) catch return error.FileCreateFailed;
            defer new_file.close(io.*);
            new_file.writeStreamingAll(io.*, data) catch return error.FileWriteFailed;
            return;
        },
        else => return err,
    };
    defer file.close(io.*);
    file.setLength(io.*, data.len) catch return error.FileWriteFailed;
    file.writeStreamingAll(io.*, data) catch return error.FileWriteFailed;
}
