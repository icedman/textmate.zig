const std = @import("std");
const oni = @import("oniguruma");
const resources = @import("resources/resources.zig");
const embedded = @import("resources/embedded.zig");
const util = @import("util.zig");
const GrammarInfo = resources.GrammarInfo;

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

// TODO convert to hash or uuid
var syntax_id: u32 = 1;

// Regex is merely a wrapper to oni.Regex
// It adds an idenfier and points to the expression string
// It also holds other cached information

pub const Regex = struct {
    id: u64 = 0,
    expr: ?[]const u8 = null,
    regex: ?oni.Regex = null,
    has_references: bool = false,
    is_anchored: bool = false,
    is_string_block: bool = false,
    is_comment_block: bool = false,

    valid: CompileResult = .Uncompiled,
    const CompileResult = enum {
        Uncompiled,
        Valid,
        Invalid,
    };

    // TODO change to void - regex compile errors are blamed on user-defined grammars - fail silently
    pub fn compile(self: *Regex, regex: []const u8) !void {
        const re = oni.Regex.init(
            regex,
            .{},
            oni.Encoding.utf8,
            oni.Syntax.default,
            null,
        ) catch |err| {
            self.valid = .Invalid;
            return err;
        };
        errdefer re.deinit();
        self.regex = re;
        self.valid = .Valid;
        self.id = util.toHash(regex);
    }
};

