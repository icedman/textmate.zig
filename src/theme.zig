const std = @import("std");

pub fn setColorHex(stdout: anytype, hex: []const u8) !void {
    if (hex.len != 7 or hex[0] != '#') {
        return error.InvalidHexColor;
    }

    const r = try std.fmt.parseInt(u8, hex[1..3], 16);
    const g = try std.fmt.parseInt(u8, hex[3..5], 16);
    const b = try std.fmt.parseInt(u8, hex[5..7], 16);

    // 24-bit ANSI foreground color
    stdout.print("\x1b[38;2;{d};{d};{d}m", .{ r, g, b });
    // stdout.print("[{d};{d};{d}]\n", .{ r, g, b });
}

pub fn setColorRgb(stdout: anytype, rgb: Rgb) !void {
    // 24-bit ANSI foreground color
    stdout.print("\x1b[38;2;{d};{d};{d}m", .{ rgb.r, rgb.g, rgb.b });
    // stdout.print("[{d};{d};{d}]\n", .{ rgb.r, rgb.g, rgb.b });
}

pub fn setBgColorHex(stdout: anytype, hex: []const u8) !void {
    if (hex.len != 7 or hex[0] != '#') {
        return error.InvalidHexColor;
    }

    const r = try std.fmt.parseInt(u8, hex[1..3], 16);
    const g = try std.fmt.parseInt(u8, hex[3..5], 16);
    const b = try std.fmt.parseInt(u8, hex[5..7], 16);

    // 24-bit ANSI background color
    stdout.print("\x1b[48;2;{d};{d};{d}m", .{ r, g, b });
    // stdout.print("[{d};{d};{d}]\n", .{ r, g, b });
}

pub fn setBgColorRgb(stdout: anytype, rgb: Rgb) !void {
    // 24-bit ANSI foreground color
    stdout.print("\x1b[48;2;{d};{d};{d}m", .{ rgb.r, rgb.g, rgb.b });
    // stdout.print("[{d};{d};{d}]\n", .{ r, g, b });
}

pub fn resetColor(stdout: anytype) !void {
    stdout.print("\x1b[0m", .{});
}

pub const Scope = struct {
    allocator: std.mem.Allocator,
    children: std.StringHashMap(Scope),
    token: ?*TokenColor = null,

    pub fn init(allocator: std.mem.Allocator) Scope {
        return Scope{
            .allocator = allocator,
            .children = std.StringHashMap(Scope).init(allocator),
        };
    }

    pub fn deinit(self: *Scope) void {
        // std.debug.print("deinit scope\n", .{});
        var it = self.children.iterator();
        while (it.next()) |kv| {
            const v = kv.value_ptr;
            v.deinit();
        }
        self.children.deinit();
    }

    pub fn addScope(self: *Scope, scope: []const u8, token: ?*TokenColor) void {
        // split
        // TODO " " denotes nesting (currently unimplemented)
        const space: []const u8 = " ";
        if (std.mem.indexOf(u8, scope, space)) |idx| {
            self.addScope(scope[0..idx], token);
            self.addScope(scope[idx + 1 ..], token);
            return;
        }

        const dot: []const u8 = ".";
        var key = scope[0..scope.len];
        if (std.mem.indexOf(u8, scope, dot)) |idx| {
            key = scope[0..idx];
        }

        // insert or get existing
        const gop = self.children.getOrPut(key) catch return;
        if (!gop.found_existing) {
            gop.value_ptr.* = Scope.init(self.allocator);
        }
        var target: *Scope = gop.value_ptr;

        if ((key.len + 1) < scope.len) {
            const next = scope[key.len + 1 ..];
            target.addScope(next, token);
        } else if (target.token == null) {
            target.token = token;
        }
    }

    pub fn getScope(self: *const Scope, scope: []const u8, colors: ?*Settings) ?*const Scope {
        // split
        const dot: []const u8 = ".";
        var key = scope[0..scope.len];
        if (std.mem.indexOf(u8, scope, dot)) |idx| {
            key = scope[0..idx];
        }

        const target = self.children.get(key) orelse null;
        if (target) |*t| {
            if (colors) |clr| {
                if (t.token) |tk| {
                    if (tk.settings) |ss| {
                        clr.* = ss;
                    }
                }
            }
            if ((key.len + 1) < scope.len) {
                const next = scope[key.len + 1 ..];
                return t.getScope(next, colors) orelse self;
            } else {
                return t;
            }
        }

        if ((key.len + 1) < scope.len) {
            const next = scope[key.len + 1 ..];
            return self.getScope(next, colors) orelse self;
        }

        return self;
    }

    pub fn dump(self: *const Scope, depth: u32) void {
        var it = self.children.iterator();
        while (it.next()) |kv| {
            const k = kv.key_ptr.*;
            const v = kv.value_ptr.*;
            for (0..depth) |i| {
                _ = i;
                std.debug.print("  ", .{});
            }
            std.debug.print("{s} ", .{k});
            if (v.token) |tk| {
                if (tk.settings) |ts| {
                    if (ts.foreground) |fg| {
                        std.debug.print("fg: {s} ", .{fg});
                    }
                }
            }
            std.debug.print("\n", .{});
            v.dump(depth + 1);
        }
    }
};

