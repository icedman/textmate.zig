const std = @import("std");
const oni = @import("oniguruma");
const grammar = @import("grammar.zig");
const processor = @import("processor.zig");
const util = @import("util.zig");
const Syntax = grammar.Syntax;
const Regex = grammar.Regex;

// TODO move to config.. smallcaps
// is exec level (findMatch) caching slower as it caches everything -- even resolving captures?)
const ENABLE_EXEC_CACHING = true;
// redundant to enable match-end cache with exec cache?
const ENABLE_MATCH_CACHING = true;
const ENABLE_END_CACHING = true;

const MAX_LINE_LEN = 1024; // and line longer will not be parsed
const MAX_MATCH_RANGES = 9; // max $1 in grammar files is just 8
const MAX_SCOPE_LEN = 98;

const MAX_STATE_STACK_DEPTH = 200; // if the state depth is too deep .. just prune (this shouldn't happen though)
const STATE_STACK_PRUNE = 120; // prune off states from the stack

// capture is like MatchRange.. but atomic and should be serializable
pub const ParseCapture = struct {
    start: usize = 0,
    end: usize = 0,

    // is this expensive to pass around (copy)
    // TODO convert scope to atoms (scope_hash) ...
    scope: [MAX_SCOPE_LEN]u8 = [_]u8{0} ** MAX_SCOPE_LEN,
    scope_hash: u64 = 0,

    // open block and strings will be retained across line parsing
    // syntax_id will be the identifier (not pointers)
    // by default, every syntax pushed to the stack will be retained until end is matched
    syntax_id: u64 = 0,
    retain: bool = false,
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
    regex: ?*Regex = null,

    // is this expensive to pass around (copy)
    ranges: [MAX_MATCH_RANGES]MatchRange = [_]MatchRange{MatchRange{ .group = 0, .start = 0, .end = 0 }} ** MAX_MATCH_RANGES,
    count: u8 = 0,

    // this is just start and end of ranges[0]
    start: usize = 0,
    end: usize = 0,

    // search anchors are the start and end of block sliced passed to findMatch
    anchor_start: usize = 0,
    anchor_end: usize = 0,

    fn applyRef(self: *const Match, block: []const u8, target: []const u8, escape_character: u8, output: *[MAX_SCOPE_LEN]u8) u8 {
        var output_idx: u8 = 0;
        var escape = false;
        var skip: usize = 0;
        for (target, 0..) |ch, idx| {
            if (skip > 0) {
                skip -= 1;
                continue;
            }
            if (escape and std.ascii.isDigit(ch)) {
                output_idx -= 1;
                for (0..self.count) |i| {
                    const r = self.ranges[i];
                    const digit: u8 = blk: {
                        const d = ch - '0';
                        if (MAX_MATCH_RANGES > 9 and output_idx < output.len - 1) {
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
                    if (digit == r.group) {
                        for (r.start..r.end) |bi| {
                            output[output_idx] = block[bi];
                            output_idx += 1;
                            // this cuts off any overflow
                            if (output_idx >= output.len) return output_idx;
                        }
                    }
                }
            } else {
                output[output_idx] = ch;
                output_idx += 1;
                if (output_idx >= output.len) return output_idx;
            }
            escape = (!escape) and (ch == escape_character);
        }

        // std.debug.print("{s}\n", .{output});
        return output_idx;
    }

    pub fn applyReferences(self: *const Match, block: []const u8, target: []const u8, output: *[MAX_SCOPE_LEN]u8) u8 {
        return self.applyRef(block, target, '\\', output);
    }

    pub fn applyCaptures(self: *const Match, block: []const u8, target: []const u8, output: *[MAX_SCOPE_LEN]u8) u8 {
        return self.applyRef(block, target, '$', output);
    }
};

// StateContext holds the context of a single character match is made for a Syntax
// It is store only if the Syntax would require further matching with its children patterns
// This should be serializable as this is what the parse state stack contains

const SerialQuad = struct { a: u64, b: u64, c: u64, d: u64 };
const StateContext = struct {
    syntax: *Syntax,

    // The match position of the character relative to the line start
    anchor: u64 = 0,

    // Parser owns these at regex_map and responsible for oni.Regex.deinit not Self
    rx_while: Regex = Regex{},
    rx_end: Regex = Regex{},

    pub fn serialize(self: *StateContext, parser: *Parser) struct { u64, u64, u64, u64 } {
        _ = parser;
        return .{ self.syntax.id, self.anchor, self.rx_while.id, self.rx_end.id };
    }

    pub fn deserialize(self: *StateContext, parser: *Parser, serial: struct { u64, u64, u64, u64 }) !void {
        self.syntax = @ptrFromInt(serial[0]);
        self.anchor = serial[1];
        self.rx_while = parser.regex_map.get(serial[2]) orelse Regex{};
        self.rx_end = parser.regex_map.get(serial[3]) orelse Regex{};
    }
};

/// ParseState is a StateContext stack
/// This should be (de)serializable
pub const ParseState = struct {
    allocator: std.mem.Allocator,
    stack: std.ArrayList(StateContext),
    owner: *Parser = undefined,

    pub fn init(owner: *Parser, allocator: std.mem.Allocator, syntax: *Syntax) !ParseState {
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

    // TODO why optional match?
    pub fn push(self: *ParseState, syntax: *Syntax, rx: *Regex, block: []const u8, match: ?Match, where: []const u8) !void {
        const anchor = (match orelse Match{ .start = 0 }).start;
        var sc = StateContext{
            .syntax = syntax,
            .anchor = anchor,
        };
        if (rx.has_references) {
            if (match) |m| {
                // compile StateContext.rx_end
                if (syntax.rx_end.expr) |regexs| {
                    var output: [MAX_SCOPE_LEN]u8 = [_]u8{0} ** MAX_SCOPE_LEN;
                    _ = m.applyReferences(block, regexs, &output);
                    {
                        if (self.owner.regex_map.get(util.toHash(util.toSlice([MAX_SCOPE_LEN]u8, output)))) |r| {
                            sc.rx_end = r;
                        } else {
                            sc.rx_end.compile(&output) catch {};
                            if (sc.rx_end.id > 0) {
                                try self.owner.regex_map.put(sc.rx_end.id, sc.rx_end);
                            }
                        }
                    }
                }
                // compile StateContext.rx_while
                if (syntax.rx_while.expr) |regexs| {
                    var output: [MAX_SCOPE_LEN]u8 = [_]u8{0} ** MAX_SCOPE_LEN;
                    _ = m.applyReferences(block, regexs, &output);
                    {
                        if (self.owner.regex_map.get(util.toHash(util.toSlice([MAX_SCOPE_LEN]u8, output)))) |r| {
                            sc.rx_while = r;
                        } else {
                            sc.rx_while.compile(&output) catch {};
                            if (sc.rx_while.id > 0) {
                                try self.owner.regex_map.put(sc.rx_while.id, sc.rx_while);
                            }
                        }
                    }
                }
            }
        }
        _ = self.stack.append(self.allocator, sc) catch {};
        _ = where;
        // std.debug.print("state push {} {s}\n", .{self.size(), where});
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
                const ls = ts.resolve(ts, self.lang.syntax);
                if (ls) |syn| {
                    std.debug.print("{} {*} {s}\n", .{ i, syn, syn.getName() });
                    if (syn.regexs_match) |r| {
                        std.debug.print("  match: {s}\n", .{r});
                    }
                    if (syn.regexs_begin) |r| {
                        std.debug.print("  begin: {s}\n", .{r});
                        std.debug.print("  end: {s}\n", .{syn.regexs_end orelse ""});
                    }
                }
            }
        }
    }
};

// Parser is where the heavy work is done
// It parses a single line but can receive ParseState from a previous line parse for continuance
pub const Parser = struct {
    allocator: std.mem.Allocator,
    lang: *grammar.Grammar,

    // processor
    processor: ?*processor.Processor = null,

    // Cache for line parsing
    // syntax level cache
    match_cache: std.AutoHashMap(u64, Match),
    // regex level cache
    exec_cache: std.AutoHashMap(u64, Match),

    // runtime-compiled (with dynamic patterns) are save for sharing a (de)serialization
    regex_map: std.AutoHashMap(u64, grammar.Regex),

    // stats
    regex_execs: u32 = 0,
    regex_skips: u32 = 0,
    current_state: ?*ParseState = null,

    pub fn init(allocator: std.mem.Allocator, lang: *grammar.Grammar) !Parser {
        return Parser{
            .allocator = allocator,
            .lang = lang,
            .match_cache = std.AutoHashMap(u64, Match).init(allocator),
            .exec_cache = std.AutoHashMap(u64, Match).init(allocator),
            .regex_map = std.AutoHashMap(u64, grammar.Regex).init(allocator),
        };
    }

    pub fn deinit(self: *Parser) void {
        self.match_cache.deinit();
        self.exec_cache.deinit();

        var it = self.regex_map.iterator();
        while (it.next()) |kv| {
            const v = kv.value_ptr.*;
            if (v.regex) |*r| {
                @constCast(r).deinit();
            }
        }
        self.regex_map.deinit();
    }

    pub fn initState(self: *Parser) !ParseState {
        if (self.lang.syntax) |s| {
            return ParseState.init(self, self.allocator, s);
        }
        return error.InvalidGrammar;
    }

    fn getCurrentAnchor(self: *Parser) usize {
        if (self.current_state) |state| {
            const top = state.top();
            if (top) |t| {
                return t.anchor;
            }
        }
        return 0;
    }

    // findMatch. Regular expression matching. This is where all the CPU usage goes.
    fn findMatch(self: *Parser, syntax: *Syntax, rx: *Regex, regex: ?oni.Regex, block: []const u8, start: usize, end: usize) Match {
        if (block.len == 0) {
            return Match{};
        }

        // std.debug.print("findMatch {s} {}\n", .{regexs orelse "", rx.id});
        // std.debug.print("findMatch {}\n", .{rx.id});

        if (regex) |*re| {

            // check cache
            var should_cache = false;
            if (rx.valid == .Valid and ENABLE_EXEC_CACHING) {
                should_cache = true;
                if (self.exec_cache.get(rx.id)) |mm| {
                    if (mm.anchor_start <= start and mm.start > start) {

                        // std.debug.print("findMatch cache {s} {} {}-{}\n", .{rx.expr orelse "", start, mm.start, mm.end});

                        self.regex_skips += 1;
                        return mm;
                    }
                    if (mm.anchor_start <= start and mm.count == 0) {
                        self.regex_skips += 1;
                        return mm;
                    }
                }
            }

            syntax.execs += 1;
            self.regex_execs += 1;
            var hard_start: usize = start;
            const is_anchored = rx.is_anchored;
            if (is_anchored) {
                // TODO is this correct?
                // \G in oniguruma means start of previous match
                hard_start = self.getCurrentAnchor();
            }
            const hard_end: usize = end;
            const reg = blk: {
                var result: oni.Region = .{};
                _ = @constCast(re).searchAdvanced(block, hard_start, hard_end, &result, .{}) catch |err| {
                    if (err == error.Mismatch) {
                        break :blk null; // return null instead
                    } else {
                        return Match{};
                    }
                };
                break :blk result;
            };

            if (reg) |r| {
                var m = Match{
                    .syntax = syntax,
                    .regex = rx,
                    .anchor_start = hard_start,
                    .anchor_end = hard_end,
                };

                var count: u8 = 0;
                var i: u16 = 0;
                const starts = r.starts();
                const ends = r.ends();
                while (i < r.count() and i < MAX_MATCH_RANGES) : (i += 1) {
                    if (starts[i] < 0) {
                        // m.ranges[count].group = i;
                        // m.ranges[count].start = start;
                        // m.ranges[count].end = start;
                        // count += 1;
                        // -1 could happen in oniguruma when an optional capture group didn't match
                        // case: when no newline '\n' is present (c.tmLanguage)
                        continue;
                    }
                    const s: usize = @intCast(starts[i]);
                    const e: usize = @intCast(ends[i]);
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
                    }
                }

                m.count = count;

                if (count > 0) {
                    // std.debug.print(">>>>>>>>>>>{s}\n", .{regexs orelse ""});
                    // std.debug.print("{s}\n", .{syntax.name});
                    // std.debug.print("{s}\n", .{syntax.scope_name});
                    // std.debug.print("{s}\n", .{syntax.content_name});
                }

                if (should_cache) {
                    self.exec_cache.put(rx.id, m) catch {};
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
    fn matchBegin(self: *Parser, syntax: *Syntax, block: []const u8, start: usize, end: usize) Match {
        if (block.len == 0) {
            return Match{};
        }

        // if all this syntax has are patterns, check patterns
        if (syntax.rx_match.valid != .Valid and syntax.rx_begin.valid != .Valid) {
            return self.matchPatterns(syntax, syntax.patterns, block, start, end);
        }

        // match
        if (syntax.rx_match.valid == .Valid) {
            if (syntax.rx_match.regex) |regex| {
                // if (syntax.regex_match != null) {
                //     if (syntax.regex_match) |regex| {
                // check of matching has been previously cached (for the same position in the buffer)
                var should_cache = false;
                const m = blk: {
                    const mm = self.match_cache.get(syntax.rx_match.id) orelse {
                        should_cache = true;
                        break :blk null;
                    };
                    if (mm.anchor_start <= start and mm.start >= start) {
                        self.regex_skips += 1;
                        break :blk mm;
                    }
                    if (mm.anchor_start <= start and mm.count == 0) {
                        self.regex_skips += 1;
                        break :blk mm;
                    }
                    break :blk null;
                } orelse self.findMatch(syntax, &syntax.rx_match, regex, block, start, end);
                if (should_cache and ENABLE_MATCH_CACHING) {
                    if (syntax.rx_match.id != 0)
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
                // if (syntax.regex_begin != null) {
                //     if (syntax.regex_begin) |regex| {
                // check of matching has been previously cached (for the same position in the buffer)
                var should_cache = false;
                const m = blk: {
                    const mm = self.match_cache.get(syntax.rx_begin.id) orelse {
                        should_cache = true;
                        break :blk null;
                    };
                    if (mm.anchor_start <= start and mm.start >= start) {
                        self.regex_skips += 1;
                        break :blk mm;
                    }
                    if (mm.anchor_start <= start and mm.count == 0) {
                        self.regex_skips += 1;
                        break :blk mm;
                    }
                    break :blk null;
                } orelse self.findMatch(syntax, &syntax.rx_begin, regex, block, start, end);
                if (should_cache and ENABLE_MATCH_CACHING) {
                    _ = self.match_cache.put(syntax.rx_begin.id, m) catch {};
                }
                if (m.count > 0) {
                    return m;
                }
            }
        }

        return Match{};
    }

    // TODO while matches could have captures
    pub fn matchWhile(self: *Parser, state: *ParseState, block: []const u8) void {
        var state_depth = state.size();
        const start: usize = 0;
        const end = block.len;
        while (state_depth > 1) : (state_depth -= 1) {
            const top = state.at(state_depth - 1);
            if (top) |t| {
                const ts = t.syntax;
                const ls = ts.resolve(ts, self.lang.syntax);
                if (ls) |syn| {
                    const m: Match = blk: {
                        if (t.rx_while.valid == .Valid) {
                            // use dynamic while_regex here if one was compiled
                            // not caching or result in this case
                            // TODO caching is possible though
                            const m = self.findMatch(@constCast(syn), @constCast(&syn.rx_while), t.rx_while.regex, block, start, end);
                            break :blk m;
                        }

                        // while_match without caching
                        if (syn.rx_while.regex) |r| {
                            const m = self.findMatch(@constCast(syn), @constCast(&syn.rx_while), r, block, start, end);
                            break :blk m;
                        }
                        break :blk Match{ .count = 1 };
                    };

                    if (m.count == 0) {
                        // std.debug.print("while! {s}\n", .{syn.syn.rx_while.expr orelse "?"});
                        while (state.size() >= state_depth) {
                            state.pop("matchWhile");
                        }
                    }
                }
            }
        }
    }

    /// TODO matchEnd must also be cached. Also, some end expressions are similar (should also be cached)
    pub fn matchEnd(self: *Parser, state: *ParseState, block: []const u8, start: usize, end: usize) Match {
        // prune if the stack is already too deep like deeply nested blocks
        // TODO investigate why this happens -- (dump end unmatched blocks, some patterns may be negatively unmatched)
        // if (state.size() > MAX_STATE_STACK_DEPTH) {
        //     if (state.stack.items.len >= MAX_STATE_STACK_DEPTH) {
        //         const new_len = state.stack.items.len - STATE_STACK_PRUNE;
        //         @memcpy(
        //             state.stack.items[0..new_len],
        //             state.stack.items[STATE_STACK_PRUNE..state.stack.items.len],
        //         );
        //         state.stack.items.len = new_len;
        //     }
        // }

        const top = state.top();
        if (top) |t| {
            const ts = t.syntax;
            const ls = ts.resolve(ts, self.lang.syntax);
            if (ls) |syn| {
                const end_match: Match = blk: {
                    if (t.rx_end.valid == .Valid) {
                        // use dynamic end_regex here if one was compiled
                        // not caching or result in this case
                        const m = self.findMatch(@constCast(syn), @constCast(&syn.rx_end), t.rx_end.regex, block, start, end);
                        break :blk m;
                    }

                    // end_match with caching
                    var should_cache = false;
                    const m = inner_blk: {
                        const mm = self.match_cache.get(syn.rx_end.id) orelse {
                            should_cache = true;
                            break :inner_blk null;
                        };
                        if (mm.anchor_start <= start and mm.start >= start) {
                            self.regex_skips += 1;
                            break :inner_blk mm;
                        }
                        if (mm.anchor_start <= start and mm.count == 0) {
                            self.regex_skips += 1;
                            break :inner_blk mm;
                        }
                        break :inner_blk null;
                    } orelse self.findMatch(@constCast(syn), @constCast(&syn.rx_end), syn.rx_end.regex, block, start, end);
                    if (should_cache and ENABLE_END_CACHING) {
                        _ = self.match_cache.put(syn.rx_end.id, m) catch {};
                    }

                    break :blk m;
                };
                if (end_match.count > 0) {
                    return end_match;
                }
            }
        }

        return Match{};
    }

    fn matchPatterns(self: *Parser, syntax: *const Syntax, patterns: ?[]*Syntax, block: []const u8, start: usize, end: usize) Match {
        _ = syntax;
        var earliest_match = Match{};
        if (patterns) |pats| {
            for (pats) |p| {
                const ls = p.resolve(p, self.lang.syntax);
                if (ls) |syn| {
                    const m = self.matchBegin(@constCast(syn), block, start, end);
                    if (m.count > 0) {
                        // if matched correctly at the current position, no need to scan further, we have our match
                        if (m.start == start) {
                            earliest_match = m;
                            break;
                        }
                        if (earliest_match.count == 0) {
                            earliest_match = m;
                        } else if (earliest_match.start > m.start) {
                            // nearer to current position is the earlier match
                            earliest_match = m;
                        }
                    }
                }
            }
        }
        return earliest_match;
    }

    fn collectMatch(self: *Parser, syntax: *const Syntax, match: *const Match, block: []const u8) void {
        const name = blk: {
            if (syntax.content_name.len > 0) {
                break :blk syntax.content_name;
            }
            if (syntax.scope_name.len > 0) {
                break :blk syntax.scope_name;
            }
            break :blk syntax.name;
        };
        if (self.processor) |proc| {
            var c = Capture{
                .start = match.start,
                .end = match.end,
            };
            if (match.applyCaptures(block, name, &c.scope) == 0) {
                c.scope_hash = syntax.scope_hash;
            }
            proc.capture(&c);
        }
    }

    fn collectCaptures(self: *Parser, match: *const Match, captures: *const std.StringHashMap(*Syntax), block: []const u8) void {
        for (0..match.count) |i| {
            var buf: [32]u8 = undefined; // is this enough to hold any int as string?
            const range = match.ranges[i];
            if (range.start == 0 and range.end == 0) continue;
            const key = std.fmt.bufPrint(&buf, "{}", .{range.group}) catch {
                continue;
            };

            const capture: ?*Syntax = captures.get(key);
            if (capture) |syn| {
                if (self.processor) |proc| {
                    var c = Capture{
                        .start = range.start,
                        .end = range.end,
                    };
                    if (match.applyCaptures(block, syn.name, &c.scope) == 0) {
                        c.scope_hash = syn.scope_hash;
                    }
                    proc.capture(&c);
                }

                // some captures have themselves some patterns
                // TODO needs verification and tests
                if (syn.patterns) |pats| {
                    const ps = match.start; // should be range.start and range.end?
                    const pe = match.end;
                    for (pats) |p| {
                        if (p.rx_match.regex) |regex| {
                            // std.debug.print(">> {s} <<\n", .{p.regexs_match orelse ""});
                            // std.debug.print(">> {s} <<\n", .{block[ps..pe]});
                            const m = self.findMatch(p, &p.rx_match, regex, block, ps, pe);
                            if (m.count > 0) {
                                // std.debug.print("count {}\n", .{m.count});
                                if (p.captures) |*pc| {
                                    // descend into captures
                                    self.collectCaptures(&m, pc, block);
                                } else if (p.name.len > 0) {
                                    if (self.processor) |proc| {
                                        var c = Capture{
                                            .start = range.start,
                                            .end = range.end,
                                        };
                                        if (m.applyCaptures(block, p.name, &c.scope) == 0) {
                                            c.scope_hash = p.scope_hash;
                                        }
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

    // feed the parser a source code line. It must be terminated by a newline character '\n'.
    pub fn parseLine(self: *Parser, state: *ParseState, block: []const u8) !void {
        if (self.processor) |proc| proc.startLine(block);

        if (block.len > MAX_LINE_LEN) {
            if (self.processor) |proc| proc.endLine();
            return;
        }

        self.current_state = state;
        self.match_cache.clearRetainingCapacity();
        // self.end_cache.clearRetainingCapacity();
        self.exec_cache.clearRetainingCapacity();

        var start: usize = 0;
        var end = block.len;

        // hacky way to escape unexplained lookp :) .. can't escape push-pop infinite loop
        var last_start: usize = 0;
        var last_syntax: u64 = 0;

        // hacky way to escape push-pop infinite loop
        var last_push_pos: usize = 0;
        var last_push_syntax: u64 = 0;

        // handle while
        // todo track while count
        self.matchWhile(state, block);

        while (true) {
            end = block.len;

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
                    const end_match: Match = self.matchEnd(state, block, start, end);
                    var pattern_match: Match = Match{};

                    if (end_match.count > 0 and end_match.end + 1 >= end) {
                        // this is the end of the block.. don't bother with patterns
                    } else {
                        pattern_match = self.matchPatterns(syn, syn.patterns, block, start, end);
                    }

                    if (end_match.count > 0 and
                        (pattern_match.count == 0 or
                            (pattern_match.count > 0 and pattern_match.start >= end_match.start)))
                    {
                        // end pattern has been matched
                        start = end_match.start;
                        end = end_match.end;

                        // collect endCaptures
                        if (end_match.syntax) |end_syn| {
                            self.collectMatch(end_syn, &end_match, block);
                            if (end_syn.end_captures) |end_cap| {
                                self.collectCaptures(&end_match, &end_cap, block);
                            }

                            if (self.processor) |proc| {
                                const name = end_syn.getName();
                                var c = Capture{
                                    .start = end_match.start,
                                    .end = end_match.end,
                                    .syntax_id = end_syn.id,
                                };
                                @memcpy(c.scope[0..name.len], name);
                                proc.closeTag(&c);
                            }

                            // std.debug.print("pop {s}\n", .{end_syn.getName()});
                        }

                        // pop!
                        state.pop("matchEnd");
                    } else if (pattern_match.count > 0) {
                        if (pattern_match.syntax) |match_syn| {
                            // pattern has been matched
                            const start_ = start;
                            start = pattern_match.start;
                            end = pattern_match.end;

                            // if it has a regexs_end.. it is a begin and should cause a push
                            if (match_syn.rx_end.expr != null) {
                                // std.debug.print("push {s}\n", .{match_syn.getName()});
                                if (pattern_match.regex) |rx| {
                                    if (last_push_pos != start_ or last_push_syntax != match_syn.id) {
                                        state.push(match_syn, rx, block, pattern_match, "patttern") catch {};
                                        last_push_pos = start_;
                                        last_push_syntax = match_syn.id;
                                    }
                                    // fail silently?
                                }

                                if (self.processor) |proc| {
                                    const name = match_syn.getName();
                                    var c = Capture{
                                        .start = pattern_match.start,
                                        .end = pattern_match.end,
                                        .syntax_id = match_syn.id,
                                    };
                                    @memcpy(c.scope[0..name.len], name);
                                    if (pattern_match.regex) |rx| {
                                        c.retain = (rx.is_string_block or rx.is_comment_block);
                                    }
                                    proc.openTag(&c);
                                }

                                self.collectMatch(match_syn, &pattern_match, block);
                                if (match_syn.begin_captures) |beg_cap| {
                                    self.collectCaptures(&pattern_match, &beg_cap, block);
                                }
                            } else {
                                self.collectMatch(match_syn, &pattern_match, block);
                                if (match_syn.captures) |cap| {
                                    self.collectCaptures(&pattern_match, &cap, block);
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

                if (start == block.len) {
                    break;
                }

                // endless loop?
                if (last_start == start and last_syntax == ts.id) {
                    break;
                }

                last_syntax = ts.id;
                last_start = start;
                start = end;
            } else {
                // no top
                unreachable;
            }
        }

        if (self.processor) |proc| proc.endLine();
        self.current_state = null;
    }

    // begin merely resets all stats
    pub fn resetStats(self: *Parser) void {
        self.regex_execs = 0;
        self.regex_skips = 0;
    }

    pub fn serialize(self: *Parser, state: *ParseState, serial: *std.ArrayList(struct { u64, u64, u64, u64 })) !void {
        serial.clearRetainingCapacity();
        for (state.stack.items) |*item| {
            serial.append(item.serialize(self)) catch {};
        }
    }

    pub fn deserialize(self: *Parser, state: *ParseState, serial: *std.ArrayList(struct { u64, u64, u64, u64 })) !void {
        state.stack.clearRetainingCapacity();
        for (serial.items) |item| {
            var sc = StateContext{ .syntax = self.lang.syntax.? };
            sc.deserialize(self, item) catch {};
            state.stack.append(sc) catch {};
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
    var output: [MAX_SCOPE_LEN]u8 = [_]u8{0} ** MAX_SCOPE_LEN;
    _ = m.applyReferences(block, "hello \\1 world \\2.", &output);

    const expectedOutput = "hello ab world de.";
    try std.testing.expectEqualStrings(output[0..expectedOutput.len], expectedOutput);
}
