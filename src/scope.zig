// TODO
// scope selection needs to be accurate for rendering to be accurate

const std = @import("std");
const resources = @import("resources.zig");
const theme = @import("theme.zig");
const util = @import("util.zig");
const ThemeInfo = resources.ThemeInfo;

test "scopes" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(ThemeInfo).init(allocator);
    defer list.deinit();
    try resources.listThemes(allocator, "./data/themes", &list);
    for (list.items) |item| {
        const p: []const u8 = &item.full_path;
        var thm = theme.Theme.init(allocator, util.toSlice([]const u8, p)) catch {
            unreachable;
        };
        defer thm.deinit();
    }
}
