const std = @import("std");
const theme = @import("theme.zig");
const Rgb = theme.Rgb;

pub fn toSlice(comptime T: type, array: T) []const u8 {
    const len = for (array, 0..) |ch, i| {
        if (ch == 0) break i;
    } else 0;
    return array[0..len];
}

pub fn toHash(s: []const u8) u64 {
    var hasher = std.hash.Fnv1a_64.init();
    hasher.update(s);
    return hasher.final();
}

// 24-bit ANSI foreground and background color
pub fn setColorHex(stdout: anytype, hex: []const u8) !void {
    if (hex.len != 7 or hex[0] != '#') {
        return error.InvalidHexColor;
    }

    const r = try std.fmt.parseInt(u8, hex[1..3], 16);
    const g = try std.fmt.parseInt(u8, hex[3..5], 16);
    const b = try std.fmt.parseInt(u8, hex[5..7], 16);

    try stdout.print("\x1b[38;2;{d};{d};{d}m", .{ r, g, b });
}

pub fn setColorRgb(stdout: anytype, rgb: Rgb) !void {
    try stdout.print("\x1b[38;2;{d};{d};{d}m", .{ rgb.r, rgb.g, rgb.b });
}

pub fn setBgColorHex(stdout: anytype, hex: []const u8) !void {
    if (hex.len < 7 or hex[0] != '#') {
        return error.InvalidHexColor;
    }

    const r = try std.fmt.parseInt(u8, hex[1..3], 16);
    const g = try std.fmt.parseInt(u8, hex[3..5], 16);
    const b = try std.fmt.parseInt(u8, hex[5..7], 16);

    try stdout.print("\x1b[48;2;{d};{d};{d}m", .{ r, g, b });
}

pub fn setBgColorRgb(stdout: anytype, rgb: Rgb) !void {
    try stdout.print("\x1b[48;2;{d};{d};{d}m", .{ rgb.r, rgb.g, rgb.b });
}

pub fn resetColor(stdout: anytype) !void {
    try stdout.print("\x1b[0m", .{});
}
