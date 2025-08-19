const std = @import("std")

// TODO move to config.. smallcaps
const MAX_NAME_LENGTH = 128;
const MAX_FILE_TYPES = 8;
const MAX_EXT_LENGTH = 16;

// fixed length strings for embedded resources
pub const GrammarInfo = struct {
    name: [MAX_NAME_LENGTH:0]u8 = [_:0]u8{0} ** MAX_NAME_LENGTH,
    scope_name: [MAX_NAME_LENGTH:0]u8 = [_:0]u8{0} ** MAX_NAME_LENGTH,
    full_path: [std.fs.max_path_bytes:0]u8 = [_:0]u8{0} ** std.fs.max_path_bytes,
    file_types: [MAX_FILE_TYPES][MAX_EXT_LENGTH:0]u8 = [_][MAX_EXT_LENGTH:0]u8{[_:0]u8{0} ** MAX_EXT_LENGTH} ** MAX_FILE_TYPES,
    file_types_count: u8 = 0,
    embedded: bool = false,
};

pub const ThemeInfo = struct {
    name: [MAX_NAME_LENGTH:0]u8 = [_:0]u8{0} ** MAX_NAME_LENGTH,
    author: [MAX_NAME_LENGTH:0]u8 = [_:0]u8{0} ** MAX_NAME_LENGTH,
    full_path: [std.fs.max_path_bytes:0]u8 = [_:0]u8{0} ** std.fs.max_path_bytes,
    embedded: bool = false,
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

        // std.debug.print("  {s}\n", .{gi.name});
        // std.debug.print("  {s}\n", .{gi.scope_name});
        // std.debug.print("  {s}\n", .{gi.full_path});
        // for (0..gi.file_types_count) |i| {
        //     std.debug.print("  -- {s}\n", .{gi.file_types[i]});
        // }

        try list.append(gi);

        // if (list.items.len > 10) break;
        // std.debug.print("{any}\n", .{entry});
    }
}

test "get grammars" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(GrammarInfo).init(allocator);
    defer list.deinit();
    try listGrammars(allocator, "./data/grammars", &list);
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

        // std.debug.print("  {s}\n", .{ti.name});
        // std.debug.print("  {s}\n", .{ti.author});
        // std.debug.print("  {s}\n", .{ti.full_path});

        try list.append(ti);

        // if (list.items.len > 10) break;
        // std.debug.print("{any}\n", .{entry});
    }
}

test "get themes" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(ThemeInfo).init(allocator);
    defer list.deinit();
    try listThemes(allocator, "./data/themes", &list);
}
