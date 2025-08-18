const std = @import("std");
const oni = @import("oniguruma");
const grammar = @import("grammar.zig");
const processor = @import("processor.zig");
const Syntax = grammar.Syntax;

const MAX_MATCH_RANGES = 10; // max $1 in grammar files is just 8
const MAX_SCOPE_LEN = 128;
const MAX_STATE_STACK_DEPTH = 200; // if the state depth is too deep .. just prune (this shouldn't happen though)
const STATE_STACK_PRUNE = 120; // prune off states from the stack

// capture is like MatchRange.. but atomic and should be serializable
pub const Capture = struct {
    start: usize = 0,
    end: usize = 0,
    scope: [MAX_SCOPE_LEN:0]u8 = [_:0]u8{0} ** MAX_SCOPE_LEN,
    // open block and strings will be retained across line parsing
    // syntax_id will be the identifier (not pointers)
    syntax_id: u32 = 0,
    retain: bool = false,
};

pub const MatchRange = struct {
    group: u16 = 0,
    start: usize = 0,
    end: usize = 0,
};

pub const Match = struct {
    syntax: ?*Syntax = null,
    count: u8 = 0,

    ranges: [MAX_MATCH_RANGES]MatchRange = [_]MatchRange{MatchRange{ .group = 0, .start = 0, .end = 0 }} ** MAX_MATCH_RANGES,
    start: usize = 0,
    end: usize = 0,

    // search anchors
    anchor_start: usize = 0,
    anchor_end: usize = 0,

    fn applyRef(self: *const Match, block: []const u8, target: []const u8, escape_character: u8, output: *[MAX_SCOPE_LEN]u8) []const u8 {
        var output_idx: usize = 0;
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
                        if (output_idx < output.len - 1) {
                            // check for another digit
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
                            if (output_idx >= output.len) return output;
                        }
                    }
                }
            } else {
                output[output_idx] = ch;
                output_idx += 1;
                if (output_idx >= output.len) return output;
            }
            escape = (!escape) and (ch == escape_character);
        }

        // std.debug.print("{s}\n", .{output});
        return output;
    }

    pub fn applyReferences(self: *const Match, block: []const u8, target: []const u8, output: *[MAX_SCOPE_LEN]u8) []const u8 {
        return self.applyRef(block, target, '\\', output);
    }

    pub fn applyCaptures(self: *const Match, block: []const u8, target: []const u8, output: *[MAX_SCOPE_LEN]u8) []const u8 {
        return self.applyRef(block, target, '$', output);
    }
};

// this should be serializable as this is what the parse state stack contains
pub const StateContext = struct {
    syntax: *Syntax,
    end_regex: ?oni.Regex = null,
};

