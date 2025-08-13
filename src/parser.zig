const std = @import("std");
const oni = @import("oniguruma");
const grammar = @import("grammar.zig");
const utils = @import("utils.zig");
const Syntax = grammar.Syntax;

const MAX_CAPTURES = 100;
const MAX_SCOPE_SIZE = 64;

pub const Capture = struct {
    start: usize,
    end: usize,
    scope: [MAX_SCOPE_SIZE]u8 = [_]u8{0} ** MAX_SCOPE_SIZE,
};

pub const MatchRange = struct {
    group: u16,
    start: usize,
    end: usize,
};

pub const Match = struct {
    syntax: ?*Syntax = null,
    count: u8 = 0,
    captures: [MAX_CAPTURES]MatchRange = [_]MatchRange{MatchRange{ .group = 0, .start = 0, .end = 0 }} ** MAX_CAPTURES,
    begin: bool = false,

    pub fn start(self: *const Match) usize {
        if (self.count > 0) {
            return self.captures[0].start;
        }
        return 0;
    }

    pub fn end(self: *const Match) usize {
        if (self.count > 0) {
            return self.captures[0].end;
        }
        return 0;
    }
};

pub const StateContext = struct {
    syntax: *Syntax,
    end_regex: ?oni.Regex = null,
};

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
                    var output: [utils.TEMP_BUFFER_SIZE]u8 = [_]u8{0} ** utils.TEMP_BUFFER_SIZE;
                    _ = utils.applyReferences(&m, block, regexs, &output);

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
};

