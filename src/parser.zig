const std = @import("std");
const oni = @import("oniguruma");
const grammar = @import("grammar.zig");
const Syntax = grammar.Syntax;

const MAX_CAPTURES = 100;

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
                std.debug.print("found!<<<<<<<<<<<<<<<<<<\n", .{});
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
                    std.debug.print("{s}\n", .{regexs orelse ""});
                    std.debug.print("{s}\n", .{syntax.name});
                    std.debug.print("{s}\n", .{syntax.scope_name});
                }
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
            const m = self.execRegex(syntax, syntax.regex_begin, syntax.regexs_begin, block, start, end);
            if (m.count > 0) {
                return m;
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
        std.debug.print("capture<<<<<<<<\n", .{});
        _ = .{ self, match, captures, block };
        var it = captures.iterator();
        while (it.next()) |kv| {
            const k = kv.key_ptr.*;
            const v = kv.value_ptr.*;
            std.debug.print("capture {s}\n", .{k});
            _ = .{v};
        }

        for (0..match.count) |i| {
            var buf: [32]u8 = undefined; // enough to hold any int as string
            const range = match.captures[i];
            const key = std.fmt.bufPrint(&buf, "{}", .{range.group}) catch {
                continue;
            };
            const capture: ?*Syntax = captures.get(key);
            if (capture) |syn| {
                // todo.. expand name
                std.debug.print("capture {} {s}\n", .{ range.group, syn.name });
                if (syn.patterns) |pat| {
                    _ = pat;
                    // todo.. collect patterns
                    std.debug.print("has patterns\n", .{});
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
                        if (end_match.syntax) |end_syn| {
                            if (end_syn.end_captures) |end_cap| {
                                self.collectCaptures(&end_match, &end_cap, block);
                            }
                        }

                        state.pop();
                    } else if (pattern_match.count > 0) {
                        if (pattern_match.syntax) |match_syn| {
                            matches.append(pattern_match) catch {};
                            start = pattern_match.start();
                            end = pattern_match.end();
                            if (match_syn.regex_end != null) {
                                state.push(match_syn);
                                std.debug.print("push {}\n", .{state.size()});
                                // collect begin captures
                                if (match_syn.begin_captures) |beg_cap| {
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
                        if (end_match.count > 0 and state.size() > 0) {
                            state.pop();
                        }
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
