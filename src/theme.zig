const std = @import("std");
const resources = @import("resources.zig");
const ThemeInfo = resources.ThemeInfo;

const scope_ = @import("scope.zig");
const util = @import("util.zig");
const Atom = scope_.Atom;

const setColorHex = util.setColorHex;
const setColorRgb = util.setColorRgb;
const setBgColorHex = util.setBgColorHex;
const setBgColorRgb = util.setBgColorRgb;
const resetColor = util.resetColor;

// TODO move to config.. smallcaps
const ENABLE_SCOPE_CACHING = true;

var theThemeLibrary: ?*ThemeLibrary = null;

pub const ThemeLibrary = struct {
    allocator: std.mem.Allocator = undefined,
    themes: std.ArrayList(ThemeInfo) = undefined,

    fn init(self: *ThemeLibrary) !void {
        self.themes = std.ArrayList(ThemeInfo).init(self.allocator);
    }

    fn deinit(self: *ThemeLibrary) void {
        self.themes.deinit();
    }

    pub fn addThemes(self: *ThemeLibrary, path: []const u8) !void {
        try resources.listThemes(self.allocator, path, &self.themes);
    }

    pub fn themeFromName(self: *ThemeLibrary, name: []const u8) !Theme {
        if (name.len >= 128) return error.NotFound;
        for (self.themes.items) |item| {
            if (std.mem.eql(u8, item.name[0..name.len], name)) {
                const p: []const u8 = &item.full_path;
                return Theme.init(self.allocator, util.toSlice([]const u8, p));
            }
        }
        return error.NotFound;
    }
};

pub fn initThemeLibrary(allocator: std.mem.Allocator) !void {
    theThemeLibrary = try allocator.create(ThemeLibrary);
    if (theThemeLibrary) |lib| {
        lib.allocator = allocator;
        try lib.init();
    }
}

pub fn deinitThemeLibrary() void {
    if (theThemeLibrary) |lib| {
        lib.deinit();
        theThemeLibrary = null;
    }
}

pub fn getThemeLibrary() ?*ThemeLibrary {
    return theThemeLibrary;
}

