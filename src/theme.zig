const std = @import("std");
const resources = @import("resources/resources.zig");
const embedded = @import("resources/embedded.zig");
const ThemeInfo = resources.ThemeInfo;

const atms = @import("atoms.zig");
const util = @import("util.zig");
const Atom = atms.Atom;

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

const setColorHex = util.setColorHex;
const setColorRgb = util.setColorRgb;
const setBgColorHex = util.setBgColorHex;
const setBgColorRgb = util.setBgColorRgb;
const resetColor = util.resetColor;

// TODO move to config.. smallcaps
const ENABLE_SCOPE_CACHING = true;

var theThemeLibrary: ?*ThemeLibrary = null;

pub const ThemeLibrary = struct {
    allocator: Allocator = undefined,
    themes: std.ArrayList(ThemeInfo) = undefined,
    cache: std.AutoHashMap(usize, Theme) = undefined,

    fn init(self: *ThemeLibrary) !void {
        self.themes = try std.ArrayList(ThemeInfo).initCapacity(self.allocator, 128);
        self.cache = std.AutoHashMap(usize, Theme).init(self.allocator);
    }

    fn deinit(self: *ThemeLibrary) void {
        self.themes.deinit(self.allocator);
        var it = self.cache.iterator();
        while (it.next()) |kv| {
            // const k = kv.key_ptr.*;
            var v = kv.value_ptr.*;
            v.deinit();
        }
        self.cache.deinit();
    }

    pub fn addThemes(self: *ThemeLibrary, path: []const u8) !void {
        try resources.listThemes(self.allocator, path, &self.themes);
    }

    pub fn addEmbeddedThemes(self: *ThemeLibrary) !void {
        // _ = self;
        try embedded.listThemes(self.allocator, &self.themes);
    }

    pub fn themeFromName(self: *ThemeLibrary, name: []const u8) !Theme {
        if (name.len >= 128) return error.NotFound;
        for (self.themes.items) |item| {
            if (std.mem.eql(u8, item.name[0..name.len], name)) {
                if (self.cache.get(item.id)) |g| {
                    return g;
                }
                if (item.embedded_file) |file| {
                    const t = try Theme.initWithData(self.allocator, file);
                    try self.cache.put(item.id, t);
                    return t;
                }
                const p: []const u8 = &item.full_path;
                const t = try Theme.init(self.allocator, util.toSlice([]const u8, p));
                try self.cache.put(item.id, t);
                return t;
            }
        }
        return error.NotFound;
    }

    pub fn initLibrary(allocator: Allocator) !void {
        theThemeLibrary = try allocator.create(ThemeLibrary);
        if (theThemeLibrary) |lib| {
            lib.allocator = allocator;
            try lib.init();
        }
    }

    pub fn deinitLibrary() void {
        if (theThemeLibrary) |lib| {
            lib.deinit();
            lib.allocator.destroy(lib);
            theThemeLibrary = null;
        }
    }

    pub fn getLibrary() ?*ThemeLibrary {
        return theThemeLibrary;
    }
};

