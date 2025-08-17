const std = @import("std");
const oni = @import("oniguruma");

var syntax_id: u32 = 1;

pub const Syntax = struct {
    id: u32 = 0,
    name: []const u8,
    content_name: []const u8,
    scope_name: []const u8,

    parent: ?*Syntax = null,

    // regex strings
    regexs_match: ?[]const u8 = null,
    regexs_begin: ?[]const u8 = null,
    regexs_while: ?[]const u8 = null,
    regexs_end: ?[]const u8 = null,

    regex_match: ?oni.Regex = null,
    regex_begin: ?oni.Regex = null,
    regex_while: ?oni.Regex = null,
    regex_end: ?oni.Regex = null,

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

    // other internals
    is_anchored: bool = false,
    is_comment_block: bool = false,
    is_string_block: bool = false,
    has_back_references: bool = false,

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
        for (ptrn) |ch| {
            if (escape and ch == 'G') {
                return true;
            }
            escape = (!escape) and (ch == '\\');
        }
        return false;
    }

    // a syntaxMap is where a name is mapped to a syntax node
    fn parseSyntaxMap(allocator: std.mem.Allocator, json: std.json.Value, field_name: []const u8, parent: ?*Syntax) !?std.StringHashMap(*Syntax) {
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

    pub fn init(allocator: std.mem.Allocator, json: std.json.Value) error{ OutOfMemory, InvalidSyntax }!*Syntax {
        if (json != .object) return error.InvalidSyntax;
        const obj = json.object;

        const id = syntax_id;
        syntax_id += 1;

        var syntax = try allocator.create(Syntax);
        const include = obj.get("include");
        if (include) |path| {
            syntax.* = Syntax{
                .id = id,
                .name = "",
                .content_name = "",
                .scope_name = "",
                .include_path = path.string,
            };
            return syntax;
        }

        syntax.* = Syntax{
            .id = id,
            .name = if (obj.get("name")) |v| v.string else "",
            .content_name = if (obj.get("contentName")) |v| v.string else "",
            .scope_name = if (obj.get("scopeName")) |v| v.string else "",
            .regexs_match = if (obj.get("match")) |v| v.string else null,
            .regexs_begin = if (obj.get("begin")) |v| v.string else null,
            .regexs_while = if (obj.get("while")) |v| v.string else null,
            .regexs_end = if (obj.get("end")) |v| v.string else null,
        };

        // special cases for retaining captures across lines
        if (syntax.regexs_begin) |regexs| {
            if (std.mem.indexOf(u8, regexs, "string")) |_| {
                syntax.is_string_block = true;
            }
            if (std.mem.indexOf(u8, regexs, "comment")) |_| {
                syntax.is_comment_block = true;
            }
        }

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
        // std.debug.print("deinit syntax address {*}-{*}\n", .{self, self.parent});
        const Entry = struct {
            string: *const ?[]const u8,
            regex_ptr: *?oni.Regex,
        };

        const entries = [_]Entry{
            .{ .string = &self.regexs_match, .regex_ptr = &self.regex_match },
            .{ .string = &self.regexs_begin, .regex_ptr = &self.regex_begin },
            .{ .string = &self.regexs_while, .regex_ptr = &self.regex_while },
            .{ .string = &self.regexs_end, .regex_ptr = &self.regex_end },
        };

        // free regexes
        for (entries) |entry| {
            if (entry.regex_ptr.*) |*regex| {
                regex.deinit();
            }
        }

        // free patterns
        if (self.patterns) |pats| {
            for (pats) |*p| {
                const v = p.*;
                v.deinit();
            }
        }

        // free repository
        if (self.repository) |repo| {
            var it = repo.iterator();
            while (it.next()) |kv| {
                const v = kv.value_ptr.*;
                v.deinit();
            }
        }

        // free captures
        if (self.captures) |captures| {
            var it = captures.iterator();
            while (it.next()) |kv| {
                const v = kv.value_ptr.*;
                v.deinit();
            }
        }
        if (self.begin_captures) |captures| {
            var it = captures.iterator();
            while (it.next()) |kv| {
                const v = kv.value_ptr.*;
                v.deinit();
            }
        }
        if (self.end_captures) |captures| {
            var it = captures.iterator();
            while (it.next()) |kv| {
                const v = kv.value_ptr.*;
                v.deinit();
            }
        }
    }

    pub fn compileAllRegexes(self: *Syntax) !void {
        const Entry = struct {
            string: *const ?[]const u8,
            regex_ptr: *?oni.Regex,
        };

        const entries = [_]Entry{
            .{ .string = &self.regexs_match, .regex_ptr = &self.regex_match },
            .{ .string = &self.regexs_begin, .regex_ptr = &self.regex_begin },
            .{ .string = &self.regexs_while, .regex_ptr = &self.regex_while },
            .{ .string = &self.regexs_end, .regex_ptr = &self.regex_end },
        };

        for (entries, 0..) |entry, i| {
            if (entry.string.*) |regex| {
                if (i > 2 and Syntax.patternHasBackReference(regex)) {
                    // deal with back references for while and end
                    // do not compile now, this has to be recompiled at every matched begin (applying one or more captures to the pattern)
                    self.has_back_references = true;
                    continue;
                }
                const re = try oni.Regex.init(
                    regex,
                    .{},
                    oni.Encoding.utf8,
                    oni.Syntax.default,
                    null,
                );
                errdefer re.deinit();
                entry.regex_ptr.* = re;
            }
        }
    }

    pub fn resolve(self: *Syntax, syntax: *Syntax) ?*const Syntax {
        if (syntax.include_path) |include_path| {
            // syntax having include_path will be resolved by finding the name on appropriate repositories
            // TODO handle external grammar repositories (source.md could require loading source.js)
            if (syntax.include) |inc_syn| {
                return inc_syn;
            }

            // TODO understand $self, $base
            if (std.mem.indexOf(u8, include_path, "$self") == 0) {
                return syntax;
            }
            if (std.mem.indexOf(u8, include_path, "$base") == 0) {
                // root
                var root = self;
                while (root.parent) |p| {
                    root = p;
                }
                return root;
            }

            const key_start = 1 + (std.mem.indexOf(u8, include_path, "#") orelse 0);
            // this is where other grammar reference is checked.. ie source.js or source.js#pattern-name

            // std.debug.print("s:{s} find include {s}\n", .{ syntax.name, include_path });
            if (self.repository) |repo| {
                // std.debug.print("check repo\n", .{});
                if (include_path.len > key_start) {
                    const name = include_path[key_start..];
                    // std.debug.print("finding {s}\n", .{name});
                    const ls = repo.get(name);
                    if (ls) |s| {
                        // std.debug.print("{s} found!\n", .{name});
                        syntax.include = ls;
                        return s;
                    }
                    return null;
                } else {
                    //std.debug.print("(name too short)\n", .{});
                    return syntax;
                }
            } else {
                // std.debug.print("no repository!\n", .{});
            }
            if (self.parent) |p| {
                // std.debug.print("check parent\n", .{});
                return p.resolve(syntax);
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

pub const Grammar = struct {
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,

    name: []const u8,
    syntax: ?*Syntax = null,

    // TODO release this after parse (requires that all string values by allocated and copied)
    parsed: ?std.json.Parsed(std.json.Value) = null,

    pub fn init(allocator: std.mem.Allocator, source_path: []const u8) !Grammar {
        const file = try std.fs.cwd().openFile(source_path, .{});
        defer file.close();
        const file_size = (try file.stat()).size;
        const file_contents = try file.readToEndAlloc(allocator, file_size);
        defer allocator.free(file_contents);
        return Grammar.parse(allocator, file_contents);
    }

    pub fn deinit(self: *Grammar) void {
        if (self.syntax) |syntax| {
            syntax.deinit();
        }
        if (self.parsed) |parsed| {
            parsed.deinit();
        }
        self.arena.deinit();
    }

    pub fn parse(allocator: std.mem.Allocator, source: []const u8) !Grammar {
        var grammar = Grammar{
            .allocator = allocator,
            .arena = std.heap.ArenaAllocator.init(allocator),
            .name = "",
        };

        // anything associated with reading the json
        // TODO reconsider arena
        const aa = grammar.arena.allocator();

        const parsed = try std.json.parseFromSlice(std.json.Value, aa, source, .{ .ignore_unknown_fields = true });
        const root = parsed.value;

        if (root != .object) return error.InvalidSyntax;
        const obj = root.object;

        // grammar meta
        const name = obj.get("name").?.string;
        const syntax = try Syntax.init(aa, root);

        grammar.name = name;
        grammar.syntax = syntax;
        grammar.parsed = parsed;

        return grammar;
    }
};

pub fn runTests(comptime testing: anytype, verbosely: bool) !void {
    var gmr = try Grammar.init(testing.allocator, "data/tests/c.tmLanguage.json");
    defer gmr.deinit();
    _ = verbosely;

    gmr.syntax.?.dump(0, false);
}
