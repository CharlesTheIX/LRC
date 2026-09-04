pub fn getCharSpacing(font_size: u32) f32 {
    var spacing = @divFloor(font_size, 8);
    if (spacing < 1) spacing = 1;
    return @as(f32, @floatFromInt(spacing));
}
