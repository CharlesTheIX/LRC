const std = @import("std");

pub fn validateAddress(address: []const u8) void {
    if (address.len == 0) @panic("Address must not be empty");
    var count: usize = 0;
    var address_it = std.mem.splitSequence(u8, address, ".");
    while (address_it.next()) |segment| {
        if (segment.len == 0) @panic("Address segments must not be empty");
        count += 1;
    }
    if (count != 4) @panic("Address must have exactly 4 segments");
}

pub fn validatePort(port: u16) void {
    if (port == 0) @panic("Port number must be greater than 0");
    if (port > 65535) @panic("Port number must be less than or equal to 65535");
}