pub const TokenColor = struct {
    name: []const u8,
    scope: ?[][]const u8 = null,
    settings: ?Settings = null,
};

pub const Rgb = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,

    pub fn fromHex(hex: []const u8) Rgb {
        if (hex.len != 7 or hex[0] != '#') {
            return Rgb{};
        }
        const r = std.fmt.parseInt(u8, hex[1..3], 16) catch {
            return Rgb{};
        };
        const g = std.fmt.parseInt(u8, hex[3..5], 16) catch {
            return Rgb{};
        };
        const b = std.fmt.parseInt(u8, hex[5..7], 16) catch {
            return Rgb{};
        };
        return Rgb{ .r = r, .g = g, .b = b };
    }
};

pub const Settings = struct {
    foreground: ?[]const u8 = null,
    background: ?[]const u8 = null,
    fontStyle: ?[]const u8 = null,
    foreground_rgb: ?Rgb = null,
    background_rgb: ?Rgb = null,

    pub fn compute(self: *Settings) void {
        if (self.foreground) |fg| {
            self.foreground_rgb = Rgb.fromHex(fg);
        }
        if (self.background) |bg| {
            self.background_rgb = Rgb.fromHex(bg);
        }
    }
};

pub const Theme = struct {
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,

    name: []const u8,
    author: ?[]const u8 = null,
    colors: ?std.StringHashMap([]const u8) = null,
    tokenColors: ?[]TokenColor = null,
    semanticHighlighting: bool = false,

    root: Scope,

    // TODO release this after parse (requires that all string values by allocated and copied)
    parsed: ?std.json.Parsed(std.json.Value) = null,

    pub fn init(allocator: std.mem.Allocator, source_path: []const u8) !Theme {
        const file = try std.fs.cwd().openFile(source_path, .{});
        defer file.close();
        const file_size = (try file.stat()).size;
        const file_contents = try file.readToEndAlloc(allocator, file_size);
        defer allocator.free(file_contents);
        return Theme.parse(allocator, file_contents);
    }

    pub fn deinit(self: *Theme) void {
        // TODO properly free up memory
        // if (self.colors) |*colors| {
        //     colors.deinit();
        // }
        // if (self.parsed) |*parsed| {
        //     parsed.deinit();
        // }
        self.root.deinit();
        self.arena.deinit();
    }

    pub fn parse(allocator: std.mem.Allocator, source: []const u8) !Theme {
        var theme = Theme{
            .allocator = allocator,
            .arena = std.heap.ArenaAllocator.init(allocator),
            .name = "",
            .root = Scope.init(allocator),
        };

        // anything associated with reading the json
        const aa = theme.arena.allocator();

        const parsed = try std.json.parseFromSlice(std.json.Value, aa, source, .{ .ignore_unknown_fields = true });
        errdefer parsed.deinit();

        const root = parsed.value;
        const obj = root.object;

        // theme meta
        const name = if (obj.get("name")) |v| v.string else "";
        const author = if (obj.get("author")) |v| v.string else "";
        const semanticHighlighting = if (obj.get("semanticHighlighting")) |v| v.bool else false;

        // colors
        var colors = std.StringHashMap([]const u8).init(aa);
        if (obj.get("colors")) |colors_val| {
            if (colors_val == .object) {
                var it = colors_val.object.iterator();
                while (it.next()) |entry| {
                    const k = entry.key_ptr.*;
                    const v = entry.value_ptr.*.string;
                    try colors.put(k, v);
                }
            }
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
                const opt = o.get("scope") orelse break :blk null;
                if (opt == .string) {
                    const scopes = try aa.alloc([]const u8, 1);
                    scopes[0] = opt.string;
                    break :blk scopes;
                }
                if (opt == .array) {
                    const scopes = try aa.alloc([]const u8, opt.array.items.len);
                    for (opt.array.items, 0..) |scope_item, j| {
                        scopes[j] = scope_item.string;
                    }
                    break :blk scopes;
                }
                break :blk null;
            };

            tokenColors[i] = TokenColor{ .name = token_name, .settings = settings.value, .scope = scopes };
            tokenColors[i].settings.?.compute();

            if (scopes) |outer| {
                for (outer) |sc| {
                    theme.root.addScope(sc, &tokenColors[i]);
                }
            }
        }

        theme.name = name;
        theme.author = author;
        theme.semanticHighlighting = semanticHighlighting;
        theme.colors = colors;
        theme.tokenColors = tokenColors;
        theme.parsed = parsed;

        return theme;
    }

    pub fn getScope(self: *Theme, scope: []const u8, colors: ?*Settings) ?*const Scope {
        // TODO pass parse state for nesting checks
        return self.root.getScope(scope, colors);
    }
};

pub fn runTests(comptime testing: anytype, verbosely: bool) !void {
    var thm = try Theme.init(testing.allocator, "data/tests/dracula.json");
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
    };

    for (entries) |entry| {
        var colors = Settings{};
        _ = thm.getScope(entry.key, &colors);
        if (colors.foreground) |fg| {
            if (verbosely) {
                setColorHex(std.debug, fg) catch {};
                std.debug.print("{s} fg: {s}\n", .{ entry.key, fg });
            }
            try testing.expectEqualStrings(fg, entry.value);
        }
    }
}