pub const Syntax = struct {
    id: u64 = 0,
    name: []const u8,
    content_name: []const u8,
    scope_name: []const u8,
    scope_hash: u64 = 0,

    parent: ?*Syntax = null,

    // TODO these will replace regexs_ and regex_ pairing above
    // Wrap oni.Regex into a struct R{ id, regex_str, regex } for better caching, and sharing
    // cached compiles will be saved at the Parser?
    // cached matched will be saved Parser
    rx_match: Regex = Regex{},
    rx_begin: Regex = Regex{},
    rx_end: Regex = Regex{},
    rx_while: Regex = Regex{},

    repository: ?std.StringHashMap(*Syntax) = null,

    // children nodes
    patterns: ?[]*Syntax = null,
    captures: ?std.StringHashMap(*Syntax) = null,
    while_captures: ?std.StringHashMap(*Syntax) = null,
    begin_captures: ?std.StringHashMap(*Syntax) = null,
    end_captures: ?std.StringHashMap(*Syntax) = null,

    // include
    include_path: ?[]const u8 = null,
    include: ?*Syntax = null,

    // stats
    execs: u32 = 0,

    pub fn patternHasBackReference(ptrn: []const u8) bool {
        var escape = false;
        for (ptrn) |ch| {
            if (escape and std.ascii.isDigit(ch)) {
                return true;
            }
            escape = (!escape) and (ch == '\\');
        }
        return false;
    }

    // TODO make use of anchors
    pub fn patternHasAnchor(ptrn: []const u8) bool {
        var escape = false;
        for (ptrn, 0..) |ch, i| {
            if (escape and ch == 'G') {
                return true;
            }
            escape = (!escape) and (ch == '\\');
            if (i > 8) break;
        }
        return false;
    }

    // a syntaxMap is where a name is mapped to a syntax node
    fn parseSyntaxMap(allocator: Allocator, json: std.json.Value, field_name: []const u8, parent: ?*Syntax) !?std.StringHashMap(*Syntax) {
        if (json != .object) return error.InvalidSyntax;
        const obj = json.object;
        return blk: {
            if (obj.get(field_name)) |source| {
                if (source != .object) break :blk null;
                var res = std.StringHashMap(*Syntax).init(allocator);
                errdefer res.deinit();
                var it = source.object.iterator();
                while (it.next()) |kv| {
                    const k = kv.key_ptr.*;
                    const v = kv.value_ptr.*;
                    var syntax = try Syntax.init(allocator, v);
                    syntax.parent = parent;
                    try res.put(k, syntax);
                }
                break :blk res;
            }
            break :blk null;
        };
    }

    pub fn init(allocator: Allocator, json: std.json.Value) error{ OutOfMemory, InvalidSyntax }!*Syntax {
        if (json != .object) return error.InvalidSyntax;
        const obj = json.object;

        var syntax = try allocator.create(Syntax);
        const include = obj.get("include");
        if (include) |path| {
            syntax.* = Syntax{
                .id = @intFromPtr(syntax),
                .name = "",
                .content_name = "",
                .scope_name = "",
                .include_path = path.string,
            };
            return syntax;
        }

        syntax.* = Syntax{
            .id = @intFromPtr(syntax),
            .name = if (obj.get("name")) |v| v.string else "",
            .content_name = if (obj.get("contentName")) |v| v.string else "",
            .scope_name = if (obj.get("scopeName")) |v| v.string else "",
            .rx_match = Regex{ .expr = if (obj.get("match")) |v| v.string else null },
            .rx_begin = Regex{ .expr = if (obj.get("begin")) |v| v.string else null },
            .rx_while = Regex{ .expr = if (obj.get("while")) |v| v.string else null },
            .rx_end = Regex{ .expr = if (obj.get("end")) |v| v.string else null },
        };

        syntax.scope_hash = util.toHash(syntax.getName());
        syntax.compileAllRegexes() catch {
            std.debug.print("Failed to compile regex: // TODO which one?\n", .{});
        };

        syntax.patterns = blk: {
            const opt = obj.get("patterns");
            if (opt) |patterns_arr| {
                if (patterns_arr.array.items.len == 0) {
                    break :blk null;
                }
                const res = try allocator.alloc(*Syntax, patterns_arr.array.items.len);
                errdefer allocator.free(res);
                for (patterns_arr.array.items, 0..) |item, i| {
                    var syn = try Syntax.init(allocator, item);
                    syn.parent = syntax;
                    res[i] = syn;
                }
                break :blk res;
            } else {
                break :blk null;
            }
        };

        syntax.captures = try parseSyntaxMap(allocator, json, "captures", syntax);
        syntax.begin_captures = try parseSyntaxMap(allocator, json, "beginCaptures", syntax);
        syntax.while_captures = try parseSyntaxMap(allocator, json, "whileCaptures", syntax);
        syntax.end_captures = try parseSyntaxMap(allocator, json, "endCaptures", syntax);
        syntax.repository = try parseSyntaxMap(allocator, json, "repository", syntax);

        // std.debug.print("syntax address {*}-{*}\n", .{syntax, syntax.parent});
        return syntax;
    }

    pub fn deinit(self: *Syntax) void {
        // Syntax and its values are arena allocated
        // as they are statically created a read time
        // But match(es) and captures have oni.Regexes that have to be deinited

        // std.debug.print("deinit syntax address {*}-{*}\n", .{self, self.parent});

        const Entry = struct {
            rx_ptr: *Regex,
        };

        const entries = [_]Entry{
            .{ .rx_ptr = &self.rx_match },
            .{ .rx_ptr = &self.rx_begin },
            .{ .rx_ptr = &self.rx_while },
            .{ .rx_ptr = &self.rx_end },
        };

        // free oni.Regexes
        for (entries) |entry| {
            const r: Regex = entry.rx_ptr.*;
            if (r.regex) |*regex| {
                @constCast(regex).deinit();
            }
        }

        if (self.patterns) |pats| {
            for (pats) |*p| {
                const v = p.*;
                v.deinit();
            }
        }

        const CapturesEntry = struct {
            map_ptr: *?std.StringHashMap(*Syntax),
        };

        const capture_entries = [_]CapturesEntry{
            .{ .map_ptr = &self.repository },
            .{ .map_ptr = &self.captures },
            .{
                .map_ptr = &self.begin_captures,
            },
            .{ .map_ptr = &self.end_captures },
        };

        for (capture_entries) |entry| {
            if (entry.map_ptr.*) |*repo| {
                var it = repo.iterator();
                while (it.next()) |kv| {
                    const v = kv.value_ptr.*;
                    v.deinit();
                }
            }
        }
    }

    pub fn compileAllRegexes(self: *Syntax) !void {
        // TODO, compilation will now be done a load but only when required
        const Entry = struct {
            rx_ptr: *Regex,
        };

        const entries = [_]Entry{
            .{ .rx_ptr = &self.rx_match },
            .{ .rx_ptr = &self.rx_begin },
            .{ .rx_ptr = &self.rx_while },
            .{ .rx_ptr = &self.rx_end },
        };

        for (entries, 0..) |entry, i| {
            if (entry.rx_ptr.*.expr) |regex| {
                if (Syntax.patternHasAnchor(regex)) {
                    entry.rx_ptr.*.is_anchored = true;
                }
                const scopeName = self.getName();
                if (std.mem.indexOf(u8, scopeName, "string")) |_| {
                    entry.rx_ptr.*.is_string_block = true;
                }
                if (std.mem.indexOf(u8, scopeName, "comment")) |_| {
                    entry.rx_ptr.*.is_comment_block = true;
                }
                if (i > 1 and Syntax.patternHasBackReference(regex)) {
                    // deal with back references for while and end
                    // do not compile now, this has to be recompiled at every matched begin (applying one or more captures to the pattern)
                    entry.rx_ptr.*.has_references = true;
                    continue;
                }
                entry.rx_ptr.*.compile(regex) catch {
                    // fail silently
                };
            }
        }
    }

    pub fn resolve(self: *Syntax, syntax: *Syntax, base: ?*Syntax) ?*const Syntax {
        if (syntax.include_path) |include_path| {
            if (include_path.len == 0) return null;

            // Syntax having include_path will be resolved by finding the name on appropriate repositories
            // Some refer to external grammars repositories (source.md could require loading source.js)

            // This one has previously been resolved
            if (syntax.include) |inc_syn| {
                return inc_syn;
            }

            if (include_path[0] == '$') {
                // TODO understand $self, $base
                if (std.mem.indexOf(u8, include_path, "$self") == 0) {
                    // root?
                    var root = self;
                    while (root.parent) |p| {
                        root = p;
                    }
                    syntax.include = root;
                    return root;
                }

                if (std.mem.indexOf(u8, include_path, "$base") == 0) {
                    // base grammar?
                    // var root = self;
                    // while (root.parent) |p| {
                    //     root = p;
                    // }
                    // syntax.include = root;
                    // return root;
                    return base;
                }
            }

            // include another grammar
            if (include_path[0] == 's' and (std.mem.indexOf(u8, include_path, "source.") orelse 1) == 0) {
                // TODO Some may point to specific a syntax (source.js#comments)
                // Further resolve '#comments' in this situation
                if (GrammarLibrary.getLibrary()) |gml| {
                    const gmr = gml.grammarFromScopeName(include_path) catch {
                        return null;
                    };
                    return gmr.syntax;
                }
            }

            const key_start = 1 + (std.mem.indexOf(u8, include_path, "#") orelse 0);
            // std.debug.print("s:{s} find include {s}\n", .{ syntax.name, include_path });
            if (self.repository) |repo| {
                if (include_path.len > key_start) {
                    const name = include_path[key_start..];
                    const ls = repo.get(name);
                    if (ls) |s| {
                        syntax.include = ls;
                        return s;
                    }
                    return null;
                } else {
                    return syntax;
                }
            } else {
                // std.debug.print("no repository!\n", .{});
            }

            if (self.parent) |p| {
                // std.debug.print("check parent\n", .{});
                return p.resolve(syntax, base);
            } else {
                return null;
            }

            // std.debug.print("not found!\n", .{});
        }
        return syntax;
    }

    pub fn getName(self: *const Syntax) []const u8 {
        if (self.content_name.len > 0) {
            return self.content_name;
        }
        if (self.scope_name.len > 0) {
            return self.scope_name;
        }
        // no need to return name (match is unscoped?)
        return self.name;
    }

    pub fn dump(self: *const Syntax, depth: u32, stats: bool) void {
        for (0..depth) |i| {
            _ = i;
            std.debug.print("  ", .{});
        }

        if (self.include_path) |p| {
            std.debug.print("include {s}\n", .{p});
        } else {
            if (stats) {
                std.debug.print("{s} {}\n", .{ self.getName(), self.execs });
            } else {
                std.debug.print("{s}\n", .{self.getName()});
            }
        }

        if (self.patterns) |pats| {
            for (pats) |*p| {
                const v = p.*;
                v.dump(depth + 1, stats);
            }
        }

        // free repository
        if (self.repository) |repo| {
            var it = repo.iterator();
            while (it.next()) |kv| {
                const k = kv.key_ptr.*;
                const v = kv.value_ptr.*;
                std.debug.print("{s} ", .{k});
                v.dump(depth + 1, stats);
            }
        }
    }
};

