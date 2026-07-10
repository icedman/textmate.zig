const std = @import("std");
const oni = @import("oniguruma");
const grammar = @import("grammar.zig");
const strings = @import("strings.zig");
const atoms = @import("atoms.zig");
const scope = @import("scopes.zig");
const config = @import("config.zig");
const processor = @import("processor/processor.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Syntax = grammar.Syntax;
const Rule = grammar.Rule;
const Atom = atoms.Atom;
const StringsArena = strings.StringsArena;

// capture is like MatchRange.. but atomic and should be serializable
pub const ParseCapture = struct {
    start: usize = 0,
    end: usize = 0,

    scope: []const u8 = "",
    atom: Atom = Atom{},

    syntax: ?*Syntax = null,
};

const Capture = ParseCapture;

// the lighter version of Capture, used internally
const MatchRange = struct {
    group: u16 = 0,
    start: usize = 0,
    end: usize = 0,
};

// every findMatch productes a Match, with MatchRanges holding the captured groups
const Match = struct {
    syntax: ?*Syntax = null,
    regex: ?*Rule = null,

    // is this expensive to pass around (copy)
    ranges: [config.max_match_ranges]MatchRange = undefined,
    count: u8 = 0,

    // this is just start and end of ranges[0]
    start: usize = 0,
    end: usize = 0,

    // search anchors are the start and end of block sliced passed to findMatch
    anchor_start: usize = 0,
    anchor_end: usize = 0,

    // TODO output: ArrayList(u8) vs output *[MAX_SCOPE_LEN]u8 ...
    fn applyRef(
        self: *const Match,
        block: []const u8,
        target: []const u8,
        escape_character: u8,
        output: *ArrayListUnmanaged(u8),
        allocator: Allocator,
    ) !usize {
        var escape = false;
        var skip: usize = 0;
        for (target, 0..) |ch, idx| {
            if (skip > 0) {
                skip -= 1;
                continue;
            }
            if (escape and std.ascii.isDigit(ch)) {
                const digit: u8 = blk: {
                    const d = ch - '0';
                    if (config.max_match_ranges > 9 and idx + 1 < target.len) {
                        // check for another digit if allowed the config
                        const ch2 = target[idx + 1];
                        if (std.ascii.isDigit(ch2)) {
                            const d2 = ch2 - '0';
                            skip = 1;
                            const dd = (d * 10) + d2;
                            break :blk dd;
                        }
                    }
                    break :blk d;
                };
                var found = false;
                for (0..self.count) |i| {
                    const r = self.ranges[i];
                    if (digit == r.group) {
                        _ = output.pop().?;
                        for (r.start..r.end) |bi| {
                            const rch = block[bi];
                            if (rch == '*' or rch == '.') {
                                try output.append(allocator, '\\');
                            }
                            try output.append(allocator, rch);
                        }
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    _ = output.pop().?;
                }
            } else {
                try output.append(allocator, ch);
            }
            escape = (!escape) and (ch == escape_character);
        }

        // std.debug.print("{s}\n", .{output});
        return output.items.len;
    }

    pub fn applyReferences(
        self: *const Match,
        block: []const u8,
        target: []const u8,
        output: *ArrayListUnmanaged(u8),
        allocator: Allocator,
    ) !usize {
        return try self.applyRef(block, target, '\\', output, allocator);
    }

    pub fn applyCaptures(
        self: *const Match,
        block: []const u8,
        target: []const u8,
        output: *ArrayList(u8),
        allocator: Allocator,
    ) !usize {
        return try self.applyRef(block, target, '$', output, allocator);
    }

    pub fn dump(self: *const Match, block: []const u8) void {
        _ = block;
        for (0..self.count) |i| {
            const r = self.ranges[i];
            const s = r.start;
            const e = r.end;
            _ = s;
            _ = e;
            // std.debug.print("{} {s}\n", .{ i, block[s..e] });
        }
    }
};

// StateContext holds the context of a single character match is made for a Syntax
// It is store only if the Syntax would require further matching with its children patterns
// This should be serializable as this is what the parse state stack contains
const StateContextPack = packed struct {
    syntax: u64,
    anchor_start: u32,
    start: u32,
    rx_while: u64,
    rx_end: u64,
};
const StateContext = struct {
    syntax: *Syntax,

    // The match position of the character relative to the line start
    anchor_start: u32 = 0,
    start: u32 = 0,
    zero_width_begin: bool = false,

    // Parser owns these at regex_map and responsible for oni.Regex.deinit not StateContext
    rx_while: Rule = Rule{},
    rx_end: Rule = Rule{},
    anchor_position: i32 = -1,

    pub fn serialize(self: *StateContext, parser: *Parser) StateContextPack {
        _ = parser;
        return .{
            self.syntax.id,
            self.anchor_start,
            self.start,
            self.rx_while.id,
            self.rx_end.id,
        };
    }

    pub fn deserialize(self: *StateContext, parser: *Parser, serial: StateContextPack) !void {
        self.syntax = @ptrFromInt(serial.syntax);
        self.anchor_start = serial.anchor_start;
        self.start = serial.start;
        self.rx_end = parser.regex_map.get(serial.rx_end) orelse Rule{};
        self.rx_while = parser.regex_map.get(serial.rx_while) orelse Rule{};
    }
};

/// ParseState is a StateContext stack
/// This should be (de)serializable
pub const ParseState = struct {
    allocator: Allocator,
    stack: std.ArrayList(StateContext),
    owner: *Parser = undefined,

    pub fn init(owner: *Parser, allocator: Allocator, syntax: *Syntax) !ParseState {
        var stack = try std.ArrayList(StateContext).initCapacity(allocator, 32);
        try stack.append(allocator, StateContext{
            .syntax = syntax,
        });
        return ParseState{
            .allocator = allocator,
            .stack = stack,
            .owner = owner,
        };
    }

    pub fn deinit(self: *ParseState) void {
        self.stack.deinit(self.allocator);
    }

    pub fn top(self: *ParseState) ?StateContext {
        if (self.stack.items.len > 0) {
            return self.stack.items[self.stack.items.len - 1];
        } else {
            return null;
        }
    }

    pub fn at(self: *ParseState, idx: usize) ?StateContext {
        if (idx < self.stack.items.len) {
            return self.stack.items[idx];
        } else {
            return null;
        }
    }

    pub fn pop(self: *ParseState, where: []const u8) void {
        if (self.stack.items.len > 0) {
            _ = self.stack.pop();
            _ = where;
            // std.debug.print("state pop {} - {s}\n", .{ self.size(), where });
        }
    }

    pub fn push(self: *ParseState, syntax: *Syntax, rx: *Rule, block: []const u8, match: Match, where: []const u8) !void {
        var sc = StateContext{
            .syntax = syntax,
            .anchor_start = @intCast(match.anchor_start),
            .start = @intCast(match.start),
            .zero_width_begin = (match.start == match.end),
            .anchor_position = @intCast(match.end),
        };

        _ = rx;

        const m = match;
        {
            var output_buf: [256]u8 = undefined;

            if (syntax.rx_end.has_references) {
                if (syntax.rx_end.expr) |regexs| {
                    var output = std.ArrayListUnmanaged(u8).initBuffer(&output_buf);

                    _ = try m.applyReferences(block, regexs, &output, self.allocator);
                    const expr = try self.owner.strings.appendUnique(output.items);
                    const regex_id = strings.toHash(expr);
                    {
                        if (self.owner.regex_map.get(regex_id)) |r| {
                            sc.rx_end = r;
                        } else {
                            // std.debug.print("compile {s} < {s} {s}<\n", .{ regexs, expr, block });
                            sc.rx_end.compile(expr) catch {
                                // std.debug.print("compile {s} < {s} {s} matches:{}<\n", .{ regexs, expr, block, m.count });
                                // std.debug.print("unable to compile {s} < {s}<\n", .{ regexs, expr });
                                // m.dump(block);
                                // if unable to compile... don't push otherwise we won't be able to exit
                                return;
                            };
                            if (sc.rx_end.id > 0) {
                                // std.debug.print("{} {s} {}\n", .{sc.rx_end.id, expr, expr.len});
                                try self.owner.regex_map.put(sc.rx_end.id, sc.rx_end);
                            }
                        }
                        sc.rx_end.expr = expr;
                    }
                }
                if (syntax.rx_while.has_references) {
                    if (syntax.rx_while.expr) |regexs| {
                        var output = std.ArrayListUnmanaged(u8).initBuffer(&output_buf);

                        _ = try m.applyReferences(block, regexs, &output, self.allocator);
                        const expr = try self.owner.strings.appendUnique(output.items);
                        const regex_id = strings.toHash(expr);
                        {
                            if (self.owner.regex_map.get(regex_id)) |r| {
                                sc.rx_while = r;
                            } else {
                                sc.rx_while.compile(expr) catch {
                                    // std.debug.print("unable to compile {s} < {s}<\n", .{ regexs, expr });
                                };
                                if (sc.rx_while.id > 0) {
                                    try self.owner.regex_map.put(sc.rx_while.id, sc.rx_while);
                                }
                            }
                            sc.rx_while.expr = expr;
                        }
                    }
                }
            }
        }

        _ = try self.stack.append(self.allocator, sc);
        _ = where;
        // std.debug.print("push {s}\n", .{syntax.getName()});
    }

    pub fn size(self: *ParseState) usize {
        return self.stack.items.len;
    }

    // TODO isn't there something like toString for fmt?
    pub fn dump(self: *ParseState) void {
        const state_depth = self.size();
        for (0..state_depth) |i| {
            const ctx = self.at(i);
            if (ctx) |t| {
                const ts = t.syntax;
                const ls = ts.resolve(ts, t.syntax);
                if (ls) |syn| {
                    _ = syn;
                    // std.debug.print("{} {*} {s}\n", .{ i, syn, syn.getName() });
                    // if (syn.rx_match.expr) |r| {
                    //     std.debug.print("  match: {s}\n", .{r});
                    // }
                    // if (syn.rx_begin.expr) |r| {
                    //     std.debug.print("  begin: {s}\n", .{r});
                    //     std.debug.print("  end: {s}\n", .{syn.rx_end.expr orelse ""});
                    // }
                }
            }
        }
    }
};

// Parser is where the heavy work is done
// It parses a single line but can receive ParseState from a previous line parse for continuance
pub const Parser = struct {
    allocator: Allocator,
    lang: *grammar.Grammar,

    // processor
    processor: ?*processor.Processor = null,

    // Cache for line parsing
    // syntax level cache
    match_cache: std.AutoHashMap(u64, Match),
    // regex level cache
    exec_cache: std.AutoHashMap(u64, Match),
    // matches at line parse - to watch endless loops
    begin_matches: std.ArrayList(Match),

    // runtime-compiled (with dynamic patterns) are save for sharing a (de)serialization
    regex_map: std.AutoHashMap(u64, grammar.Rule),

    // optionally attach a theme's atoms here for faster scope resolution
    atoms: ?*std.StringHashMap(u32) = null,

    strings: StringsArena,
    transient_strings: StringsArena,
    first_line: bool = false,
    cycle_detected: bool = false,
    current_anchor_position: i32 = -1,

    // stats
    regex_execs: u32 = 0,
    regex_skips: u32 = 0,
    total_pats: usize = 0,
    deepest: u32 = 0,

    current_state: ?*ParseState = null,

    pub fn init(allocator: Allocator, lang: *grammar.Grammar) !Parser {
        return Parser{
            .allocator = allocator,
            .lang = lang,
            .match_cache = std.AutoHashMap(u64, Match).init(allocator),
            .exec_cache = std.AutoHashMap(u64, Match).init(allocator),
            .begin_matches = try std.ArrayList(Match).initCapacity(allocator, 32),
            .regex_map = std.AutoHashMap(u64, grammar.Rule).init(allocator),
            .strings = try StringsArena.init(allocator),
            .transient_strings = try StringsArena.init(allocator),
        };
    }

    pub fn deinit(self: *Parser) void {
        self.match_cache.deinit();
        self.exec_cache.deinit();
        self.begin_matches.deinit(self.allocator);

        var it = self.regex_map.iterator();
        while (it.next()) |kv| {
            const v = kv.value_ptr.*;
            if (v.regex) |*r| {
                @constCast(r).deinit();
            }
        }
        self.regex_map.deinit();
        self.strings.deinit();
        self.transient_strings.deinit();
    }

    pub fn initState(self: *Parser) !ParseState {
        if (self.lang.syntax) |s| {
            return ParseState.init(self, self.allocator, s);
        }
        return error.InvalidGrammar;
    }

    fn getAnchorPosition(self: *Parser) i32 {
        if (self.current_state) |state| {
            if (state.top()) |t| {
                // std.debug.print("getAnchorPosition top={s} anchor={}\n", .{ t.syntax.getName(), t.anchor_position });
                return t.anchor_position;
            }
        }
        return -1;
    }

    fn getLastMatchPositions(self: *Parser) Match {
        if (self.current_state) |state| {
            const top = state.top();
            if (top) |t| {
                return Match{ .anchor_start = t.anchor_start, .start = t.start };
            }
        }
        return Match{};
    }

    // findMatch. Regular expression matching. This is where all the CPU usage goes.
    fn findMatch(self: *Parser, syntax: *Syntax, rx: *Rule, regex: ?oni.Regex, block: []const u8, start: usize, end: usize) Match {
        // std.debug.print("findMatch syntax='{s}' pattern='{s}' start={} end={} anchor_pos={}\n", .{ syntax.getName(), rx.expr orelse "", start, end, self.current_anchor_position });

        if (regex) |*re| {
            if (rx.is_anchored_at_start and !self.first_line) {
                return Match{};
            }
            // check cache
            var should_cache = false;

            syntax.execs += 1;
            self.regex_execs += 1;
            const hard_start: usize = start;
            const anchor_pos = self.current_anchor_position;
            if (rx.is_anchored) {
                // \G in oniguruma means start of previous match

                // when pattern is merely "\\G", it is merely to re-assert matching at the last matched position
                // in this case, simulate a successful match
                if (rx.is_anchor_assertion) {
                    if (anchor_pos == -1 or hard_start != @as(usize, @intCast(anchor_pos))) {
                        return Match{};
                    }
                    var m = Match{
                        .syntax = syntax,
                        .regex = rx,
                        .anchor_start = hard_start,
                        .anchor_end = hard_start,
                        .ranges = [_]MatchRange{MatchRange{ .group = 0, .start = 0, .end = 0 }} ** config.max_match_ranges,
                    };
                    m.count = 1;
                    m.start = hard_start;
                    m.end = hard_start;
                    return m;
                }
            }
            const hard_end: usize = end;

            if (rx.valid == .Valid and config.enable_exec_caching) {
                should_cache = !rx.is_anchored and !rx.is_anchored_at_start;
                if (should_cache) {
                    if (self.exec_cache.get(rx.id)) |mm| {
                        if (mm.anchor_start == hard_start and mm.start > hard_start) {
                            // std.debug.print("findMatch cache {s} {} {}-{}\n", .{rx.expr orelse "", start, mm.start, mm.end});
                            self.regex_skips += 1;
                            var res = mm;
                            res.syntax = syntax;
                            res.regex = rx;
                            return res;
                        }
                        if (mm.anchor_start == hard_start and mm.count == 0) {
                            self.regex_skips += 1;
                            var res = mm;
                            res.syntax = syntax;
                            res.regex = rx;
                            return res;
                        }
                    }
                }
            }

            const not_begin_pos = blk: {
                if (rx.is_anchored) {
                    break :blk (anchor_pos == -1 or hard_start != @as(usize, @intCast(anchor_pos)));
                }
                break :blk false;
            };

            const reg = blk: {
                var result: oni.Region = .{};
                _ = @constCast(re).searchAdvanced(block, hard_start, hard_end, &result, .{
                    .not_begin_string = false,
                    .not_end_string = (hard_start != hard_end and block[hard_end - 1] == '\n'),
                    .not_begin_position = not_begin_pos,
                }) catch |err| {
                    if (err == error.Mismatch) {
                        break :blk null; // return null instead
                    } else {
                        return Match{};
                    }
                };
                break :blk result;
            };

            if (reg) |*r| {
                defer @constCast(r).deinit();
                var m = Match{
                    .syntax = syntax,
                    .regex = rx,
                    .anchor_start = hard_start,
                    .anchor_end = hard_end,
                    .ranges = [_]MatchRange{MatchRange{ .group = 0, .start = 0, .end = 0 }} ** config.max_match_ranges,
                };

                // if (r.count() > 0) {
                //     std.debug.print("findMatch {} [{s}] {s}\n", .{rx.id, block, rx.expr orelse ""});
                // }

                var count: u8 = 0;
                var i: u16 = 0;
                const starts = r.starts();
                const ends = r.ends();
                while (i < r.count() and i < config.max_match_ranges) : (i += 1) {
                    if (starts[i] < 0) {
                        // m.ranges[count].group = i;
                        // m.ranges[count].start = 0;
                        // m.ranges[count].end = 0;
                        // count += 1;
                        // -1 could happen in oniguruma when an optional capture group didn't match
                        // case: when no newline '\n' is present (c.tmLanguage)
                        continue;
                    }
                    const s: usize = @intCast(starts[i]);
                    const e: usize = @intCast(ends[i]);
                    // suite1 #46 remove this if .. but fix endless loop first
                    if (s >= start) {
                        m.ranges[count].group = i;
                        m.ranges[count].start = s;
                        m.ranges[count].end = e;
                        if (count == 0) {
                            m.start = s;
                            m.end = e;
                        }
                        // std.debug.print("{}-{}: {s}\n", .{ s, e, block[m.ranges[count].start..m.ranges[count].end] });
                        count += 1;
                    } else {
                        // std.debug.print("skipped {}-{} {s}\n", .{ s, e, block[m.ranges[count].start..m.ranges[count].end] });
                    }
                }

                m.count = count;

                // if (count > 0) {
                // std.debug.print(">>>>>>>>>>>{s}\n", .{rx.expr orelse ""});
                // std.debug.print("{} {}\n", .{m.start, m.end});
                // std.debug.print("{s}\n", .{syntax.getName()});
                // std.debug.print("{s}\n", .{syntax.scope_name});
                // std.debug.print("{s}\n", .{syntax.content_name});
                // }

                if (should_cache and (m.count == 0 or (m.count > 0 and m.start > hard_start))) {
                    if (!rx.is_anchored and !rx.is_anchored_at_start) {
                        self.exec_cache.put(rx.id, m) catch {};
                    }
                }

                return m;
            }
        }

        return Match{};
    }

    /// matchBegin is where the regex patterns are checked.
    /// It is also where caching would(should) be done
    /// Caching is based on:
    /// 1. position-expression.
    ///     - Cache the result of expression executed against a block at a specific position
    ///     - Some rules may have nested loops hence expressions may be checked more than once
    /// 2. > position-expression.
    ///     - Cache also matches with match position ahead of current position
    ///     - Matched expression may be defeated by earlier matches but it may be usefyl as current position moves forward
    fn matchBegin(self: *Parser, syntax_: *Syntax, block: []const u8, start: usize, end: usize) Match {
        // guard against unresolved syntax being passed
        const syntax = @constCast(syntax_.resolve(syntax_, self.lang.syntax) orelse syntax_);
        self.current_anchor_position = @intCast(start);

        // match
        if (syntax.rx_match.valid == .Valid) {
            if (syntax.rx_match.regex) |regex| {
                // check of matching has been previously cached (for the same position in the buffer)
                var should_cache = false;
                const m = blk: {
                    if (syntax.rx_match.is_anchored or syntax.rx_match.is_anchored_at_start) {
                        break :blk null;
                    }
                    const mm = self.match_cache.get(syntax.rx_match.id) orelse {
                        should_cache = true;
                        break :blk null;
                    };
                    if (mm.anchor_start <= start and mm.start >= start) {
                        self.regex_skips += 1;
                        var res = mm;
                        res.syntax = syntax;
                        res.regex = &syntax.rx_match;
                        break :blk res;
                    }
                    if (mm.anchor_start <= start and mm.count == 0) {
                        self.regex_skips += 1;
                        var res = mm;
                        res.syntax = syntax;
                        res.regex = &syntax.rx_match;
                        break :blk res;
                    }
                    break :blk null;
                } orelse self.findMatch(syntax, &syntax.rx_match, regex, block, start, end);

                // if (m.count > 0) {
                //     std.debug.print("{s}\n\t {s} {s} {}\n", .{syntax.rx_match.expr orelse "", syntax.getName(), block[start..end], m.count});
                // }

                if (should_cache and config.enable_match_caching and m.count == 0) {
                    if (syntax.rx_match.id != 0 and !syntax.rx_match.is_anchored and !syntax.rx_match.is_anchored_at_start)
                        _ = self.match_cache.put(syntax.rx_match.id, m) catch {};
                }
                if (m.count > 0) {
                    return m;
                }
            }
        }

        // begin
        if (syntax.rx_begin.valid == .Valid) {
            if (syntax.rx_begin.regex) |regex| {
                // check of matching has been previously cached (for the same position in the buffer)
                var should_cache = false;
                const m = blk: {
                    if (syntax.rx_begin.is_anchored or syntax.rx_begin.is_anchored_at_start) {
                        break :blk null;
                    }
                    const mm = self.match_cache.get(syntax.rx_begin.id) orelse {
                        should_cache = true;
                        break :blk null;
                    };
                    if (mm.anchor_start <= start and mm.start >= start) {
                        self.regex_skips += 1;
                        var res = mm;
                        res.syntax = syntax;
                        res.regex = &syntax.rx_begin;
                        break :blk res;
                    }
                    if (mm.anchor_start <= start and mm.count == 0) {
                        self.regex_skips += 1;
                        var res = mm;
                        res.syntax = syntax;
                        res.regex = &syntax.rx_begin;
                        break :blk res;
                    }
                    break :blk null;
                } orelse self.findMatch(syntax, &syntax.rx_begin, regex, block, start, end);

                if (self.hasCycle(m)) {
                    // disqualify
                    return Match{};
                }

                if (should_cache and config.enable_match_caching and m.count == 0) {
                    if (!syntax.rx_begin.is_anchored and !syntax.rx_begin.is_anchored_at_start)
                        _ = self.match_cache.put(syntax.rx_begin.id, m) catch {};
                }

                if (m.count > 0) {
                    return m;
                }
            }
        }

        // if (syntax.rx_end.regex != null or syntax.rx_while.regex != null) {
        //     return Match{};
        // }

        // if all this syntax has are patterns, check patterns
        if (syntax.rx_match.expr == null and syntax.rx_begin.expr == null) {
            return self.matchPatterns(syntax, syntax.patterns, block, start, end);
        }

        return Match{};
    }

    pub fn matchWhile(self: *Parser, state: *ParseState, block: []const u8) !Match {
        var start: usize = 0;
        const end = block.len;
        var i: usize = 1;
        var last_successful_match = Match{};

        while (i < state.stack.items.len) {
            const ctx = &state.stack.items[i];
            const syn = ctx.syntax;
            const ls = syn.resolve(syn, self.lang.syntax) orelse syn;

            if (ls.rx_while.expr != null) {
                ctx.anchor_position = @intCast(start);
                self.current_anchor_position = ctx.anchor_position;
                const m: Match = blk: {
                    if (ctx.rx_while.valid == .Valid) {
                        break :blk self.findMatch(@constCast(ls), @constCast(&ls.rx_while), ctx.rx_while.regex, block, start, end);
                    }
                    if (ls.rx_while.regex) |r| {
                        break :blk self.findMatch(@constCast(ls), @constCast(&ls.rx_while), r, block, start, end);
                    }
                    break :blk Match{ .count = 1, .start = start, .end = start };
                };

                if (m.count == 0) {
                    while (state.stack.items.len > i) {
                        const pop_ctx = state.stack.items[state.stack.items.len - 1];
                        if (self.processor) |proc| {
                            if (pop_ctx.syntax.content_name.len > 0) {
                                var c = ParseCapture{
                                    .start = start,
                                    .end = start,
                                    .syntax = pop_ctx.syntax,
                                    .atom = pop_ctx.syntax.atom,
                                    .scope = pop_ctx.syntax.content_name,
                                };
                                proc.closeTag(&c);
                            }
                            if (pop_ctx.syntax.name.len > 0) {
                                var c = ParseCapture{
                                    .start = start,
                                    .end = start,
                                    .syntax = pop_ctx.syntax,
                                    .atom = pop_ctx.syntax.atom,
                                    .scope = pop_ctx.syntax.name,
                                };
                                proc.closeTag(&c);
                            } else if (pop_ctx.syntax.name.len == 0 and pop_ctx.syntax.scope_name.len > 0) {
                                var c = ParseCapture{
                                    .start = start,
                                    .end = start,
                                    .syntax = pop_ctx.syntax,
                                    .atom = pop_ctx.syntax.atom,
                                    .scope = pop_ctx.syntax.scope_name,
                                };
                                proc.closeTag(&c);
                            }
                        }
                        state.pop("matchWhile");
                    }
                    break;
                } else {
                    if (ls.while_captures) |*while_cap| {
                        try self.collectCaptures(&m, while_cap, block);
                    } else if (ls.captures) |*cap| {
                        try self.collectCaptures(&m, cap, block);
                    }

                    ctx.start = @intCast(m.end);
                    ctx.anchor_start = @intCast(m.start);

                    start = m.end;
                    last_successful_match = m;
                    i += 1;
                }
            } else {
                i += 1;
            }
        }

        if (start > 0) {
            return last_successful_match;
        }
        return Match{};
    }

    /// TODO matchEnd must also be cached. Also, some end expressions are similar (should also be cached)
    pub fn matchEnd(self: *Parser, state: *ParseState, block: []const u8, start: usize, end: usize) Match {
        // prune if the stack is already too deep like deeply nested blocks
        // This is merely now guard against intentionally written code
        // if (state.size() > config.max_state_stack_depth) {
        //     if (state.stack.items.len >= config.max_state_stack_depth) {
        //         const new_len = state.stack.items.len - config.state_stack_prune;
        //         @memcpy(
        //             state.stack.items[0..new_len],
        //             state.stack.items[config.state_stack_prune..state.stack.items.len],
        //         );
        //         state.stack.items.len = new_len;
        //     }
        // }

        const top = state.top();
        if (top) |t| {
            const syn = t.syntax;
            // std.debug.print("matchEnd state={*} top={s} t.anchor_position={}\n", .{ state, syn.getName(), t.anchor_position });
            self.current_anchor_position = t.anchor_position;
            {
                var end_match: Match = blk: {
                    if (t.rx_end.valid == .Valid) {
                        // use dynamic end_regex here if one was compiled
                        // not caching or result in this case
                        const m = self.findMatch(@constCast(syn), @constCast(&t.rx_end), t.rx_end.regex, block, start, end);
                        // std.debug.print(">>>[{s}] match:{s} {} {}-{}\n", .{ block, t.rx_end.expr orelse "", m.count, start, end });
                        break :blk m;
                    }

                    // end_match with caching
                    var should_cache = false;
                    const m = inner_blk: {
                        if (syn.rx_end.is_anchored or syn.rx_end.is_anchored_at_start) {
                            break :inner_blk null;
                        }
                        const mm = self.match_cache.get(syn.rx_end.id) orelse {
                            should_cache = true;
                            break :inner_blk null;
                        };
                        if (mm.anchor_start <= start and mm.start >= start) {
                            self.regex_skips += 1;
                            var res = mm;
                            res.syntax = @constCast(syn);
                            res.regex = &syn.rx_end;
                            break :inner_blk res;
                        }
                        if (mm.anchor_start <= start and mm.count == 0) {
                            self.regex_skips += 1;
                            var res = mm;
                            res.syntax = @constCast(syn);
                            res.regex = &syn.rx_end;
                            break :inner_blk res;
                        }
                        break :inner_blk null;
                    } orelse self.findMatch(@constCast(syn), @constCast(&syn.rx_end), syn.rx_end.regex, block, start, end);

                    if (should_cache and config.enable_end_caching) {
                        if (!syn.rx_end.is_anchored and !syn.rx_end.is_anchored_at_start)
                            _ = self.match_cache.put(syn.rx_end.id, m) catch {};
                    }

                    break :blk m;
                };
                if (t.zero_width_begin and end_match.count > 0 and end_match.start == t.start and end_match.end == t.start) {
                    end_match.count = 0;
                }
                if (end_match.count > 0) {
                    return end_match;
                }
            }
        }

        return Match{};
    }

    fn matchPatterns(self: *Parser, syntax: *const Syntax, patterns: ?std.ArrayList(*Syntax), block: []const u8, start: usize, end: usize) Match {
        var earliest_match = Match{};

        var left_injections_buffer: [32]*Syntax = undefined;
        var left_injections = std.ArrayListUnmanaged(*Syntax).initBuffer(&left_injections_buffer);

        var right_injections_buffer: [32]*Syntax = undefined;
        var right_injections = std.ArrayListUnmanaged(*Syntax).initBuffer(&right_injections_buffer);

        if (syntax.scope_name.len > 0) {
            if (self.current_state) |state| {
                var scopes_buffer: [64][]const u8 = undefined;
                var scopes = std.ArrayListUnmanaged([]const u8).initBuffer(&scopes_buffer);

                for (state.stack.items) |ctx| {
                    const name = ctx.syntax.getName();
                    if (name.len > 0) {
                        var it = std.mem.splitScalar(u8, name, ' ');
                        while (it.next()) |tok| {
                            if (tok.len > 0) {
                                scopes.append(self.allocator, tok) catch {};
                            }
                        }
                    }
                }

                if (scopes.items.len > 0) {
                    // Collect injections from self.lang
                    if (self.lang.syntax) |root_syn| {
                        if (root_syn.injections) |*injs| {
                            var inj_it = injs.iterator();
                            while (inj_it.next()) |inj_kv| {
                                const selector = inj_kv.key_ptr.*;
                                const inj_node = inj_kv.value_ptr.*;
                                if (scope.matchesScopeSelector(scopes.items, selector)) {
                                    var is_right = false;
                                    var alt_it = std.mem.splitScalar(u8, selector, ',');
                                    while (alt_it.next()) |alt| {
                                        const trimmed = std.mem.trim(u8, alt, " \t\r\n");
                                        if (std.mem.startsWith(u8, trimmed, "R:")) {
                                            is_right = true;
                                            break;
                                        }
                                    }
                                    if (inj_node.patterns) |inj_pats| {
                                        for (inj_pats.items) |ip| {
                                            if (is_right) {
                                                right_injections.appendBounded(ip) catch {};
                                            } else {
                                                left_injections.appendBounded(ip) catch {};
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Collect injections from other loaded grammars
                    if (grammar.GrammarLibrary.getLibrary()) |gml| {
                        var cache_it = gml.cache.iterator();
                        while (cache_it.next()) |kv| {
                            const g = kv.value_ptr.*;
                            if (g == self.lang) continue;
                            if (g.syntax) |root_syn| {
                                if (root_syn.injections) |*injs| {
                                    var inj_it = injs.iterator();
                                    while (inj_it.next()) |inj_kv| {
                                        const selector = inj_kv.key_ptr.*;
                                        const inj_node = inj_kv.value_ptr.*;
                                        if (scope.matchesScopeSelector(scopes.items, selector)) {
                                            var is_right = false;
                                            var alt_it = std.mem.splitScalar(u8, selector, ',');
                                            while (alt_it.next()) |alt| {
                                                const trimmed = std.mem.trim(u8, alt, " \t\r\n");
                                                if (std.mem.startsWith(u8, trimmed, "R:")) {
                                                    is_right = true;
                                                    break;
                                                }
                                            }
                                            if (inj_node.patterns) |inj_pats| {
                                                for (inj_pats.items) |ip| {
                                                    if (is_right) {
                                                        right_injections.appendBounded(ip) catch {};
                                                    } else {
                                                        left_injections.appendBounded(ip) catch {};
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        var pats_buffer: [256]*Syntax = undefined;
        var all_pats = std.ArrayListUnmanaged(*Syntax).initBuffer(&pats_buffer);

        for (left_injections.items) |p| {
            all_pats.appendBounded(p) catch {};
        }
        if (patterns) |pats| {
            for (pats.items) |p| {
                all_pats.appendBounded(p) catch {};
            }
        }
        for (right_injections.items) |p| {
            all_pats.appendBounded(p) catch {};
        }

        for (all_pats.items) |p| {
            self.total_pats += 1;
            const ls = p.resolve(p, self.lang.syntax);
            if (ls) |syn| {
                const m = self.matchBegin(@constCast(syn), block, start, end);
                if (m.count > 0) {
                    if (m.start == start) {
                        earliest_match = m;
                        break;
                    }

                    if (earliest_match.count == 0) {
                        earliest_match = m;
                    } else if (earliest_match.start > m.start) {
                        earliest_match = m;
                    } else if (earliest_match.start == m.start and earliest_match.end < m.end) {
                        earliest_match = m;
                    }
                }
            }
        }

        return earliest_match;
    }

    fn collectMatch(self: *Parser, syntax: *const Syntax, match: *const Match, block: []const u8) !void {
        const name = syntax.getName();

        if (config.enable_scope_atoms_skip and syntax.atom.id == 1) return;

        if (self.processor) |proc| {
            var c = Capture{
                .start = match.start,
                .end = match.end,
                .syntax = @constCast(syntax),
            };

            var buffer: [128]u8 = undefined;
            var cscope = std.ArrayListUnmanaged(u8).initBuffer(&buffer);

            if (try match.applyCaptures(block, name, &cscope, self.allocator) == 0) {
                if (match.regex) |rx| {
                    if (config.enable_scope_atoms and !rx.has_references) {
                        if (self.atoms) |at| {
                            if (syntax.atom.count == 0 and syntax.atom.id == 0) {
                                @constCast(syntax).atom.compute(name, at);
                                if (syntax.atom.id == 0) {
                                    @constCast(syntax).atom.id = 1;
                                }
                            }
                            c.atom = syntax.atom;
                        }
                    }
                }
            }
            c.scope = try self.transient_strings.appendUnique(cscope.items);
            proc.capture(&c);
        }
    }

    fn collectCaptures(self: *Parser, match: *const Match, captures: *const std.StringHashMap(*Syntax), block: []const u8) !void {
        // std.debug.print("collectCaptures\n", .{});
        var key_buf: [32]u8 = undefined; // is this enough to hold any int as string?
        var scope_buf: [128]u8 = undefined;

        for (0..match.count) |i| {
            const range = match.ranges[i];
            if (range.start == 0 and range.end == 0) continue;
            const key = std.fmt.bufPrint(&key_buf, "{}", .{range.group}) catch {
                continue;
            };

            // std.debug.print(" captures {s}\n", .{key});

            const capture: ?*Syntax = captures.get(key);
            if (capture) |syn| {
                // std.debug.print("capture {s}\n", .{syn.getName()});
                if (self.processor) |proc| {
                    var c = Capture{
                        .start = range.start,
                        .end = range.end,
                        .syntax = syn,
                    };

                    // theme is not interested in this
                    if (config.enable_scope_atoms_skip and syn.atom.id == 1) continue;

                    var cscope = std.ArrayListUnmanaged(u8).initBuffer(&scope_buf);

                    if (try match.applyCaptures(block, syn.name, &cscope, self.allocator) == 0) {
                        if (match.regex) |rx| {
                            if (config.enable_scope_atoms and !rx.has_references) {
                                if (self.atoms) |at| {
                                    if (syn.atom.count == 0 and syn.atom.id == 0) {
                                        syn.atom.compute(syn.getName(), at);
                                        if (syn.atom.id == 0) {
                                            syn.atom.id = 1;
                                        }
                                    }
                                    c.atom = syn.atom;
                                }
                            }
                        }
                    }
                    c.scope = try self.transient_strings.appendUnique(cscope.items);
                    proc.capture(&c);
                }

                // some captures have themselves some patterns
                // TODO needs verification and tests
                if (syn.patterns) |pats| {
                    const ps = match.start; // should be range.start and range.end?
                    const pe = match.end;
                    for (pats.items) |p| {
                        var rx = p.rx_begin;
                        var rx_caps = p.begin_captures;
                        if (p.rx_begin.regex) |_| {
                            rx = p.rx_begin;
                        } else if (p.rx_match.regex) |_| {
                            rx = p.rx_match;
                            rx_caps = p.captures;
                        }
                        if (rx.regex) |regex| {
                            // std.debug.print(">> {s} <<\n", .{p.rx_match.expr orelse ""});
                            // std.debug.print(">> {s} <<\n", .{block[ps..pe]});
                            self.current_anchor_position = @intCast(ps);
                            const m = self.findMatch(p, &p.rx_match, regex, block, ps, pe);
                            if (m.count > 0) {
                                // std.debug.print("count {}\n", .{m.count});
                                if (rx_caps) |*pc| {
                                    // descend into captures
                                    try self.collectCaptures(&m, pc, block);
                                } else if (p.name.len > 0) {
                                    if (self.processor) |proc| {
                                        var c = Capture{
                                            .start = range.start,
                                            .end = range.end,
                                            .syntax = p,
                                        };

                                        var cscope = std.ArrayListUnmanaged(u8).initBuffer(&scope_buf);

                                        if (try m.applyCaptures(block, p.name, &cscope, self.allocator) == 0) {
                                            if (config.enable_scope_atoms) {
                                                if (self.atoms) |at| {
                                                    if (p.atom.count == 0 and p.atom.id == 0) {
                                                        p.atom.compute(p.getName(), at);
                                                        if (p.atom.id == 0) {
                                                            p.atom.id = 1;
                                                        }
                                                    }
                                                    c.atom = p.atom;
                                                }
                                            }
                                        }
                                        c.scope = try self.transient_strings.appendUnique(cscope.items);
                                        proc.capture(&c);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    fn hasCycle(self: *Parser, match: Match) bool {
        for (self.begin_matches.items) |item| {
            if (item.regex == match.regex and item.start == match.start and item.end == match.end) {
                self.cycle_detected = true;
                return true;
            }
        }
        return false;
    }

    // feed the parser a source code line. It must be terminated by a newline character '\n'.
    pub fn parseLine(self: *Parser, state: *ParseState, block: []const u8, first_line: bool) !void {
        if (self.processor) |proc| proc.startLine(block);

        // std.debug.print("\n--- parseLine: '{s}' (len={}, first_line={}) state={*} ---\n", .{ block, block.len, first_line, state });
        // std.debug.print("Initial stack state:\n", .{});
        // state.dump();
        // std.debug.print("----------------------------------------\n", .{});

        if (block.len > config.max_line_len) {
            if (self.processor) |proc| proc.endLine();
            return;
        }

        for (state.stack.items) |*sc| {
            sc.anchor_position = -1;
            sc.zero_width_begin = false;
        }

        self.current_state = state;
        self.match_cache.clearRetainingCapacity();
        self.exec_cache.clearRetainingCapacity();
        self.begin_matches.clearRetainingCapacity();

        self.transient_strings.clear();
        self.first_line = first_line;
        self.cycle_detected = false;

        var start: usize = 0;
        var end = block.len;
        var last_start: usize = 0;
        var last_syntax: u64 = 0;
        var last_stack_size: usize = state.size();

        // handle while
        // todo track while count
        const while_match = try self.matchWhile(state, block);
        if (while_match.count > 0) {
            start = while_match.end;
        }

        while (true) {
            end = block.len;

            var did_match = false;
            const start_ = start;
            // const end_ = end;

            // debug only
            // {
            //     const text = block[start..end];
            //     std.debug.print("====================================\n", .{});
            //     std.debug.print("s:{} e:{} [{s}]\n", .{ start, end, text });
            // }

            const top = state.top();
            if (top) |t| {
                const ts = t.syntax;
                const ls = ts.resolve(ts, self.lang.syntax);
                if (ls) |syn| {
                    // std.debug.print("top> {s} {*}..{}\n", .{syn.getName(), @constCast(syn).root(), state.size()});
                    var end_match: Match = self.matchEnd(state, block, start, end);
                    var pattern_match: Match = Match{};

                    if (!syn.apply_end_pattern_last and end_match.count > 0 and end_match.start == start and end_match.end + 1 >= end) {
                        // end match is prioritized, remove?
                    } else {
                        pattern_match = self.matchPatterns(syn, syn.patterns, block, start, end);
                        if (self.cycle_detected) {
                            break;
                        }
                    }

                    // patter match prevails over end ...
                    if (pattern_match.count > 0) {
                        if (syn.apply_end_pattern_last) {
                            end_match.count = 0;
                        } else if (pattern_match.start < end_match.start) {
                            end_match.count = 0;
                        } else if (pattern_match.start == end_match.start and pattern_match.end < end_match.end) {
                            end_match.count = 0;
                        }
                    }

                    did_match = end_match.count + pattern_match.count > 0;

                    // std.debug.print("end {} vs pat {}\n", .{end_match.count, pattern_match.count});

                    if (end_match.count > 0) {
                        // end pattern has been matched
                        start = end_match.start;
                        end = end_match.end;

                        if (end_match.regex.?.is_anchored) {
                            end = start_;
                        }
                        if (end_match.regex.?.is_anchored_at_start) {
                            end = 0;
                        }

                        // collect endCaptures
                        if (end_match.syntax) |end_syn| {
                            try self.collectMatch(end_syn, &end_match, block);
                            if (end_syn.end_captures) |end_cap| {
                                try self.collectCaptures(&end_match, &end_cap, block);
                            } else if (end_syn.captures) |end_cap| {
                                try self.collectCaptures(&end_match, &end_cap, block);
                            }

                            if (self.processor) |proc| {
                                if (end_syn.content_name.len > 0) {
                                    var c = Capture{
                                        .start = end_match.start,
                                        .end = end_match.start,
                                        .syntax = end_syn,
                                        .atom = end_syn.atom,
                                        .scope = end_syn.content_name,
                                    };
                                    proc.closeTag(&c);
                                }
                                if (end_syn.name.len > 0) {
                                    var c = Capture{
                                        .start = end_match.start,
                                        .end = end_match.end,
                                        .syntax = end_syn,
                                        .atom = end_syn.atom,
                                        .scope = end_syn.name,
                                    };
                                    proc.closeTag(&c);
                                } else if (end_syn.name.len == 0 and end_syn.scope_name.len > 0) {
                                    var c = Capture{
                                        .start = end_match.start,
                                        .end = end_match.end,
                                        .syntax = end_syn,
                                        .atom = end_syn.atom,
                                        .scope = end_syn.scope_name,
                                    };
                                    proc.closeTag(&c);
                                }
                            }

                            // std.debug.print("pop {*} {s} {s}\n", .{ end_syn, end_syn.getName(), block[end_match.start..end_match.end] });
                        }

                        // pop!
                        state.pop("matchEnd");
                    } else if (pattern_match.count > 0) {
                        if (pattern_match.syntax) |match_syn| {
                            // pattern has been matched
                            start = pattern_match.start;
                            end = pattern_match.end;

                            if (match_syn.rx_begin.valid == .Valid) {
                                // std.debug.print("push {*} {s} {s} {}-{}\n", .{ match_syn, match_syn.getName(), match_syn.rx_begin.expr orelse "", start, end });
                                if (pattern_match.regex) |rx| {
                                    if (config.enable_scope_atoms and !rx.has_references) {
                                        if (self.atoms) |at| {
                                            if (match_syn.atom.count == 0 and match_syn.atom.id == 0) {
                                                match_syn.atom.compute(match_syn.getName(), at);
                                                if (match_syn.atom.id == 0) {
                                                    match_syn.atom.id = 1;
                                                }
                                            }
                                        }
                                    }

                                    try state.push(@constCast(match_syn), rx, block, pattern_match, "pattern");
                                    // TODO fix anchors
                                    if (ts.rx_begin.is_anchored and rx.is_anchored) {
                                        end = start_;
                                    }

                                    try self.begin_matches.append(self.allocator, pattern_match);
                                    // fail silently?
                                }

                                if (self.processor) |proc| {
                                    if (match_syn.name.len > 0) {
                                        var c = Capture{
                                            .start = pattern_match.start,
                                            .end = pattern_match.end,
                                            .syntax = match_syn,
                                            .atom = match_syn.atom,
                                            .scope = match_syn.name,
                                        };
                                        proc.openTag(&c);
                                    }
                                    if (match_syn.content_name.len > 0) {
                                        var c = Capture{
                                            .start = pattern_match.end,
                                            .end = pattern_match.end,
                                            .syntax = match_syn,
                                            .atom = match_syn.atom,
                                            .scope = match_syn.content_name,
                                        };
                                        proc.openTag(&c);
                                    } else if (match_syn.name.len == 0 and match_syn.scope_name.len > 0) {
                                        var c = Capture{
                                            .start = pattern_match.start,
                                            .end = pattern_match.end,
                                            .syntax = match_syn,
                                            .atom = match_syn.atom,
                                            .scope = match_syn.scope_name,
                                        };
                                        proc.openTag(&c);
                                    }
                                }

                                try self.collectMatch(match_syn, &pattern_match, block);
                                if (match_syn.begin_captures) |beg_cap| {
                                    try self.collectCaptures(&pattern_match, &beg_cap, block);
                                } else if (match_syn.captures) |beg_cap| {
                                    try self.collectCaptures(&pattern_match, &beg_cap, block);
                                }
                            } else {
                                try self.collectMatch(match_syn, &pattern_match, block);
                                if (match_syn.captures) |cap| {
                                    try self.collectCaptures(&pattern_match, &cap, block);
                                }
                            }
                        }
                    } else {
                        // no match
                    }
                } else {
                    // no top.syntax
                    unreachable;
                }

                if (state.size() > self.deepest) {
                    self.deepest = @intCast(state.size());
                }

                if (start == block.len) {
                    break;
                }

                if (start_ == end) {
                    if (state.size() == last_stack_size) {
                        if (state.size() > 1) {
                            _ = state.pop("zeroWidthLoop");
                        }
                        break;
                    }
                }

                last_syntax = ts.id;
                last_start = start;
                last_stack_size = state.size();
                start = end;
            }
        }

        if (self.processor) |proc| proc.endLine();
        self.current_state = null;
        self.first_line = false;
    }

    // begin merely resets all stats
    pub fn resetStats(self: *Parser) void {
        self.regex_execs = 0;
        self.regex_skips = 0;
        self.total_pats = 0;
        self.deepest = 0;
    }

    pub fn serialize(self: *Parser, state: *ParseState, serial: *std.ArrayList(StateContextPack)) !void {
        serial.clearRetainingCapacity();
        for (state.stack.items) |*item| {
            try serial.append(item.serialize(self));
        }
    }

    pub fn deserialize(self: *Parser, state: *ParseState, serial: *std.ArrayList(StateContextPack)) !void {
        state.stack.clearRetainingCapacity();
        for (serial.items) |item| {
            var sc = StateContext{ .syntax = self.lang.syntax.? };
            try sc.deserialize(self, item);
            try state.stack.append(sc);
        }
    }
};

test "test references" {
    const block: []const u8 = "abcdefg";
    var m = Match{};
    m.count = 2;
    m.ranges[0].group = 1;
    m.ranges[0].start = 0;
    m.ranges[0].end = 2;
    m.ranges[1].group = 2;
    m.ranges[1].start = 3;
    m.ranges[1].end = 5;
    var output = try ArrayList(u8).initCapacity(std.testing.allocator, 64);
    defer output.deinit(std.testing.allocator);
    _ = try m.applyReferences(block, "hello \\1 world \\2.", &output, std.testing.allocator);

    const expectedOutput = "hello ab world de.";
    try std.testing.expectEqualStrings(output.items[0..expectedOutput.len], expectedOutput);
}
