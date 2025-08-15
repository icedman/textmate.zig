const std = @import("std");
const oni = @import("oniguruma");
const grammar = @import("grammar.zig");
const processor = @import("processor.zig");
const Syntax = grammar.Syntax;

const MAX_CAPTURES = 100;
const MAX_SCOPE_SIZE = 128;
const TEMP_BUFFER_SIZE = 128;

pub const Capture = struct {
    start: usize = 0,
    end: usize = 0,
    scope: [MAX_SCOPE_SIZE]u8 = [_]u8{0} ** MAX_SCOPE_SIZE,
};

pub const MatchRange = struct {
    group: u16 = 0,
    start: usize = 0,
    end: usize = 0,
};

pub const Match = struct {
    syntax: ?*Syntax = null,
    count: u8 = 0,
    captures: [MAX_CAPTURES]MatchRange = [_]MatchRange{MatchRange{ .group = 0, .start = 0, .end = 0 }} ** MAX_CAPTURES,
    begin: bool = false,

    start: usize = 0,
    end: usize = 0,

    //
    anchor_start: usize = 0,
    anchor_end: usize = 0,

    fn applyRef(self: *const Match, block: []const u8, target: []const u8, escape_character: u8, output: *[TEMP_BUFFER_SIZE]u8) []const u8 {
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
                    const r = self.captures[i];
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

    pub fn applyReferences(self: *const Match, block: []const u8, target: []const u8, output: *[TEMP_BUFFER_SIZE]u8) []const u8 {
        return self.applyRef(block, target, '\\', output);
    }

    pub fn applyCaptures(self: *const Match, block: []const u8, target: []const u8, output: *[TEMP_BUFFER_SIZE]u8) []const u8 {
        return self.applyRef(block, target, '$', output);
    }
};

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
                    var output: [TEMP_BUFFER_SIZE]u8 = [_]u8{0} ** TEMP_BUFFER_SIZE;
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
    captures: std.ArrayList(Capture),
    match_cache: std.AutoHashMap(*const oni.Regex, Match),

    // processor
    processor: ?*processor.Processor = null,

    // stats
    regex_execs: usize = 0,

    pub fn init(allocator: std.mem.Allocator, lang: *grammar.Grammar) !Parser {
        return Parser{
            .allocator = allocator,
            .lang = lang,
            .captures = std.ArrayList(Capture).init(allocator),
            .match_cache = std.AutoHashMap(*const oni.Regex, Match).init(allocator),
        };
    }

    pub fn deinit(self: *Parser) void {
        self.captures.deinit();
        self.match_cache.deinit();
    }

    fn execRegex(self: *Parser, syntax: *Syntax, regex: ?oni.Regex, regexs: ?[]const u8, block: []const u8, start: usize, end: usize) Match {
        // std.debug.print("execRegex {s}\n", .{regexs orelse ""});
        if (regex) |*re| {
            self.regex_execs += 1;
            const hard_start: usize = start;
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
                while (i < r.count()) : (i += 1) {
                    if (starts[i] < 0) {
                        // -1 could happen in oniguruma when an optional capture group didn't match
                        // case: when no newline '\n' is present (c.tmLanguage)
                        continue;
                    }
                    const s: usize = @intCast(starts[i]);
                    const e: usize = @intCast(ends[i]);
                    if (s >= start) {
                        m.captures[count].group = i;
                        m.captures[count].start = s;
                        m.captures[count].end = e;

                        if (count == 0) {
                            m.start = s;
                            m.end = e;
                        }

                        // std.debug.print("{}-{}: {s}\n", .{ s, e, block[m.captures[count].start..m.captures[count].end] });
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
        // std.debug.print("matchBegin\n", .{});
        // match
        if (syntax.regex_match != null) {
            if (syntax.regex_match) |regex| {
                const m = blk: {
                    const mm = self.match_cache.get(&regex) orelse break :blk null;
                    if (mm.anchor_start == start and mm.anchor_end == end) {
                        break :blk mm;
                    }
                    break :blk null;
                } orelse self.execRegex(syntax, regex, syntax.regexs_match, block, start, end);
                // const m = self.execRegex(syntax, regex, syntax.regexs_match, block, start, end);
                if (m.count > 0) {
                    // _ = self.match_cache.put(&regex, m) catch {};
                    // std.debug.print("match {s} {}-{}\n", .{syntax.regexs_match orelse "??", m.start, m.end});
                    return m;
                }
            }
        }
        // begin
        if (syntax.regex_begin != null) {
            if (syntax.regex_begin) |regex| {
                var m = blk: {
                    // check if previously failed
                    const mm = self.match_cache.get(&regex) orelse break :blk null;
                    if (mm.anchor_start == start and mm.anchor_end == end) {
                        break :blk mm;
                    }
                    break :blk null;
                } orelse self.execRegex(syntax, regex, syntax.regexs_begin, block, start, end);
                // cache failure
                // var m = self.execRegex(syntax, regex, syntax.regexs_begin, block, start, end);
                if (m.count > 0) {
                    // _ = self.match_cache.put(&regex, m) catch {};
                    m.begin = true;
                    // std.debug.print("begin {s} {}-{}\n", .{syntax.regexs_begin orelse "??", m.start, m.end});
                    return m;
                }
            }
        }

        // check patterns
        if (syntax.regex_match == null and syntax.regex_begin == null) {
            // std.debug.print("descending into more patterns matchPatterns\n", .{});
            return self.matchPatterns(syntax, syntax.patterns, block, start, end);
        }
        return Match{};
    }

    // todo while could have captures
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

    // end match checking is against the  state stack to pop-out as much as possible
    pub fn matchEnd(self: *Parser, state: *ParseState, block: []const u8, start: usize, end: usize) Match {
        // prune
        if (state.size() > 200) {
            if (state.stack.items.len >= 200) {
                const new_len = state.stack.items.len - 120;
                @memcpy(
                    state.stack.items[0..new_len],
                    state.stack.items[120..state.stack.items.len],
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
        // std.debug.print("matchPatterns {s} {s}\n", .{ syntax.name, syntax.include_path orelse "." });
        var earliest_match = Match{};
        if (patterns) |pats| {
            for (pats) |p| {
                // std.debug.print("..pattern\n", .{});
                const ls = p.resolve(p);
                if (ls) |syn| {
                    // std.debug.print(">{s} {s}\n", .{ syn.name, syn.include_path orelse "." });
                    const m = self.matchBegin(@constCast(syn), block, start, end);
                    if (m.count > 0) {
                        if (earliest_match.count == 0) {
                            earliest_match = m;
                        } else if (earliest_match.start > m.start) {
                            earliest_match = m;
                        } else if (earliest_match.start == m.start and m.end > earliest_match.end) {
                            // if (earliest_match.syntax) |end_syn| {
                            //     if (end_syn.regexs_end == null) {
                            //         earliest_match = m;
                            //     }
                            // } else {
                            earliest_match = m;
                            // }
                        }
                        if (m.start == start) {
                            earliest_match = m;
                            break;
                        }
                    }
                }
            }
        }

        // if (earliest_match.syntax) |syn| {
        //     if (earliest_match.begin) {
        //         std.debug.print("final begin: {s}\n", .{syn.regexs_begin orelse ""});
        //     } else {
        //         std.debug.print("final match: {s}\n", .{syn.regexs_match orelse ""});
        //     }
        // }
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
        var output: [TEMP_BUFFER_SIZE]u8 = [_]u8{0} ** TEMP_BUFFER_SIZE;
        _ = match.applyCaptures(block, name, &output);
        self.captures.append(Capture{
            .start = match.start,
            .end = match.end,
            .scope = output,
        }) catch {};

        if (self.processor) |proc| {
            const cap = self.captures.items[self.captures.items.len - 1];
            proc.capture(&cap);
        }
    }

    fn collectCaptures(self: *Parser, match: *const Match, captures: *const std.StringHashMap(*Syntax), block: []const u8) void {
        // std.debug.print("captures\n", .{});
        for (0..match.count) |i| {
            var buf: [32]u8 = undefined; // enough to hold any int as string
            const range = match.captures[i];
            if (range.start == 0 and range.end == 0) continue;
            const key = std.fmt.bufPrint(&buf, "{}", .{range.group}) catch {
                continue;
            };

            // std.debug.print("captures key {s}\n", .{key});

            const capture: ?*Syntax = captures.get(key);
            if (capture) |syn| {
                // std.debug.print("capture {} {s}\n", .{ range.group, syn.name });
                var output: [TEMP_BUFFER_SIZE]u8 = [_]u8{0} ** TEMP_BUFFER_SIZE;
                _ = match.applyCaptures(block, syn.name, &output);
                self.captures.append(Capture{
                    .start = range.start,
                    .end = range.end,
                    .scope = output,
                }) catch {};
                // std.debug.print("{s}\n", .{output});

                if (self.processor) |proc| {
                    const cap = self.captures.items[self.captures.items.len - 1];
                    proc.capture(&cap);
                }

                // some captures have themselves some patterns
                // TODO needs verification
                if (syn.patterns) |pats| {
                    const ps = match.start; // should be range.start and range.end?
                    const pe = match.end;
                    // std.debug.print("has uncollected patterns\n", .{});
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
                                    var sname: [TEMP_BUFFER_SIZE]u8 = [_]u8{0} ** TEMP_BUFFER_SIZE;
                                    _ = m.applyCaptures(block, p.name, &sname);
                                    self.captures.append(Capture{
                                        .start = range.start,
                                        .end = range.end,
                                        .scope = sname,
                                    }) catch {};

                                    if (self.processor) |proc| {
                                        const cap = self.captures.items[self.captures.items.len - 1];
                                        proc.capture(&cap);
                                    }
                                    // std.debug.print("captured_name: {s}<??\n", .{p.name});
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    pub fn parseLine(self: *Parser, state: *ParseState, buffer: []const u8) !*std.ArrayList(Capture) {
        var block = self.allocator.alloc(u8, buffer.len + 1) catch {
            return error.OutOfMemory;
        };
        defer self.allocator.free(block);
        @memcpy(block[0..buffer.len], buffer);
        block[buffer.len] = '\n';

        if (self.processor) |proc| proc.startLine(block);

        self.match_cache.clearRetainingCapacity();
        self.captures.clearRetainingCapacity();

        var start: usize = 0;
        var end = block.len;
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
                    const pattern_match: Match = self.matchPatterns(syn, syn.patterns, block, start, end);
                    const end_match: Match = self.matchEnd(state, block, start, end);
                    if (end_match.count > 0 and
                        (pattern_match.count == 0 or
                            (pattern_match.count > 0 and pattern_match.start >= end_match.start)))
                    {
                        start = end_match.start;
                        end = end_match.end;

                        // collect endCaptures
                        if (end_match.syntax) |end_syn| {
                            self.collectMatch(end_syn, &end_match, block);
                            if (end_syn.end_captures) |end_cap| {
                                self.collectCaptures(&end_match, &end_cap, block);
                            }
                        }

                        if (self.processor) |proc| proc.closeTag(&end_match);
                        // std.debug.print("pop {s} {}\n", .{ syn.name, state.size() });
                        state.pop();
                    } else if (pattern_match.count > 0) {
                        if (pattern_match.syntax) |match_syn| {
                            start = pattern_match.start;
                            end = pattern_match.end;

                            self.collectMatch(match_syn, &pattern_match, block);

                            if (pattern_match.begin or match_syn.regexs_end != null) {
                                state.push(match_syn, block, pattern_match) catch {
                                    // fail silently?
                                };
                                // std.debug.print("push {s} {}\n", .{ match_syn.name, state.size() });
                                if (self.processor) |proc| proc.openTag(&pattern_match);

                                // collect begin captures
                                if (match_syn.begin_captures) |beg_cap| {
                                    // std.debug.print("beginCaptures\n", .{});
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

                last_syntax = ts;
                start = end;
            } else {
                // no top
                unreachable;
            }
        }

        if (self.processor) |proc| proc.endLine();

        // std.debug.print("---------------------------------------------------\n", .{});
        // for (self.captures.items) |m| {
        //     const text = block[m.start..m.end];
        //     std.debug.print("{s} {s}\n", .{ text, m.scope });
        // }
        // std.debug.print("\n", .{});

        return &self.captures;
    }

    pub fn begin(self: *Parser) void {
        self.regex_execs = 0;
    }
};

test "test references" {
    const block: []const u8 = "abcdefg";
    var m = Match{};
    m.count = 2;
    m.captures[0].group = 1;
    m.captures[0].start = 0;
    m.captures[0].end = 2;
    m.captures[1].group = 2;
    m.captures[1].start = 3;
    m.captures[1].end = 5;
    var output: [TEMP_BUFFER_SIZE]u8 = [_]u8{0} ** TEMP_BUFFER_SIZE;
    _ = m.applyReferences(block, "hello \\1 world \\2.", &output);

    const expectedOutput = "hello ab world de.";
    try std.testing.expectEqualStrings(output[0..expectedOutput.len], expectedOutput);
}