// Grammars may load other grammars
// This will also a hold embedded grammar files.
// And optionally hold additional grammars from requested directories
var theGrammarLibrary: ?*GrammarLibrary = null;

pub const GrammarLibrary = struct {
    allocator: Allocator = undefined,
    grammars: std.ArrayList(GrammarInfo) = undefined,
    cache: std.AutoHashMap(u16, Grammar) = undefined,

    fn init(self: *GrammarLibrary) !void {
        self.grammars = try std.ArrayList(GrammarInfo).initCapacity(self.allocator, 256);
        self.cache = std.AutoHashMap(u16, Grammar).init(self.allocator);
    }

    fn deinit(self: *GrammarLibrary) void {
        self.grammars.deinit(self.allocator);
        self.cache.deinit();
    }

    pub fn addGrammars(self: *GrammarLibrary, path: []const u8) !void {
        try resources.listGrammars(self.allocator, path, &self.grammars);
    }

    pub fn addEmbeddedGrammars(self: *GrammarLibrary) !void {
        try embedded.listGrammars(self.allocator, &self.grammars);
    }

    pub fn applyInjectors(self: *GrammarLibrary, grammar: *Grammar) !void {
        if (grammar.syntax) |syntax| {
            const scope_name = syntax.scope_name;
            for (self.grammars.items) |item| {
                if (!item.inject_only) continue;
                for (0..item.inject_to_count) |fi| {
                    const np: []const u8 = &item.inject_to[fi];
                    if (std.mem.eql(u8, util.toSlice([]const u8, np), scope_name)) {
                        // TODO .. load the grammar later (use include?)
                        // add injecto to repository
                        // add include to patterns
                        // if (self.cache.get(item.id)) |g| {
                        // } else {
                        // }
                    }
                }
            }
        }
    }

    pub fn grammarFromName(self: *GrammarLibrary, name: []const u8) !Grammar {
        if (name.len >= 128) return error.NotFound;
        for (self.grammars.items) |item| {
            const np: []const u8 = &item.name;
            if (std.mem.eql(u8, util.toSlice([]const u8, np), name)) {
                if (self.cache.get(item.id)) |g| {
                    return g;
                }
                // std.debug.print("found!\n", .{});
                if (item.embedded_file) |file| {
                    return Grammar.initWithData(self.allocator, file);
                }
                const p: []const u8 = &item.full_path;
                var g = try Grammar.init(self.allocator, util.toSlice([]const u8, p));
                try self.applyInjectors(&g);
                try self.cache.put(item.id, g);
                return g;
            }
        }
        return error.NotFound;
    }

    pub fn grammarFromScopeName(self: *GrammarLibrary, name: []const u8) !Grammar {
        if (name.len >= 128) return error.NotFound;
        for (self.grammars.items) |item| {
            const np: []const u8 = &item.scope_name;
            if (std.mem.eql(u8, util.toSlice([]const u8, np), name)) {
                if (self.cache.get(item.id)) |g| {
                    return g;
                }
                // std.debug.print("found!\n", .{});
                if (item.embedded_file) |file| {
                    return Grammar.initWithData(self.allocator, file);
                }
                const p: []const u8 = &item.full_path;
                var g = try Grammar.init(self.allocator, util.toSlice([]const u8, p));
                try self.applyInjectors(&g);
                try self.cache.put(item.id, g);
                return g;
            }
        }
        return self.grammarFromName(name);
    }

    pub fn grammarFromExtension(self: *GrammarLibrary, name: []const u8) !Grammar {
        const dot_ext = std.fs.path.extension(name);
        if (dot_ext.len == 0) {
            return error.NotFound;
        }
        const ext = dot_ext[1..];
        if (ext.len >= 16) return error.NotFound;

        // Most grammar definitions don't provide fileTypes
        // check against scope name instead .. using "source.{ext}"
        var scope_name: [64]u8 = [_]u8{0} ** 64;
        var scope_name_len = "source".len;
        @memcpy(scope_name[0..scope_name_len], "source");
        scope_name_len += dot_ext.len;
        @memcpy(scope_name[6..scope_name_len], dot_ext);

        for (self.grammars.items) |item| {
            if (item.inject_only) continue;
            if (item.file_types_count > 0) {
                // Check against file types
                for (0..item.file_types_count) |fi| {
                    const np: []const u8 = &item.file_types[fi];
                    if (std.mem.eql(u8, util.toSlice([]const u8, np), ext[0..ext.len])) {
                        if (self.cache.get(item.id)) |g| {
                            return g;
                        }
                        if (item.embedded_file) |file| {
                            return Grammar.initWithData(self.allocator, file);
                        }
                        const p: []const u8 = &item.full_path;
                        var g = try Grammar.init(self.allocator, util.toSlice([]const u8, p));
                        try self.applyInjectors(&g);
                        try self.cache.put(item.id, g);
                        return g;
                    }
                }
            } else {
                // Check against scope
                // TODO move this somewhere. getByExtension is intentful, no fallback
                const np: []const u8 = &item.scope_name;
                if (std.mem.eql(u8, util.toSlice([]const u8, np), scope_name[0..scope_name_len])) {
                    if (self.cache.get(item.id)) |g| {
                        return g;
                    }
                    if (item.embedded_file) |file| {
                        return Grammar.initWithData(self.allocator, file);
                    }
                    const p: []const u8 = &item.full_path;
                    var g = try Grammar.init(self.allocator, util.toSlice([]const u8, p));
                    try self.applyInjectors(&g);
                    try self.cache.put(item.id, g);
                    return g;
                }
            }
        }
        return error.NotFound;
    }

    pub fn initLibrary(allocator: Allocator) !void {
        theGrammarLibrary = try allocator.create(GrammarLibrary);
        if (theGrammarLibrary) |lib| {
            lib.allocator = allocator;
            try lib.init();
        }
    }

    pub fn deinitLibrary() void {
        if (theGrammarLibrary) |lib| {
            lib.deinit();
            lib.allocator.destroy(lib);
            theGrammarLibrary = null;
        }
    }

    pub fn getLibrary() ?*GrammarLibrary {
        return theGrammarLibrary;
    }
};

