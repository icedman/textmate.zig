const std = @import("std");
const util = @import("util.zig");

// TODO move to config.. smallcaps
const MAX_NAME_LENGTH = 128;
const MAX_FILE_TYPES = 8;
const MAX_EXT_LENGTH = 16;

var theme_id: u16 = 1;
var grammar_id: u16 = 1;

// Fixed length strings for embedded resources
// convert to []const u8 for faster embedding (avoiding memcpy)
pub const GrammarInfo = struct {
    id: u16 = 0, // for caching purposed
    name: [MAX_NAME_LENGTH]u8 = [_]u8{0} ** MAX_NAME_LENGTH,
    scope_name: [MAX_NAME_LENGTH]u8 = [_]u8{0} ** MAX_NAME_LENGTH,
    full_path: [std.fs.max_path_bytes]u8 = [_]u8{0} ** std.fs.max_path_bytes,
    file_types: [MAX_FILE_TYPES][MAX_EXT_LENGTH]u8 = [_][MAX_EXT_LENGTH]u8{[_]u8{0} ** MAX_EXT_LENGTH} ** MAX_FILE_TYPES,
    file_types_count: u8 = 0,
    inject_only: bool = false,
    embedded_file: ?[]const u8 = null,
};

pub const ThemeInfo = struct {
    id: u16 = 0, // for caching purposes
    name: [MAX_NAME_LENGTH]u8 = [_]u8{0} ** MAX_NAME_LENGTH,
    author: [MAX_NAME_LENGTH]u8 = [_]u8{0} ** MAX_NAME_LENGTH,
    full_path: [std.fs.max_path_bytes]u8 = [_]u8{0} ** std.fs.max_path_bytes,
    embedded_file: ?[]const u8 = null,
};

pub fn getGrammarInfo(allocator: std.mem.Allocator, path: []const u8, full_path: []const u8) !GrammarInfo {
    // std.debug.print("{s}\n", .{path});
    _ = path;

    const file = try std.fs.cwd().openFile(full_path, .{});
    defer file.close();
    const file_size = (try file.stat()).size;
    const file_contents = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(file_contents);

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, file_contents, .{ .ignore_unknown_fields = true });
    defer parsed.deinit();

    const root = parsed.value;
    if (root != .object) return error.InvalidSyntax;
    const obj = root.object;

    const name = if (obj.get("name")) |v| v.string else "";
    if (name.len >= MAX_NAME_LENGTH) {
        return error.OutOfMemory;
    }
    const scope_name = if (obj.get("scopeName")) |v| v.string else "";
    if (scope_name.len >= MAX_NAME_LENGTH) {
        return error.OutOfMemory;
    }

    var gi = GrammarInfo{};
    @memcpy(gi.name[0..name.len], name);
    @memcpy(gi.scope_name[0..scope_name.len], scope_name);
    @memcpy(gi.full_path[0..full_path.len], full_path);
    if (obj.get("fileTypes")) |ft| {
        if (ft == .array) {
            for (ft.array.items, 0..) |f, j| {
                if (f.string.len < MAX_EXT_LENGTH) {
                    @memcpy(gi.file_types[j][0..f.string.len], f.string);
                    gi.file_types_count += 1;
                    if (gi.file_types_count >= MAX_FILE_TYPES) {
                        break;
                    }
                }
            }
        }
    }

    if (obj.get("injectTo")) |_| {
        gi.inject_only = true;
    }

    gi.id = grammar_id;
    grammar_id += 1;
    return gi;
}