pub const Parser = struct {
    allocator: std.mem.Allocator,
    lang: *grammar.Grammar,

    // line parse data
    captures: std.ArrayList(Capture),
    match_cache: std.AutoHashMap(*const oni.Regex, Match),

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
        if (regex) |*re| {
            self.regex_execs += 1;
            const reg = blk: {
                var result: oni.Region = .{};
                const hard_start: usize = start;
                const hard_end: usize = end;
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
                std.debug.print("<<<<<<<<<<<<<<<<<< {s}\n", .{syntax.name});
                var m = Match{
                    .syntax = syntax,
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
                        // std.debug.print("{d}: {s}\n", .{ s, block[m.captures[count].start..m.captures[count].end] });
                        count += 1;
                    }
                }

                m.count = count;

                if (count > 0) {
                    // std.debug.print("{s}\n", .{regexs orelse ""});
                    std.debug.print("{s}\n", .{syntax.name});
                    std.debug.print("{s}\n", .{syntax.scope_name});
                }
                return m;
            }
        }

        _ = .{regexs};
        return Match{};
    }

    fn matchBegin(self: *Parser, syntax: *Syntax, block: []const u8, start: usize, end: usize) Match {
        // match
        if (syntax.regex_match != null) {
            if (syntax.regex_match) |regex| {
                const m = blk: {
                    // fetch cache if valid
                    const mm = self.match_cache.get(&regex) orelse break :blk null;
                    if (mm.count > 0 and mm.start() < start) {
                        break :blk null;
                    }
                    break :blk mm;
                } orelse self.execRegex(syntax, syntax.regex_match, syntax.regexs_match, block, start, end);
                if (m.start() > start) {
                    // save to cache if reusable
                    _ = self.match_cache.put(&regex, m) catch {};
                }
                // const m = self.execRegex(syntax, regex, syntax.regexs_match, block, start, end);
                if (m.count > 0) {
                    return m;
                }
            }
        }
        // begin
        if (syntax.regex_begin != null) {
            if (syntax.regex_begin) |regex| {
                const m = blk: {
                    // fetch cache if valid
                    const mm = self.match_cache.get(&regex) orelse break :blk null;
                    if (mm.count > 0 and mm.start() < start) {
                        break :blk null;
                    }
                    break :blk mm;
                } orelse self.execRegex(syntax, syntax.regex_begin, syntax.regexs_begin, block, start, end);
                if (m.start() > start) {
                    // save to cache if reusable
                    _ = self.match_cache.put(&regex, m) catch {};
                }
                // const m = self.execRegex(syntax, regex, syntax.regexs_begin, block, start, end);
                if (m.count > 0) {
                    return m;
                }
            }
        }

        // check patterns
        if (syntax.regex_match == null and syntax.regex_begin == null) {
            return self.matchPatterns(syntax.patterns, block, start, end);
        }
        return Match{};
    }

    fn matchPatterns(self: *Parser, patterns: ?[]*Syntax, block: []const u8, start: usize, end: usize) Match {
        var earliest_match = Match{};
        if (patterns) |pats| {
            for (pats) |p| {
                const ls = p.resolve(p);
                if (ls) |syn| {
                    // std.debug.print(">{s}\n", .{syn.name});
                    const m = self.matchBegin(@constCast(syn), block, start, end);
                    if (m.count > 0) {
                        if (earliest_match.count == 0) {
                            earliest_match = m;
                        } else if (earliest_match.start() > m.start()) {
                            earliest_match = m;
                        } else if (earliest_match.start() == m.start() and m.end() > earliest_match.end()) {
                            earliest_match = m;
                        }
                        if (m.start() == start) break;
                    }
                }
            }
        }
        return earliest_match;
    }

    fn collectCaptures(self: *Parser, match: *const Match, captures: *const std.StringHashMap(*Syntax), block: []const u8) void {
        std.debug.print("captures\n", .{});
        _ = .{ self, match, captures, block };
        for (0..match.count) |i| {
            var buf: [32]u8 = undefined; // enough to hold any int as string
            const range = match.captures[i];
            if (range.start == 0 and range.end == 0) continue;
            const key = std.fmt.bufPrint(&buf, "{}", .{range.group}) catch {
                continue;
            };
            const capture: ?*Syntax = captures.get(key);
            if (capture) |syn| {
                std.debug.print("capture {} {s}\n", .{ range.group, syn.name });
                var output: [utils.TEMP_BUFFER_SIZE]u8 = [_]u8{0} ** utils.TEMP_BUFFER_SIZE;
                _ = utils.applyCaptures(match, block, syn.name, &output);
                self.captures.append(Capture{
                    .start = range.start,
                    .end = range.end,
                    .scope = output,
                }) catch {};
                std.debug.print("{s}\n", .{output});
                if (syn.patterns) |pat| {
                    _ = pat;
                    // todo.. collect patterns
                    std.debug.print("has uncollected patterns\n", .{});
                }
            }
        }
    }

    pub fn parseLine(self: *Parser, state: *ParseState, buffer: []const u8) void {
        var block = self.allocator.alloc(u8, buffer.len + 1) catch {
            return;
        };
        defer self.allocator.free(block);
        @memcpy(block[0..buffer.len], buffer);
        block[buffer.len] = '\n';

        self.match_cache.clearRetainingCapacity();
        self.captures.clearRetainingCapacity();

        var start: usize = 0;
        var end = block.len;
        var last_syntax: ?*Syntax = null;

        // handle while
        // todo track while count
        var state_depth = state.size();
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

        while (true) {
            end = block.len;

            // debug only
            {
                const text = block[start..end];
                std.debug.print("====================================\n", .{});
                std.debug.print("s:{} e:{} {s}\n", .{ start, end, text });
            }

            const top = state.top();
            if (top) |t| {
                const ts = t.syntax;
                const ls = ts.resolve(ts);
                if (ls) |syn| {
                    std.debug.print("{s}\n", .{syn.name});
                    const pattern_match: Match = self.matchPatterns(syn.patterns, block, start, end);
                    const end_match: Match = blk: {
                        if (t.end_regex) |r| {
                            // use dynamic end_regex here if one was compiled
                            const m = self.execRegex(@constCast(syn), r, syn.regexs_end, block, start, end);
                            break :blk m;
                        }
                        const m = self.execRegex(@constCast(syn), syn.regex_end, syn.regexs_end, block, start, end);
                        break :blk m;
                    };
                    if (end_match.count > 0 and
                        (pattern_match.count == 0 or
                            (pattern_match.count > 0 and pattern_match.start() >= end_match.start())))
                    {
                        start = end_match.start();
                        end = end_match.end();

                        // collect endCaptures
                        if (end_match.syntax) |end_syn| {
                            if (end_syn.end_captures) |end_cap| {
                                self.collectCaptures(&end_match, &end_cap, block);
                            }
                        }

                        std.debug.print("!pop\n", .{});
                        state.pop();
                    } else if (pattern_match.count > 0) {
                        if (pattern_match.syntax) |match_syn| {
                            start = pattern_match.start();
                            end = pattern_match.end();
                            if (match_syn.regex_end != null) {
                                state.push(match_syn, block, pattern_match) catch {
                                    // fail silently?
                                };
                                std.debug.print("push {}\n", .{state.size()});
                                // collect begin captures
                                if (match_syn.begin_captures) |beg_cap| {
                                    self.captures.append(Capture{
                                        .start = pattern_match.start(),
                                        .end = pattern_match.end(),
                                        .scope = blk: {
                                            var scope: [MAX_SCOPE_SIZE]u8 = [_]u8{0} ** MAX_SCOPE_SIZE;
                                            var l = match_syn.name.len;
                                            if (l > MAX_SCOPE_SIZE) {
                                                l = MAX_SCOPE_SIZE;
                                            }
                                            @memcpy(scope[0..l], match_syn.name);
                                            break :blk scope;
                                        },
                                    }) catch {};

                                    self.collectCaptures(&pattern_match, &beg_cap, block);
                                }
                            } else {
                                // simple match .. collect captures
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

                if (start == end and last_syntax == ts) {
                    break;
                }

                last_syntax = ts;
                start = end;
            } else {
                // no top
                unreachable;
            }
        }

        std.debug.print("---------------------------------------------------\n", .{});
        for (self.captures.items) |m| {
            const text = block[m.start..m.end];
            std.debug.print("{s} {s}\n", .{ text, m.scope });
        }
        std.debug.print("\n", .{});
    }

    pub fn begin(self: *Parser) void {
        self.regex_execs = 0;
    }
};