pub const Grammar = struct {
    allocator: Allocator,
    arena: ArenaAllocator,

    name: []const u8,
    scope_name: []const u8,
    syntax: ?*Syntax = null,

    inject_to: std.ArrayList([]const u8),

    // TODO
    // firstLineMatch
    // foldingStartMarker / foldingStopMarker

    // TODO release this after parse (requires that all string values be allocated and copied)
    parsed: ?std.json.Parsed(std.json.Value) = null,

    pub fn init(allocator: Allocator, source_path: []const u8) !Grammar {
        const file = try std.fs.cwd().openFile(source_path, .{});
        defer file.close();
        const file_size = (try file.stat()).size;
        const file_contents = try file.readToEndAlloc(allocator, file_size);
        defer allocator.free(file_contents);
        // TODO apply injectors
        return Grammar.parse(allocator, file_contents);
    }

    pub fn initWithData(allocator: Allocator, file_contents: []const u8) !Grammar {
        // TODO apply injectors
        return Grammar.parse(allocator, file_contents);
    }

    pub fn deinit(self: *Grammar) void {
        if (self.syntax) |syn| {
            syn.deinit();
        }

        // TODO arena - makes allocation really abstract.. remove?
        self.inject_to.deinit(self.allocator);
        self.arena.deinit();
    }

    fn parse(allocator: Allocator, source: []const u8) !Grammar {
        var grammar = Grammar{
            .allocator = allocator,
            .inject_to = try std.ArrayList([]const u8).initCapacity(allocator, 2048),
            .arena = ArenaAllocator.init(allocator),
            .name = "",
            .scope_name = "",
        };

        // anything associated with reading the json
        // TODO reconsider arena
        const aa = grammar.arena.allocator();

        const parsed = try std.json.parseFromSlice(std.json.Value, aa, source, .{ .ignore_unknown_fields = true });
        const root = parsed.value;

        if (root != .object) return error.InvalidGrammar;
        const obj = root.object;

        // grammar meta
        const name = if (obj.get("name")) |v| v.string else "";
        const scope_name = if (obj.get("scope_name")) |v| v.string else "";
        const syntax = try Syntax.init(aa, root);

        if (obj.get("injectTo")) |inject| {
            if (inject == .array) {
                try grammar.inject_to.append(allocator, "-- placeholder --");
            }
        }

        grammar.name = name;
        grammar.scope_name = scope_name;
        grammar.syntax = syntax;
        grammar.parsed = parsed;
        syntax.scope_name = scope_name;
        return grammar;
    }
};

pub fn runTests(comptime testing: anytype, verbosely: bool) !void {
    var gmr = try Grammar.init(testing.allocator, "data/tests/c.tmLanguage.json");
    defer gmr.deinit();
    _ = verbosely;

    gmr.syntax.?.dump(0, false);
}