pub const Scope = struct {
    atom: Atom = Atom{},
    token: ?*TokenColor = null,
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
        if (hex.len < 7 or hex[0] != '#') {
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
    colors: ?std.StringHashMap(Settings) = null,
    token_colors: ?[]TokenColor = null,
    semantic_highlighting: bool = false,

    type: ?[]const u8 = null, // dark,light?

    atoms: ?std.StringHashMap(u32) = null,
    scopes: ?std.ArrayList(Scope) = null,
    scope_cache: ?std.StringHashMap(*Scope) = null,

    // TODO release this after parse (requires that all string values be allocated and copied)
    parsed: ?std.json.Parsed(std.json.Value) = null,

    pub fn init(allocator: std.mem.Allocator, source_path: []const u8) !Theme {
        const file = std.fs.cwd().openFile(source_path, .{}) catch |err| {
            std.debug.print("unable to open {s}\n", .{source_path});
            return err;
        };
        defer file.close();
        const file_size = (try file.stat()).size;
        const file_contents = try file.readToEndAlloc(allocator, file_size);
        defer allocator.free(file_contents);
        return Theme.parse(allocator, file_contents);
    }

    pub fn deinit(self: *Theme) void {
        if (self.atoms) |*atoms| {
            atoms.deinit();
        }
        if (self.scopes) |*scopes| {
            scopes.deinit();
        }
        if (self.scope_cache) |*cache| {
            cache.deinit();
        }
        self.arena.deinit();
    }

    pub fn parse(allocator: std.mem.Allocator, source: []const u8) !Theme {
        var theme = Theme{
            .allocator = allocator,
            .arena = std.heap.ArenaAllocator.init(allocator),
            .name = "",
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
        const semantic_highlighting = if (obj.get("semanticHighlighting")) |v| v.bool else false;

        // colors
        var colors = std.StringHashMap(Settings).init(aa);
        errdefer colors.deinit();
        if (obj.get("colors")) |colors_val| {
            if (colors_val == .object) {
                var it = colors_val.object.iterator();
                while (it.next()) |entry| {
                    if (entry.value_ptr.* != .string) {
                        // fail silenty
                        continue;
                    }
                    const k = entry.key_ptr.*;
                    const v = entry.value_ptr.*.string;
                    // TODO value should be settings
                    var settings = Settings{
                        .foreground = v,
                    };
                    settings.compute();
                    try colors.put(k, settings);
                }
            }
        }

        // tokenColors
        if (obj.get("tokenColors") == null) {
            return error.InvalidTheme;
        }

        var atoms = std.StringHashMap(u32).init(allocator);
        errdefer atoms.deinit();
        const token_colors_arr = obj.get("tokenColors").?.array;
        const token_colors = try aa.alloc(TokenColor, token_colors_arr.items.len);
        errdefer aa.free(token_colors);
        for (token_colors_arr.items, 0..) |item, i| {
            const o = item.object;
            const token_name = if (o.get("name")) |v| v.string else "";

            // settings
            if (o.get("settings") == null) {
                token_colors[i] = TokenColor{ .name = token_name };
                continue;
            }

            const settings_value = o.get("settings").?;
            const settings = try std.json.parseFromValue(Settings, aa, settings_value, .{ .ignore_unknown_fields = true });

            const scopes: ?[][]const u8 = blk: {
                const opt = o.get("scope") orelse break :blk null;
                if (opt == .string) {
                    const scopes = try aa.alloc([]const u8, 1);
                    errdefer aa.free(scopes);
                    scopes[0] = opt.string;
                    break :blk scopes;
                }
                if (opt == .array) {
                    const scopes = try aa.alloc([]const u8, opt.array.items.len);
                    errdefer aa.free(scopes);
                    for (opt.array.items, 0..) |scope_item, j| {
                        scopes[j] = scope_item.string;
                    }
                    break :blk scopes;
                }
                break :blk null;
            };

            token_colors[i] = TokenColor{ .name = token_name, .settings = settings.value, .scope = scopes };
            token_colors[i].settings.?.compute();

            if (scopes) |outer| {
                for (outer) |sc| {
                    scope_.extractAtom(sc, &atoms);
                }
            }
        }

        var atom_scopes = std.ArrayList(Scope).init(allocator);
        errdefer atom_scopes.deinit();

        for (token_colors, 0..) |tokenColor, ti| {
            if (tokenColor.scope) |sc| {
                for (sc) |scope_name| {
                    if (std.mem.indexOf(u8, scope_name, ",")) |_| continue;
                    if (std.mem.indexOf(u8, scope_name, " ")) |_| continue;
                    var atom = Atom{};
                    atom.compute(scope_name, &atoms);
                    atom_scopes.append(Scope{
                        .atom = atom,
                        .token = &token_colors[ti],
                    }) catch {};
                }
            }
        }

        theme.name = name;
        theme.author = author;
        theme.semantic_highlighting = semantic_highlighting;
        theme.colors = colors;
        theme.token_colors = token_colors;
        theme.atoms = atoms;
        theme.scopes = atom_scopes;
        theme.scope_cache = std.StringHashMap(*Scope).init(allocator);
        theme.parsed = parsed;

        return theme;
    }

    pub fn getScope(self: *Theme, scope: []const u8, colors: ?*Settings) ?*const Scope {
        if (scope.len == 0) {
            return null;
        }

        var atom = Atom{};
        // todo.. this should be cached from the grammar side too
        if (self.atoms) |*a| {
            atom.compute(scope, @constCast(a));
        }

        if (self.scopes) |scopes| {
            var highest: u8 = 0;
            var matched: ?*Scope = null;
            for (scopes.items) |*sc| {
                const m = Atom.cmp(atom, sc.atom);
                if (m > highest) {
                    highest = m;
                    matched = sc;
                }
            }
            if (colors) |cc| {
                if (matched) |mm| {
                    if (mm.token) |tk| {
                        if (tk.settings) |ts| {
                            cc.foreground = ts.foreground;
                            cc.foreground_rgb = ts.foreground_rgb;
                        }
                    }
                }
            }
            return matched;
        }

        return null;
    }

    pub fn getColor(self: *Theme, name: []const u8) ?Settings {
        if (self.colors.?.get(name)) |c| {
            return c;
        }
        return null;
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