/// read grammars from a directory
pub fn listGrammars(allocator: std.mem.Allocator, path: []const u8, list: *std.ArrayList(GrammarInfo)) !void {
    const dir = std.fs.cwd().openDir(path, .{ .iterate = true }) catch unreachable;
    var walker = dir.walk(allocator) catch unreachable;
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind != std.fs.File.Kind.file) {
            continue;
        }
        const tmp = try std.fs.path.join(allocator, &.{ path, entry.path });
        defer allocator.free(tmp);
        const gi = try getGrammarInfo(allocator, entry.path, tmp);

        // std.debug.print("{s}\n", .{gi.name});
        // std.debug.print("  {s}\n", .{gi.scope_name});
        // std.debug.print("  {s}\n", .{gi.full_path});
        // for (0..gi.file_types_count) |i| {
        //     std.debug.print("  -- {s}\n", .{gi.file_types[i]});
        // }

        try list.append(gi);
    }
}

test "get grammars" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(GrammarInfo).init(allocator);
    defer list.deinit();
    try listGrammars(allocator, "./src/grammars", &list);
}

pub fn getThemeInfo(allocator: std.mem.Allocator, path: []const u8, full_path: []const u8) !ThemeInfo {
    // std.debug.print("{s}\n", .{path});
    _ = path;

    const file = try std.fs.cwd().openFile(full_path, .{});
    defer file.close();
    const file_size = (try file.stat()).size;
    const file_contents = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(file_contents);

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, file_contents, .{ .ignore_unknown_fields = true });
    defer parsed.deinit();

    const root = parsed.value;
    if (root != .object) return error.InvalidSyntax;
    const obj = root.object;

    const name = if (obj.get("name")) |v| v.string else "";
    if (name.len >= MAX_NAME_LENGTH) {
        return error.OutOfMemory;
    }
    const author = if (obj.get("author")) |v| v.string else "";
    if (author.len >= MAX_NAME_LENGTH) {
        return error.OutOfMemory;
    }

    var ti = ThemeInfo{};
    @memcpy(ti.name[0..name.len], name);
    @memcpy(ti.author[0..author.len], author);
    @memcpy(ti.full_path[0..full_path.len], full_path);

    ti.id = theme_id;
    theme_id += 1;
    return ti;
}

/// read themes from a directory
pub fn listThemes(allocator: std.mem.Allocator, path: []const u8, list: *std.ArrayList(ThemeInfo)) !void {
    const dir = std.fs.cwd().openDir(path, .{ .iterate = true }) catch unreachable;
    var walker = dir.walk(allocator) catch unreachable;
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind != std.fs.File.Kind.file) {
            continue;
        }
        const tmp = try std.fs.path.join(allocator, &.{ path, entry.path });
        defer allocator.free(tmp);
        const ti = try getThemeInfo(allocator, entry.path, tmp);

        // std.debug.print("{s}\n", .{ti.name});
        // std.debug.print("  {s}\n", .{ti.author});
        // std.debug.print("  {s}\n", .{ti.full_path});

        try list.append(ti);
    }
}

// Use at build time to generate embedded_themes.zig
pub fn generateEmbeddedThemesFile(allocator: std.mem.Allocator, writer: anytype, prefix: []const u8, path: []const u8) !void {
    var list = std.ArrayList(ThemeInfo).init(allocator);
    defer list.deinit();
    try listThemes(allocator, path, &list);

    try writer.print("{s}{s}{s}{s}", .{ // :) how to do this?
        "/// This is a generated file. Do not edit manually\n\n",
        "const std = @import(\"std\");\n",
        "const res = @import(\"resources.zig\");\n",
        "const ThemeInfo = res.ThemeInfo;\n\n",
    });

    var embed_id: u16 = 1;

    for (list.items) |item| {
        const np: []const u8 = &item.full_path;
        const nps = util.toSlice([]const u8, np);
        const idx = (std.mem.indexOf(u8, nps, "src") orelse 0) + 4;
        try writer.print("const {s}{} = @embedFile(\"{s}\");\n", .{ prefix, embed_id, nps[idx..] });
        embed_id += 1;
    }

    embed_id = 1;

    try writer.print("\npub fn listThemes(allocator: std.mem.Allocator, list: *std.ArrayList(ThemeInfo)) !void {c}\n  _ = allocator;\n", .{'{'});
    for (list.items) |item| {
        const np: []const u8 = &item.name;
        const nps = util.toSlice([]const u8, np);

        try writer.print("  {c}\n", .{'{'});
        try writer.print("    const bytes: []const u8 = {s}{}[0..{s}{}.len];\n", .{ prefix, embed_id, prefix, embed_id });
        try writer.print("    var ti = ThemeInfo{c} .embedded_file = bytes {c};\n", .{ '{', '}' });
        try writer.print("    @memcpy(ti.name[0..\"{s}\".len], \"{s}\");\n", .{ nps, nps });
        try writer.print("    try list.append(ti);\n", .{});
        try writer.print("  {c}\n", .{'}'});
        embed_id += 1;
    }

    try writer.print("{c}\n", .{'}'});
}

