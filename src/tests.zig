const std = @import("std");
const parser = @import("parser.zig");
const theme = @import("theme.zig");

const VERBOSELY = false;

fn print(comptime fmt: []const u8, args: anytype) void {
    if (VERBOSELY) {
        std.debug.print(fmt, args);
    }
}

test "test parser" {
    // print(">>> test parser <<<\n", .{});
}

test "test theme" {
    var thm = try theme.Theme.init(std.testing.allocator, "data/tests/dracula.json");
    defer thm.deinit();

    // thm.root.dump(0);

    const Entry = struct {
        key: []const u8,
        value: []const u8,
    };

    // these values are currently as resolved - which is lacking in features. TODO get tests from vscode
    const entries = [_]Entry{
        .{ .key = "storage.type.built-in.primitive.c", .value = "#8BE9FD" },
        .{ .key = "meta.function.c", .value = "#8BE9FD" },
        .{ .key = "meta.function.definition.parameters.c", .value = "#8BE9FD" },
        .{ .key = "entity.name.function.c", .value = "#50FA7B" },
        .{ .key = "punctuation.section.parameters.begin.backet.round.c", .value = "#FF79C6" },
        .{ .key = "variable.parameter.probably.c", .value = "#FFB86C" },
        .{ .key = "punctuation.separator.delimiter.c", .value = "#FF79C6" },
        .{ .key = "keyword.operator.c", .value = "#FF79C6" },
        .{ .key = "punctuation.section.parameters.end.bracket.round.c", .value = "#FF79C6" },
        .{ .key = "meta.block.c", .value = "#FF79C6" },
    };

    for (entries) |entry| {
        var colors = theme.Settings{};
        _ = thm.getScope(entry.key, &colors);
        if (colors.foreground) |fg| {
            if (VERBOSELY) {
                theme.setColorHex(std.debug, fg) catch {};
            }
            print("{s} fg: {s}\n", .{ entry.key, fg });
            try std.testing.expectEqualStrings(fg, entry.value);
        }
    }
}
