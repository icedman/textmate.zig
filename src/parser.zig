const std = @import("std");
const oni = @import("oniguruma");
const grammar = @import("grammar.zig");
const Syntax = grammar.Syntax;

const MAX_CAPTURES = 100;

pub const MatchRange = struct {
    start: u32,
    end: u32,
};

pub const Match = struct {
    syntax: ?*Syntax = null,
    count: u8 = 0,
    captures: [MAX_CAPTURES]MatchRange = [_]MatchRange{MatchRange{ .start = 0, .end = 0 }} ** MAX_CAPTURES,
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
    arena: std.heap.ArenaAllocator,
    allocator: std.mem.Allocator,
    lang: *grammar.Grammar,

    pub fn init(allocator: std.mem.Allocator, lang: *grammar.Grammar) !Parser {
        var arena = std.heap.ArenaAllocator.init(allocator);
        const aa = arena.allocator();
        errdefer arena.deinit();
        return Parser{ .arena = arena, .allocator = aa, .lang = lang };
    }

    pub fn deinit(self: *Parser) void {
        self.arena.deinit();
    }

    fn execRegex(self: *Parser, syntax: *Syntax, regex: ?oni.Regex, buffer: []const u8) Match {
        if (regex) |*re| {
            // std.debug.print("matching\n", .{});
            const reg = blk: {
                const result = @constCast(re).search(buffer, .{}) catch |err| {
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
                std.debug.print("found!<<<<<<<<<<<<<<<<<<<\n", .{});
                std.debug.print("count: {d}\n", .{r.count()});
                std.debug.print("starts: {d}\n", .{r.starts()});
                std.debug.print("ends: {d}\n", .{r.ends()});
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

    fn matchPatterns(self: *Parser, patterns: ?[]Syntax, block: []const u8) Match {
        if (patterns) |pats| {
            for (pats) |p| {
                const ls = p.lookup(&p);
                if (ls) |syn| {
                    const m = self.execRegex(@constCast(syn), syn.regex_match, block);
                    if (m.count > 0) {
                        return m;
                    }
                }
            }
        }
        _ = .{ self, block };
        return Match{};
    }

    pub fn parseLine(self: *Parser, state: *ParseState, block: []const u8) void {
        // get top
        while (true) {
            const top = state.top();
            if (top) |t| {
                const ls = t.lookup(t);

                // is->while ... match while
                // has->end ... match end
                // match top->patterns

                if (ls) |syn| {
                    _ = self.execRegex(@constCast(syn), syn.regex_match, block);
                    const pattern_match = self.matchPatterns(syn.patterns, block);
                    if (pattern_match.syntax) |match_syn| {
                        state.push(match_syn);
                    }
                }
            } else {
                unreachable;
            }

            state.pop();
            if (state.size() == 0) break;
        }

        _ = .{ self, block };
    }
};

test "parser" {
    try std.testing.expectEqual(1 + 1, 2);
}
