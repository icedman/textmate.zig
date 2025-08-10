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

    pub fn firstStart(self: *const Match) usize {
        if (self.count > 0) {
            return self.captures[0].start;
        }
        return 0;
    }

    pub fn firstEnd(self: *const Match) usize {
        if (self.count > 0) {
            return self.captures[0].end;
        }
        return 0;
    }

    pub fn offset(self: *const Match, start: usize) Match {
        var m = self.*;
        for (0..m.count) |i| {
            m.captures[i].start += start;
            m.captures[i].end += start;
        }
        return m;
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

    fn execRegex(self: *Parser, syntax: *Syntax, regex: ?oni.Regex, regexs: ?[]const u8, block: []const u8, start: usize) Match {
        if (regex) |*re| {
            const reg = blk: {
                var result: oni.Region = .{};
                //const result = @constCast(re).search(block, .{}) catch |err| {
                _ = @constCast(re).searchAdvanced(block, start, block.len, &result, .{}) catch |err| {
                    if (err == error.Mismatch) {
                        // std.debug.print("no match\n", .{});
                        break :blk null; // return null instead
                    } else {
                        // some other error
                        return Match{};
                    }
                };
                break :blk result;
            };

            if (reg) |r| {
                // std.debug.print("found!<<<<<<<<<<<<<<<<<<<\n", .{});
                std.debug.print("{s}\n", .{regexs orelse ""});
                std.debug.print("{s}\n", .{syntax.name});
                std.debug.print("{s}\n", .{syntax.scope_name});
                // std.debug.print("count: {d}\n", .{r.count()});
                // std.debug.print("starts: {d}\n", .{r.starts()});
                // std.debug.print("ends: {d}\n", .{r.ends()});
                return Match{
                    .syntax = syntax,
                    .count = @intCast(r.count()),
                    .captures = blk: {
                        var captures: [MAX_CAPTURES]MatchRange = [_]MatchRange{MatchRange{ .start = 0, .end = 0 }} ** MAX_CAPTURES;
                        var i: u8 = 0;
                        const starts = r.starts();
                        const ends = r.ends();
                        while (i < r.count()) : (i += 1) {
                            captures[i].start = @intCast(starts[i]);
                            captures[i].end = @intCast(ends[i]);
                            std.debug.print("{d}: {s}\n", .{ i, block[captures[i].start..captures[i].end] });
                        }
                        break :blk captures;
                    },
                };
            } else {
                // std.debug.print("no match, continuing\n", .{});
            }
        }

        _ = .{self};
        return Match{};
    }

    fn matchBegin(self: *Parser, syntax: *Syntax, block: []const u8, start: usize) Match {
        // match
        {
            const m = self.execRegex(syntax, syntax.regex_match, syntax.regexs_match, block, start);
            if (m.count > 0) {
                return m;
            }
        }
        // begin
        {
            var m = self.execRegex(syntax, syntax.regex_begin, syntax.regexs_begin, block, start);
            if (m.count > 0) {
                m.begin = true;
                return m;
            }
        }
        // patterns
        return self.matchPatterns(syntax.patterns, block, start);
    }

    fn matchPatterns(self: *Parser, patterns: ?[]*Syntax, block: []const u8, start: usize) Match {
        var earliest_match = Match{};
        if (patterns) |pats| {
            for (pats) |p| {
                const ls = p.resolve(p);
                if (ls) |syn| {
                    const m = self.matchBegin(@constCast(syn), block, start);
                    if (m.count > 0) {
                        if (earliest_match.count == 0) {
                            earliest_match = m;
                        } else if (earliest_match.firstStart() > m.firstStart()) {
                            earliest_match = m;
                        } else if (earliest_match.firstStart() == m.firstStart() and
                            earliest_match.firstEnd() < m.firstEnd())
                        {
                            earliest_match = m;
                        }
                    }
                }
            }
        }
        _ = .{ self, block };
        if (earliest_match.count > 0) {
            std.debug.print("pattern: {}-{}\n", .{ earliest_match.firstStart(), earliest_match.firstEnd() });
        }
        return earliest_match;
    }

    pub fn parseLine(self: *Parser, state: *ParseState, buffer: []const u8) void {
        var block = self.allocator.alloc(u8, buffer.len + 1) catch {
            return;
        };
        @memcpy(block[0..buffer.len], buffer);
        block[buffer.len] = '\n'; // if you want to add newline

        var start: usize = 0;
        const end = block.len;

        var matches = std.ArrayList(Match).init(self.allocator);
        defer matches.deinit();

        // todo handle while

        while (true) {
            const text = block[start..end];
            std.debug.print("====================================\n", .{});
            std.debug.print("s:{} e:{} {s}\n", .{ start, end, text });
            const top = state.top();
            if (top) |t| {
                const ls = t.resolve(t);
                if (ls) |syn| {
                    std.debug.print("{s}\n", .{syn.name});
                    const pattern_match: Match = self.matchPatterns(syn.patterns, block, start);
                    const end_match: Match = self.execRegex(@constCast(syn), syn.regex_end, syn.regexs_end, block, start);
                    if (end_match.count > 0 and
                        (pattern_match.count == 0 or
                            (pattern_match.count > 0 and pattern_match.firstStart() >= end_match.firstStart())))
                    {
                        matches.append(end_match) catch {};
                        start = end_match.firstEnd();
                        state.pop();
                    } else if (pattern_match.count > 0) {
                        if (pattern_match.syntax) |match_syn| {
                            matches.append(pattern_match) catch {};
                            start = pattern_match.firstEnd();
                            if (pattern_match.begin) {
                                // std.debug.print("begin!<<<<<<<<<<<<<<<<<<<< {s}\n", .{match_syn.regexs_orelse ""});
                                _ = match_syn;
                                //state.push(match_syn);
                                std.debug.print("push {}\n", .{state.size()});
                            }
                        }
                    } else {
                        // not match
                        break;
                    }
                } else {
                    unreachable;
                }
            } else {
                unreachable;
            }

            if (start == end) break;
        }
        std.debug.print("---------------------------------------------------\n", .{});
        for (matches.items) |m| {
            const text = block[m.firstStart()..m.firstEnd()];
            std.debug.print("{s} {}-{} |", .{ text, m.firstStart(), m.firstEnd() });
        }
        std.debug.print("\n", .{});
    }
};

test "parser" {
    try std.testing.expectEqual(1 + 1, 2);
}
