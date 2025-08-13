const std = @import("std");
const oni = @import("oniguruma");

var syntax_id: u32 = 1;

pub const Syntax = struct {
    id: u32 = 0,
    name: []const u8,
    content_name: []const u8,
    scope_name: []const u8,

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
    parent: ?*Syntax = null,
    is_anchored: bool = false,
    has_back_references: bool = false,

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

    // todo make use of anchors
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

        syntax.compile_all_regexes() catch {
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
                    res[i] = try Syntax.init(allocator, item);
                }
                break :blk res;
            } else {
                break :blk null;
            }
        };

        syntax.captures = try parseSyntaxMap(allocator, json, "captures", null);
        syntax.begin_captures = try parseSyntaxMap(allocator, json, "beginCaptures", null);
        syntax.while_captures = try parseSyntaxMap(allocator, json, "whileCaptures", null);
        syntax.end_captures = try parseSyntaxMap(allocator, json, "endCaptures", null);
        syntax.repository = try parseSyntaxMap(allocator, json, "repository", null);

        return syntax;
    }

    pub fn deinit(self: *Syntax) void {
        self.parent = null;

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

    pub fn compile_all_regexes(self: *Syntax) !void {
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
                // deal with back references for while and end
                if (i > 1 and Syntax.patternHasBackReference(regex)) {
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

    pub fn resolve(self: *Syntax, syntax: *const Syntax) ?*const Syntax {
        if (syntax.include_path) |include_path| {
            if (self.include) |inc_syn| {
                return inc_syn;
            }
            // std.debug.print("s:{s} find include {s}\n", .{ syntax.name, include_path });
            if (self.repository) |repo| {
                if (include_path.len > 1) {
                    const name = include_path[1..];
                    const ls = repo.get(name);
                    if (ls) |s| {
                        //std.debug.print("{s} found!\n", .{name});
                        self.include = s;
                        return s;
                    }
                    return null;
                } else {
                    //std.debug.print("(name too short)\n", .{});
                    return syntax;
                }
            }
            if (self.parent) |p| {
                return p.resolve(syntax);
            }
        }
        return syntax;
    }

    pub fn setId(self: *Syntax, id: u32) u32 {
        self.id = id;
        return self.id;
    }
};

pub const Grammar = struct {
    allocator: std.mem.Allocator,

    name: []const u8,
    syntax: *Syntax,

    syntax_id: usize = 0,
    syntax_map: std.AutoHashMap(u32, *Syntax),

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
        self.syntax.deinit();
        if (self.parsed) |*parsed| {
            parsed.deinit();
        }
    }

    pub fn parse(allocator: std.mem.Allocator, source: []const u8) !Grammar {
        const parsed = try std.json.parseFromSlice(std.json.Value, allocator, source, .{ .ignore_unknown_fields = true });
        const root = parsed.value;

        if (root != .object) return error.InvalidSyntax;
        const obj = root.object;

        // grammar meta
        const name = obj.get("name").?.string;
        const syntax = try Syntax.init(allocator, root);

        const syntax_map = std.AutoHashMap(u32, *Syntax).init(allocator);
        return Grammar{
            .allocator = allocator,
            .name = name,
            .syntax = syntax,
            .syntax_id = 0,
            .syntax_map = syntax_map,
            .parsed = parsed,
        };
    }
};
