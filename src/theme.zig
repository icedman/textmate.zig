const std = @import("std");

pub const Theme = struct {
    arena: std.heap.ArenaAllocator,
    allocator: std.mem.Allocator,

    name: []const u8,
    author: ?[]const u8 = null,
    colors: ?std.StringHashMap([]const u8) = null,
    tokenColors: ?[]TokenColor = null,
    semanticHighlighting: bool = false,

    pub const TokenColor = struct {
        name: []const u8,
        // scope: ?[][]u8 = null,
        scope: ?[][]const u8 = null,
        settings: ?Settings = null,
    };

    pub const Settings = struct {
        foreground: ?[]const u8 = null,
        background: ?[]const u8 = null,
        fontStyle: ?[]const u8 = null,
    };

    pub fn init(allocator: std.mem.Allocator, source_path: []const u8) !Theme {
        const file = try std.fs.cwd().openFile(source_path, .{});
        defer file.close();
        const file_size = (try file.stat()).size;
        const file_contents = try file.readToEndAlloc(allocator, file_size);
        defer allocator.free(file_contents);
        return Theme.parse(allocator, file_contents);
    }

    pub fn deinit(self: *Theme) void {
        self.arena.deinit();
    }

    pub fn parse(allocator: std.mem.Allocator, source: []const u8) !Theme {
        var arena = std.heap.ArenaAllocator.init(allocator);
        var aa = arena.allocator();
        errdefer arena.deinit();

        const parsed = try std.json.parseFromSlice(std.json.Value, aa, source, .{ .ignore_unknown_fields = true });
        const root = parsed.value;
        const obj = root.object;

        // theme meta
        const name = obj.get("name").?.string;
        const author = obj.get("author").?.string;
        const semanticHighlighting = if (obj.get("semnaticHighlighting")) |v| v.bool else false;

        // colors
        var colors = std.StringHashMap([]const u8).init(aa);
        const colors_obj = obj.get("colors").?.object;
        var it = colors_obj.iterator();

        while (it.next()) |entry| {
            const k = entry.key_ptr.*;
            const v = entry.value_ptr.*.string;
            try colors.put(k, v);
            // std.debug.print("{s} {s}\n", .{k, v});
        }

        // tokenColors
        const tokenColors_arr = obj.get("tokenColors").?.array;
        const tokenColors = try aa.alloc(TokenColor, tokenColors_arr.items.len);
        for (tokenColors_arr.items, 0..) |item, i| {
            const o = item.object;
            const token_name = if (o.get("name")) |v| v.string else "";

            // settings
            const settings_value = o.get("settings").?;
            const settings = try std.json.parseFromValue(Settings, aa, settings_value, .{ .ignore_unknown_fields = true });

            const scopes: ?[][]const u8 = blk: {
                const opt = o.get("scope").?;
                if (opt == .string) {
                    const scopes = try aa.alloc([]const u8, 1);
                    // scopes[0] = try aa.dupe(u8, opt.string);
                    scopes[0] = opt.string;
                    break :blk scopes;
                }
                if (opt == .array) {
                    const scopes = try aa.alloc([]const u8, opt.array.items.len);
                    for (opt.array.items, 0..) |scope_item, j| {
                        // scopes[j] = try aa.dupe(u8, scope_item.string);
                        scopes[j] = scope_item.string;
                    }
                    break :blk scopes;
                }
                break :blk null;
            };

            tokenColors[i] = TokenColor{ .name = token_name, .settings = settings.value, .scope = scopes };
            // std.debug.print("{s} {}\n", .{ token_name, i });
        }

        return Theme{
            .arena = arena,
            .allocator = allocator,
            .name = name,
            .author = author,
            .semanticHighlighting = semanticHighlighting,
            .colors = colors,
            .tokenColors = tokenColors,
        };
    }
};