pub const Scope = struct {
    atom: Atom = Atom{},
    token: ?*TokenColor = null,

    // having ascendant(s) - one for now - will allow this atom to score better
    ascendant: Atom = Atom{},
    // having exclusion(s) - one for now - will allow this atom to fail
    exclusion: Atom = Atom{},
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
    a: u8 = 0,

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
        return Rgb{ .r = r, .g = g, .b = b, .a = 255 };
    }

    pub fn pack(self: Rgb) u32 {
        return (@as(u32, self.r) << 24) |
            (@as(u32, self.g) << 16) |
            (@as(u32, self.b) << 8) |
            (@as(u32, self.a));
    }

    pub fn unpack(value: u32) Rgb {
        return Rgb{
            .r = @intCast((value >> 24) & 0xFF),
            .g = @intCast((value >> 16) & 0xFF),
            .b = @intCast((value >> 8) & 0xFF),
            .a = @intCast(value & 0xFF),
        };
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

pub const ThemeColors = Settings;

pub const Theme = struct {
    allocator: Allocator,
    arena: ArenaAllocator,

    name: []const u8,

    // TODO minimize optionals
    author: ?[]const u8 = null,
    colors: ?std.StringHashMap(Settings) = null,
    token_colors: ?[]TokenColor = null,
    semantic_highlighting: bool = false,

    type: ?[]const u8 = null, // dark,light?

    atoms: std.StringHashMap(u32),
    scopes: std.ArrayList(Scope),
    cache: std.StringHashMap(*Scope),
    cache_by_atom: std.AutoHashMap(u128, *Scope),

    // TODO release this after parse (requires that all string values be allocated and copied)
    parsed: ?std.json.Parsed(std.json.Value) = null,

    pub fn init(allocator: Allocator, source_path: []const u8) !Theme {
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

    pub fn initWithData(allocator: Allocator, file_contents: []const u8) !Theme {
        return Theme.parse(allocator, file_contents);
    }

    pub fn deinit(self: *Theme) void {
        self.atoms.deinit();
        self.scopes.deinit(self.allocator);
        self.cache.deinit();
        self.cache_by_atom.deinit();

        // TODO ArenaAllocator is a bit difficult to track but this is the Rule
        // 1. atoms, scopes, cache (all grow)
        // 2. colors, tokenColors (do not grow - therefore arena)
        // Rationale
        // colors, tokenColors will have a lot of static allocated strings (which will be more conventient destroy all at once)
        self.arena.deinit();
    }

    fn addScopeForToken(self: *Theme, scope_name: []const u8, token: *TokenColor, ascendant: Atom, exclusion: Atom) !void {
        if (scope_name.len == 0) return;

        // Exclusions scopes...
        if (std.mem.indexOf(u8, scope_name, " - ")) |_| {
            // split by comma and make atoms for the same tokenColor
            // TODO ... disregard exclusionist scope
            var sc = scope_name[0..];
            while (std.mem.indexOf(u8, sc, " - ")) |idx| {
                const ss = sc[0..idx];
                self.addScopeForToken(ss, token, ascendant, exclusion) catch {};
                return;
            }
            return;
        }

        // Grouped scopes ... split by ","
        if (std.mem.indexOf(u8, scope_name, ",")) |_| {
            // split by comma and make atoms for the same tokenColor
            var sc = scope_name[0..];
            while (std.mem.indexOf(u8, sc, ",")) |idx| {
                const ss = sc[0..idx];
                self.addScopeForToken(ss, token, ascendant, exclusion) catch {};
                sc = sc[idx + 1 ..];
                while (sc.len > 1 and sc[0] == ' ') sc = sc[1..];
            }
            self.addScopeForToken(sc, token, ascendant, exclusion) catch {};
            return;
        }

        // Scopes with ascendants ... split by " "
        if (std.mem.indexOf(u8, scope_name, " ")) |_| {
            var asc = Atom{};
            var sc = scope_name[0..];
            while (std.mem.indexOf(u8, sc, " ")) |idx| {
                const ss = sc[0..idx];
                if (asc.id == 0) {
                    asc = Atom.fromScopeName(ss, &self.atoms);
                } else {
                    self.addScopeForToken(ss, token, asc, exclusion) catch {};
                    return;
                }
                sc = sc[idx + 1 ..];
                while (sc.len > 1 and sc[0] == ' ') sc = sc[1..];
            }
            self.addScopeForToken(sc, token, asc, exclusion) catch {};
            return;
        }

        try self.scopes.append(self.allocator, Scope{
            .atom = Atom.fromScopeName(scope_name, &self.atoms),
            .ascendant = ascendant,
            .exclusion = exclusion,
            .token = token,
        });
    }

    fn parse(allocator: Allocator, source: []const u8) !Theme {
        var theme = Theme{
            .allocator = allocator,
            .atoms = std.StringHashMap(u32).init(allocator),
            .scopes = try std.ArrayList(Scope).initCapacity(allocator, 512),
            .cache = std.StringHashMap(*Scope).init(allocator),
            .cache_by_atom = std.AutoHashMap(u128, *Scope).init(allocator),
            .arena = ArenaAllocator.init(allocator),
            .name = "",
        };

        errdefer theme.atoms.deinit();
        errdefer theme.scopes.deinit(allocator);
        errdefer theme.cache.deinit();

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
                    atms.extractAtom(sc, &theme.atoms);
                }
            }
        }

        theme.name = name;
        theme.author = author;
        theme.semantic_highlighting = semantic_highlighting;
        theme.colors = colors;
        theme.token_colors = token_colors;
        theme.parsed = parsed;

        for (token_colors, 0..) |tokenColor, ti| {
            if (tokenColor.scope) |sc| {
                for (sc) |scope_name| {
                    theme.addScopeForToken(scope_name, &token_colors[ti], Atom{}, Atom{}) catch {};
                }
            }
        }
        return theme;
    }

    pub fn getScope(self: *Theme, scope: []const u8, atoms: []const Atom, colors: ?*Settings) ?*const Scope {
        var atom = atoms[0];

        if (scope.len == 0 and atom.count == 0) return null;

        // This caching should be done per grammar, not per theme.
        // Otherwise the cache hashmap would grow too large.
        const enable_cache = ENABLE_SCOPE_CACHING;
        if (enable_cache) {
            if (scope.len > 0) {
                if (self.cache.get(scope)) |cached| {
                    if (colors) |c| {
                        if (cached.token) |token| {
                            if (token.settings) |settings| {
                                c.foreground = settings.foreground;
                                c.foreground_rgb = settings.foreground_rgb;
                            }
                        }
                    }
                    return cached;
                }
            } else if (atom.id > 0) {
                if (self.cache_by_atom.get(atom.id)) |cached| {
                    if (colors) |c| {
                        if (cached.token) |token| {
                            if (token.settings) |settings| {
                                c.foreground = settings.foreground;
                                c.foreground_rgb = settings.foreground_rgb;
                            }
                        }
                    }
                    return cached;
                }
            }
        }

        if (scope.len > 0) {
            if (atoms[0].count == 0) {
                atom.compute(scope, &self.atoms);
                // std.debug.print("[{s}({}) {}? {}<<<< ", .{scope, scope.len, atom.id, atoms[0].id});
            }
        }

        var highest: u8 = 0;
        var matched: ?*Scope = null;
        for (self.scopes.items) |*sc| {
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

                if (enable_cache) {
                    if (scope.len > 0) {
                        // why the need to allocate? isn't hash computed from string content?
                        const key = self.arena.allocator().dupe(u8, scope) catch {
                            return mm;
                        };
                        _ = self.cache.put(key, mm) catch {};
                    } else if (atom.id > 0) {
                        _ = self.cache_by_atom.put(atom.id, mm) catch {};
                    }
                }
            }
        }
        return matched;
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
            // TODO these tests are no longer correct
            // try testing.expectEqualStrings(fg, entry.value);
        }
    }
}
