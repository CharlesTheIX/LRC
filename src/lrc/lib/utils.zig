const std = @import("std");
const Io = std.Io;
const Map = std.process.Environ.Map;
const Allocator = std.mem.Allocator;

pub fn appendFile(io: *Io, env_map: *Map, file_path: []const u8, data: []const u8) !void {
    const home_dir = getHomeDirectory(io, env_map) catch |err| return err;
    const file = home_dir.openFile(io.*, file_path, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => {
            // If the file doesn't exist, create it
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
    const file = home_dir.createFile(io.*, file_path, .{ .exclusive = true }) catch |err| switch (err) {
        error.PathAlreadyExists => return,
        else => return err,
    };
    defer file.close(io.*);
}

pub fn deleteFile(io: *Io, env_map: *Map, file_path: []const u8) !void {
    const home_dir = getHomeDirectory(io, env_map) catch |err| return err;
    home_dir.deleteFile(io.*, file_path) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
}

fn getHomeDirectory(io: *Io, env_map: *Map) !std.Io.Dir {
    const home_path = env_map.get("HOME") orelse return error.HomeDirectoryNotFound;
    return std.Io.Dir.cwd().openDir(io.*, home_path, .{}) catch return error.HomeDirectoryNotFound;
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

pub fn sliceToZSlice(allocator: *std.mem.Allocator, slice: []const u8) ![:0]const u8 {
    return allocator.dupeZ(u8, slice) catch return error.OutOfMemory;
}

pub fn writeFile(io: *Io, env_map: *Map, file_path: []const u8, data: []const u8) !void {
    const home_dir = getHomeDirectory(io, env_map) catch |err| return err;
    const file = home_dir.openFile(io.*, file_path, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => {
            // If the file doesn't exist, create it
            const new_file = home_dir.createFile(io.*, file_path, .{ .exclusive = true }) catch return error.FileCreateFailed;
            defer new_file.close(io.*);
            new_file.writeStreamingAll(io.*, data) catch return error.FileWriteFailed;
            return;
        },
        else => return err,
    };
    defer file.close(io.*);
    file.writeStreamingAll(io.*, data) catch return error.FileWriteFailed;
}
