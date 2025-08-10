const std = @import("std");
const oni = @import("oniguruma");
const grammar = @import("grammar.zig");
const Syntax = grammar.Syntax;

const MAX_CAPTURES = 100;

pub const MatchRange = struct {
    start: usize,
    end: usize,
};

pub const Match = struct {
    syntax: ?*Syntax = null,
    count: u8 = 0,
    captures: [MAX_CAPTURES]MatchRange = [_]MatchRange{MatchRange{ .start = 0, .end = 0 }} ** MAX_CAPTURES,
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

pub const ParseState = struct {
    allocator: std.mem.Allocator,
    stack: std.ArrayList(*Syntax),

    pub fn init(allocator: std.mem.Allocator, syntax: *Syntax) !ParseState {
        var stack = std.ArrayList(*Syntax).init(allocator);
        try stack.append(syntax);

        return ParseState{
            .allocator = allocator,
            .stack = stack,
        };
    }

    pub fn deinit(self: *ParseState) void {
        self.stack.deinit();
    }

    pub fn top(self: *ParseState) ?*Syntax {
        if (self.stack.items.len > 0) {
            return self.stack.items[self.stack.items.len - 1];
        } else {
            return null;
        }
    }

    pub fn pop(self: *ParseState) void {
        if (self.stack.items.len > 0) {
            _ = self.stack.pop();
        }
    }

    pub fn push(self: *ParseState, syntax: *Syntax) void {
        _ = self.stack.append(syntax) catch {};
    }

    pub fn size(self: *ParseState) usize {
        return self.stack.items.len;
    }
};

pub const Parser = struct {
    allocator: std.mem.Allocator,
    lang: *grammar.Grammar,

    pub fn init(allocator: std.mem.Allocator, lang: *grammar.Grammar) !Parser {
        return Parser{ .allocator = allocator, .lang = lang };
    }

    pub fn deinit(self: *Parser) void {
        _ = self;
    }

    fn execRegex(self: *Parser, syntax: *Syntax, regex: ?oni.Regex, regexs: ?[]const u8, block: []const u8, start: usize, end: usize) Match {
        if (regex) |*re| {
            const reg = blk: {
                var result: oni.Region = .{};
                const hard_start: usize = start;
                _ = @constCast(re).searchAdvanced(block, hard_start, end, &result, .{}) catch |err| {
                    if (err == error.Mismatch) {
                        break :blk null; // return null instead
                    } else {
                        return Match{};
                    }
                };
                break :blk result;
            };

            if (reg) |r| {
                // std.debug.print("found!<<<<<<<<<<<<<<<<<<\n", .{});
                var count: u8 = 0;
                var m = Match{
                    .syntax = syntax,
                    .count = 0,
                    .captures = blk: {
                        var captures: [MAX_CAPTURES]MatchRange = [_]MatchRange{MatchRange{ .start = 0, .end = 0 }} ** MAX_CAPTURES;
                        var i: u8 = 0;
                        const starts = r.starts();
                        const ends = r.ends();
                        while (i < r.count()) : (i += 1) {
                            const s: usize = @intCast(starts[i]);
                            const e: usize = @intCast(ends[i]);
                            if (s >= start) {
                                captures[count].start = s;
                                captures[count].end = e;
                                count += 1;
                                std.debug.print("{d}: {s}\n", .{ s, block[captures[i].start..captures[i].end] });
                            }
                        }
                        break :blk captures;
                    },
                };
                if (count > 0) {
                    std.debug.print("{s}\n", .{regexs orelse ""});
                    std.debug.print("{s}\n", .{syntax.name});
                    std.debug.print("{s}\n", .{syntax.scope_name});
                }
                m.count = count;
                return m;
            }
        }

        _ = .{self};
        return Match{};
    }

    fn matchBegin(self: *Parser, syntax: *Syntax, block: []const u8, start: usize, end: usize) Match {
        // match
        if (syntax.regex_match != null) {
            const m = self.execRegex(syntax, syntax.regex_match, syntax.regexs_match, block, start, end);
            if (m.count > 0) {
                return m;
            }
        }
        // begin
        if (syntax.regex_begin != null) {
            var m = self.execRegex(syntax, syntax.regex_begin, syntax.regexs_begin, block, start, end);
            if (m.count > 0) {
                m.begin = true;
                return m;
            }
        }
        if (syntax.regex_end != null or syntax.regex_while != null) {
            return Match{};
        }

        // patterns
        // if (syntax.patterns != null) {
            // return self.matchPatterns(syntax.patterns, block, start, end);
        // }

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
                        //if (m.start() == start) break;
                    }
                }
            }
        }
        return earliest_match;
    }

    pub fn parseLine(self: *Parser, state: *ParseState, buffer: []const u8) void {
        _ = .{ self, state };

        var block = self.allocator.alloc(u8, buffer.len + 1) catch {
            return;
        };
        @memcpy(block[0..buffer.len], buffer);
        block[buffer.len] = '\n';

        var matches = std.ArrayList(Match).init(self.allocator);
        defer matches.deinit();

        var start: usize = 0;
        const end = block.len;
        while (start < end) {
            // debug only
            {
                const text = block[start..end];
                std.debug.print("====================================\n", .{});
                std.debug.print("s:{} e:{} {s}\n", .{ start, end, text });
            }

            const top = state.top();
            if (top) |t| {
                const ls = t.resolve(t);
                if (ls) |syn| {

                    // check end
                    const end_match: Match = self.execRegex(@constCast(syn), syn.regex_end, syn.regexs_end, block, start, end);
                    if (end_match.count > 0) {
                        state.pop();
                        start = end_match.end();
                        continue;
                    }

                    // best match/rule
                    const pattern_match: Match = self.matchPatterns(syn.patterns, block, start, end);
                    if (pattern_match.count == 0) {
                        if (syn.regex_end != null) {
                            state.pop();
                            continue;
                        }
                        start += 1;
                        continue;
                    }

                    matches.append(pattern_match) catch {};
                    start = pattern_match.end();
                    if (pattern_match.begin) {
                        if (pattern_match.syntax) |match_syn| {
                            state.push(match_syn);
                        }
                    }
                    continue;
                }
            }

            break;
        }

        std.debug.print("---------------------------------------------------\n", .{});
        for (matches.items) |m| {
            const text = block[m.start()..m.end()];
            std.debug.print("{s} {}-{} |", .{ text, m.start(), m.end() });
        }
        std.debug.print("\n", .{});
    }

    pub fn parseLine2(self: *Parser, state: *ParseState, buffer: []const u8) void {
        var block = self.allocator.alloc(u8, buffer.len + 1) catch {
            return;
        };
        @memcpy(block[0..buffer.len], buffer);
        block[buffer.len] = '\n';

        var start: usize = 0;
        var end = block.len;
        var last_syntax: ?*Syntax = null;

        var matches = std.ArrayList(Match).init(self.allocator);
        defer matches.deinit();

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
                const ls = t.resolve(t);
                if (ls) |syn| {
                    std.debug.print("{s}\n", .{syn.name});
                    const pattern_match: Match = self.matchPatterns(syn.patterns, block, start, end);
                    const end_match: Match = self.execRegex(@constCast(syn), syn.regex_end, syn.regexs_end, block, start, end);
                    if (end_match.count > 0 and
                        (pattern_match.count == 0 or
                            (pattern_match.count > 0 and pattern_match.start() >= end_match.start())))
                    {
                        matches.append(end_match) catch {};
                        start = end_match.start();
                        end = end_match.end();
                        // collect endCaptures

                        std.debug.print("captures!\n", .{});

                        state.pop();
                    } else if (pattern_match.count > 0) {
                        if (pattern_match.syntax) |match_syn| {
                            matches.append(pattern_match) catch {};
                            start = pattern_match.start();
                            end = pattern_match.end();
                            if (pattern_match.begin) {
                                // _ = match_syn;
                                if (false) state.push(match_syn);
                                std.debug.print("push {}\n", .{state.size()});
                            } else {
                                // simple match .. collect captures
                            }
                        }
                    } else {
                        // no match
                    }
                } else {
                    unreachable;
                }
            } else {
                unreachable;
            }

            if (start == end and last_syntax == top) {
                break;
            }

            last_syntax = top;
            start = end;
        }

        std.debug.print("---------------------------------------------------\n", .{});
        for (matches.items) |m| {
            const text = block[m.start()..m.end()];
            std.debug.print("{s} {}-{} |", .{ text, m.start(), m.end() });
        }
        std.debug.print("\n", .{});
    }
};