// Use at build time to generate embedded_grammars.zig
pub fn generateEmbeddedGrammarsFile(allocator: std.mem.Allocator, writer: anytype, prefix: []const u8, path: []const u8) !void {
    var list = std.ArrayList(GrammarInfo).init(allocator);
    defer list.deinit();
    try listGrammars(allocator, path, &list);

    try writer.print("{s}", .{ // :) how to do this?
        "\nconst GrammarInfo = res.GrammarInfo;\n\n",
    });

    var embed_id: u16 = 1;

    for (list.items) |item| {
        const np: []const u8 = &item.full_path;
        const nps = util.toSlice([]const u8, np);
        const idx = (std.mem.indexOf(u8, nps, "src") orelse 0) + 4;
        try writer.print("const {s}{} = @embedFile(\"{s}\");\n", .{ prefix, embed_id, nps[idx..] });
        embed_id += 1;
    }

    embed_id = 1;

    try writer.print("\npub fn listGrammars(allocator: std.mem.Allocator, list: *std.ArrayList(GrammarInfo)) !void {c}\n  _ = allocator;\n", .{'{'});
    for (list.items) |item| {
        const np: []const u8 = &item.name;
        const nps = util.toSlice([]const u8, np);
        const sp: []const u8 = &item.scope_name;
        const sps = util.toSlice([]const u8, sp);
        try writer.print("  {c}\n", .{'{'});
        try writer.print("    const bytes: []const u8 = {s}{}[0..{s}{}.len];\n", .{ prefix, embed_id, prefix, embed_id });
        try writer.print("    var gi = GrammarInfo{c} .embedded_file = bytes, .file_types_count = {}, .inject_only = {}, {c};\n", .{
            '{',
            item.file_types_count,
            item.inject_only,
            '}',
        });
        try writer.print("    @memcpy(gi.name[0..\"{s}\".len], \"{s}\");\n", .{ nps, nps });
        try writer.print("    @memcpy(gi.scope_name[0..\"{s}\".len], \"{s}\");\n", .{ sps, sps });
        for (0..item.file_types_count) |fi| {
            const fp: []const u8 = &item.file_types[fi];
            const fps = util.toSlice([]const u8, fp);
            try writer.print("    @memcpy(gi.file_types[{}][0..\"{s}\".len], \"{s}\");\n", .{ fi, fps, fps });
        }
        try writer.print("    try list.append(gi);\n", .{});
        try writer.print("  {c}\n", .{'}'});
        embed_id += 1;
    }

    try writer.print("{c}\n", .{'}'});
}

test "get themes" {
    const allocator = std.testing.allocator;

    var assets_buffer = std.ArrayList(u8).init(allocator);
    defer assets_buffer.deinit();

    const writer = assets_buffer.writer();

    // try generateEmbeddedThemesFile(allocator, writer, "theme_", "./src/themes");
    try generateEmbeddedGrammarsFile(allocator, writer, "grammar_", "./src/grammars");

    std.debug.print("{s}\n", .{assets_buffer.items});
}
