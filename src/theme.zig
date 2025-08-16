const std = @import("std");

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
        if (target.token == null) {
            target.token = token;
        }

        if ((key.len + 1) < scope.len) {
            const next = scope[key.len + 1 ..];
            target.addScope(next, token);
        }
    }

    pub fn getScope(self: *const Scope, scope: []const u8, colors: ?*Settings) ?*const Scope {
        // std.debug.print("key: {s}\n", .{scope});
        // split
        const dot: []const u8 = ".";
        var key = scope[0..scope.len];
        if (std.mem.indexOf(u8, scope, dot)) |idx| {
            key = scope[0..idx];
        }

        // std.debug.print("checking key: {s}\n", .{key});

        const target = self.children.get(key) orelse null;
        if (target) |*t| {
            // std.debug.print("--- match {s}\n", .{key});
            if (colors) |clr| {
                if (t.token) |tk| {
                    if (tk.settings) |ss| {
                        // std.debug.print("--- {s}\n", .{ss.foreground orelse ""});
                        clr.foreground = ss.foreground;
                        clr.background = ss.background;
                    }
                }
            }
            if ((key.len + 1) < scope.len) {
                const next = scope[key.len + 1 ..];
                // std.debug.print("continuing: {s}\n", .{next});
                return t.getScope(next, colors) orelse self;
            } else {
                // std.debug.print("fully found\n", .{});
                return t;
            }
        }

        if ((key.len + 1) < scope.len) {
            const next = scope[key.len + 1 ..];
            // std.debug.print("dropping key: {s}\n", .{next});
            return self.getScope(next, colors) orelse self;
        }

        return self;
    }

    pub fn dump(self: *const Scope, depth: u8) void {
        const stdout = std.io.getStdOut().writer();
        var it = self.children.iterator();
        while (it.next()) |kv| {
            const k = kv.key_ptr.*;
            const v = kv.value_ptr.*;
            for (0..depth) |i| {
                _ = i;
                stdout.print("  ", .{}) catch {};
            }
            stdout.print("{s} ", .{k}) catch {};
            if (v.token) |tk| {
                if (tk.settings) |ts| {
                    if (ts.foreground) |fg| {
                        stdout.print("fg: {s} ", .{fg}) catch {};
                    }
                }
            }
            stdout.print("\n", .{}) catch {};
            v.dump(depth + 1);
        }
    }
};

test "test scope addToken" {
    var s: Scope = Scope.init(std.testing.allocator);
    defer s.deinit();

    s.addScope("keyword.include.c", null);
}

test "test theme" {
    var thm = try Theme.init(std.testing.allocator, "data/dracula.json");
    defer thm.deinit();

    thm.root.dump(0);

    var colors = Settings{};
    // const scope = thm.root.getScope("meta.group.toml", &colors);
    const scope = thm.root.getScope("punctuation.section.parameters.begin.bracket.round.c", &colors);
    if (scope) |sc| {
        if (sc.token) |tk| {
            if (tk.settings) |ss| {
                if (ss.foreground) |fg| {
                    std.debug.print("fg: {s}\n", .{fg});
                }
            }
        }
    }
    if (colors.foreground) |fg| {
        std.debug.print("fg: {s}\n", .{fg});
    }
}

pub const TokenColor = struct {
    name: []const u8,
    scope: ?[][]const u8 = null,
    settings: ?Settings = null,
};

pub const Settings = struct {
    foreground: ?[]const u8 = null,
    background: ?[]const u8 = null,
    fontStyle: ?[]const u8 = null,
};

pub const Theme = struct {
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,

    name: []const u8,
    author: ?[]const u8 = null,
    colors: ?std.StringHashMap([]const u8) = null,
    tokenColors: ?[]TokenColor = null,
    semanticHighlighting: bool = false,

    parsed: ?std.json.Parsed(std.json.Value) = null,

    root: Scope,

    pub fn init(allocator: std.mem.Allocator, source_path: []const u8) !Theme {
        const file = try std.fs.cwd().openFile(source_path, .{});
        defer file.close();
        const file_size = (try file.stat()).size;
        const file_contents = try file.readToEndAlloc(allocator, file_size);
        defer allocator.free(file_contents);
        return Theme.parse(allocator, file_contents);
    }

    pub fn deinit(self: *Theme) void {
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
                    // std.debug.print("{s} {s}\n", .{k, v});
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
            if (scopes) |outer| {
                for (outer) |sc| {
                    theme.root.addScope(sc, &tokenColors[i]);
                    //std.debug.print("{s}\n", .{ sc });
                }
            }
            // std.debug.print("{s} {}\n", .{ token_name, i });
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
        return self.root.getScope(scope, colors);
    }
};