/// ParseState is a StateContext stack
pub const ParseState = struct {
    allocator: std.mem.Allocator,
    stack: std.ArrayList(StateContext),

    pub fn init(allocator: std.mem.Allocator, syntax: *Syntax) !ParseState {
        var stack = std.ArrayList(StateContext).init(allocator);
        try stack.append(StateContext{
            .syntax = syntax,
        });
        return ParseState{
            .allocator = allocator,
            .stack = stack,
        };
    }

    pub fn deinit(self: *ParseState) void {
        for (self.stack.items) |item| {
            // free parse-time compiled regex
            if (item.end_regex) |*regex| {
                @constCast(regex).deinit();
            }
        }
        self.stack.deinit();
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

    pub fn pop(self: *ParseState) void {
        if (self.stack.items.len > 0) {
            _ = self.stack.pop();
        }
    }

    pub fn push(self: *ParseState, syntax: *Syntax, block: []const u8, match: ?Match) !void {
        var sc = StateContext{
            .syntax = syntax,
        };
        if (syntax.has_back_references) {
            // compile regex_end
            if (match) |m| {
                if (syntax.regexs_end) |regexs| {
                    var output: [MAX_SCOPE_LEN]u8 = [_]u8{0} ** MAX_SCOPE_LEN;
                    _ = m.applyReferences(block, regexs, &output);
                    {
                        sc.end_regex = try oni.Regex.init(
                            &output,
                            .{},
                            oni.Encoding.utf8,
                            oni.Syntax.default,
                            null,
                        );
                        errdefer sc.end_regex.deinit();
                    }
                }
            }
        }
        _ = self.stack.append(sc) catch {};
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
                const ls = ts.resolve(ts);
                if (ls) |syn| {
                    std.debug.print("{} {*} {s} {s} {s}\n", .{ i, syn, syn.name, syn.content_name, syn.scope_name });
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

pub const Parser = struct {
    allocator: std.mem.Allocator,
    lang: *grammar.Grammar,

    // line parse data
    match_cache: std.AutoHashMap(u32, Match),

    // processor
    processor: ?*processor.Processor = null,

    // stats
    regex_execs: u32 = 0,
    regex_skips: u32 = 0,

    pub fn init(allocator: std.mem.Allocator, lang: *grammar.Grammar) !Parser {
        return Parser{
            .allocator = allocator,
            .lang = lang,
            .match_cache = std.AutoHashMap(u32, Match).init(allocator),
        };
    }

    pub fn deinit(self: *Parser) void {
        self.match_cache.deinit();
    }

    fn execRegex(self: *Parser, syntax: *Syntax, regex: ?oni.Regex, regexs: ?[]const u8, block: []const u8, start: usize, end: usize) Match {
        // std.debug.print("execRegex {s}\n", .{regexs orelse ""});
        if (regex) |*re| {
            syntax.execs += 1;
            self.regex_execs += 1;
            var hard_start: usize = start;
            if (syntax.is_anchored) {
                // TODO is this correct?
                hard_start = 0;
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
                    .anchor_start = hard_start,
                    .anchor_end = hard_end,
                };

                var count: u8 = 0;
                var i: u16 = 0;
                const starts = r.starts();
                const ends = r.ends();
                while (i < r.count() and i < 10) : (i += 1) {
                    if (starts[i] < 0) {
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
                return m;
            }
        }

        _ = .{regexs};
        return Match{};
    }

    fn matchBegin(self: *Parser, syntax: *Syntax, block: []const u8, start: usize, end: usize) Match {
        // if all this syntax has are patterns.. check patterns
        if (syntax.regex_match == null and syntax.regex_begin == null) {
            return self.matchPatterns(syntax, syntax.patterns, block, start, end);
        }

        // match
        if (syntax.regex_match != null) {
            if (syntax.regex_match) |regex| {
                // check of matching has been previously cached (for the same position in the buffer)
                const m = blk: {
                    const mm = self.match_cache.get(syntax.id) orelse break :blk null;
                    if (mm.anchor_start <= start and mm.anchor_end <= end and mm.start >= start) {
                        self.regex_skips += 1;
                        break :blk mm;
                    }
                    break :blk null;
                } orelse self.execRegex(syntax, regex, syntax.regexs_match, block, start, end);
                _ = self.match_cache.put(syntax.id, m) catch {};
                if (m.count > 0) {
                    return m;
                }
            }
        }

        // begin
        if (syntax.regex_begin != null) {
            if (syntax.regex_begin) |regex| {
                // check of matching has been previously cached (for the same position in the buffer)
                const m = blk: {
                    const mm = self.match_cache.get(syntax.id) orelse break :blk null;
                    if (mm.anchor_start <= start and mm.anchor_end <= end and mm.start >= start) {
                        self.regex_skips += 1;
                        break :blk mm;
                    }
                    break :blk null;
                } orelse self.execRegex(syntax, regex, syntax.regexs_begin, block, start, end);
                _ = self.match_cache.put(syntax.id, m) catch {};
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
                const ls = ts.resolve(ts);
                if (ls) |syn| {
                    if (syn.regex_while) |regex| {
                        const m = self.execRegex(@constCast(syn), regex, syn.regexs_while, block, start, end);
                        if (m.count == 0) {
                            while (state.size() >= state_depth) {
                                state.pop();
                            }
                        }
                    }
                }
            }
        }
    }

    pub fn matchEnd(self: *Parser, state: *ParseState, block: []const u8, start: usize, end: usize) Match {
        // prune if the stack is already too deep like deeply nested blocks
        // TODO investigate why this happens -- (dump end blocks unmatched)
        if (state.size() > MAX_STATE_STACK_DEPTH) {
            if (state.stack.items.len >= MAX_STATE_STACK_DEPTH) {
                const new_len = state.stack.items.len - STATE_STACK_PRUNE;
                @memcpy(
                    state.stack.items[0..new_len],
                    state.stack.items[STATE_STACK_PRUNE..state.stack.items.len],
                );
                state.stack.items.len = new_len;
            }
        }

        const top = state.top();
        if (top) |t| {
            const ts = t.syntax;
            const ls = ts.resolve(ts);
            if (ls) |syn| {
                const end_match: Match = blk: {
                    if (t.end_regex) |r| {
                        // use dynamic end_regex here if one was compiled
                        const m = self.execRegex(@constCast(syn), r, syn.regexs_end, block, start, end);
                        break :blk m;
                    }
                    const m = self.execRegex(@constCast(syn), syn.regex_end, syn.regexs_end, block, start, end);
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
                const ls = p.resolve(p);
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
            var output: [MAX_SCOPE_LEN:0]u8 = [_:0]u8{0} ** MAX_SCOPE_LEN;
            _ = match.applyCaptures(block, name, &output);
            proc.capture(Capture{
                .start = match.start,
                .end = match.end,
                .scope = output,
            });
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
                    var output: [MAX_SCOPE_LEN:0]u8 = [_:0]u8{0} ** MAX_SCOPE_LEN;
                    _ = match.applyCaptures(block, syn.name, &output);
                    proc.capture(Capture{
                        .start = range.start,
                        .end = range.end,
                        .scope = output,
                    });
                }

                // some captures have themselves some patterns
                // TODO needs verification and tests
                if (syn.patterns) |pats| {
                    const ps = match.start; // should be range.start and range.end?
                    const pe = match.end;
                    for (pats) |p| {
                        if (p.regex_match) |regex| {
                            // std.debug.print(">> {s} <<\n", .{p.regexs_match orelse ""});
                            // std.debug.print(">> {s} <<\n", .{block[ps..pe]});
                            const m = self.execRegex(p, regex, p.regexs_match, block, ps, pe);
                            if (m.count > 0) {
                                // std.debug.print("count {}\n", .{m.count});
                                if (p.captures) |*pc| {
                                    // descend into captures
                                    self.collectCaptures(&m, pc, block);
                                } else if (p.name.len > 0) {
                                    var sname: [MAX_SCOPE_LEN:0]u8 = [_:0]u8{0} ** MAX_SCOPE_LEN;
                                    _ = m.applyCaptures(block, p.name, &sname);
                                    if (self.processor) |proc| {
                                        proc.capture(Capture{
                                            .start = range.start,
                                            .end = range.end,
                                            .scope = sname,
                                        });
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    pub fn parseLine(self: *Parser, state: *ParseState, buffer: []const u8) !void {
        var block = self.allocator.alloc(u8, buffer.len + 1) catch {
            return error.OutOfMemory;
        };
        defer self.allocator.free(block);
        @memcpy(block[0..buffer.len], buffer);
        block[buffer.len] = '\n';

        // save the buffer, not block - as block is freed at the end of scope
        if (self.processor) |proc| proc.startLine(buffer);

        self.match_cache.clearRetainingCapacity();

        var start: usize = 0;
        var end = block.len;
        var last_start: usize = 0;
        var last_syntax: ?*Syntax = null;

        // handle while
        // todo track while count
        self.matchWhile(state, block);

        while (true) {
            end = block.len;

            // debug only
            // {
            //     const text = block[start..end];
            //     std.debug.print("====================================\n", .{});
            //     std.debug.print("s:{} e:{} {s}\n", .{ start, end, text });
            // }

            const top = state.top();
            if (top) |t| {
                const ts = t.syntax;
                const ls = ts.resolve(ts);
                if (ls) |syn| {
                    if (state.size() > 1 and syn.parent == null) {
                        // $self was included? clear the stack in this situation?
                        while (state.size() > 1) {
                            state.pop();
                        }
                    }

                    const pattern_match: Match = self.matchPatterns(syn, syn.patterns, block, start, end);
                    const end_match: Match = self.matchEnd(state, block, start, end);
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
                                var scope_name: [MAX_SCOPE_LEN:0]u8 = [_:0]u8{0} ** MAX_SCOPE_LEN;
                                @memcpy(scope_name[0..name.len], name);
                                proc.closeTag(Capture{
                                    .start = end_match.start,
                                    .end = end_match.end,
                                    .scope = scope_name,
                                    .syntax_id = end_syn.id,
                                });
                            }
                        }

                        // pop!
                        state.pop();
                    } else if (pattern_match.count > 0) {
                        if (pattern_match.syntax) |match_syn| {
                            // pattern has been matched
                            //
                            start = pattern_match.start;
                            end = pattern_match.end;

                            self.collectMatch(match_syn, &pattern_match, block);

                            if (match_syn.regexs_end != null) {
                                // if it has a regexs_end.. it is a begin and should cause a push
                                state.push(match_syn, block, pattern_match) catch {
                                    // fail silently?
                                };

                                if (self.processor) |proc| {
                                    const name = match_syn.getName();
                                    var scope_name: [MAX_SCOPE_LEN:0]u8 = [_:0]u8{0} ** MAX_SCOPE_LEN;
                                    @memcpy(scope_name[0..name.len], name);
                                    proc.openTag(Capture{
                                        .start = pattern_match.start,
                                        .end = pattern_match.end,
                                        .scope = scope_name,
                                        .syntax_id = match_syn.id,
                                    });
                                }

                                // collect begin captures
                                if (match_syn.begin_captures) |beg_cap| {
                                    self.collectCaptures(&pattern_match, &beg_cap, block);
                                }
                            } else {
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
                if (last_start == start and last_syntax == ts) {
                    break;
                }

                last_syntax = ts;
                last_start = start;
                start = end;
            } else {
                // no top
                unreachable;
            }
        }

        if (self.processor) |proc| proc.endLine();
    }

    // begin merely resets all stats
    pub fn begin(self: *Parser) void {
        self.regex_execs = 0;
        self.regex_skips = 0;
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
