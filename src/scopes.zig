const std = @import("std");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayList;

fn matchesScope(scopes: []const []const u8, target: []const u8) bool {
    for (scopes) |s| {
        if (std.mem.startsWith(u8, s, target)) {
            if (s.len == target.len or s[target.len] == '.') {
                return true;
            }
        }
    }
    return false;
}

const SelectorEvaluator = struct {
    scopes: []const []const u8,
    expr: []const u8,
    pos: usize = 0,

    fn init(scopes: []const []const u8, expr: []const u8) SelectorEvaluator {
        return .{ .scopes = scopes, .expr = expr };
    }

    fn skipWhitespace(self: *SelectorEvaluator) void {
        while (self.pos < self.expr.len and (self.expr[self.pos] == ' ' or self.expr[self.pos] == '\t')) {
            self.pos += 1;
        }
    }

    fn parsePrimary(self: *SelectorEvaluator) bool {
        self.skipWhitespace();
        if (self.pos >= self.expr.len) return false;

        if (self.expr[self.pos] == '(') {
            self.pos += 1;
            const res = self.parseOr();
            self.skipWhitespace();
            if (self.pos < self.expr.len and self.expr[self.pos] == ')') {
                self.pos += 1;
            }
            return res;
        }

        const start = self.pos;
        while (self.pos < self.expr.len) {
            const ch = self.expr[self.pos];
            if (std.ascii.isAlphanumeric(ch) or ch == '.' or ch == '-' or ch == '_') {
                self.pos += 1;
            } else {
                break;
            }
        }
        if (start == self.pos) return false;
        const scope_name = self.expr[start..self.pos];
        return matchesScope(self.scopes, scope_name);
    }

    fn parseOr(self: *SelectorEvaluator) bool {
        var res = self.parseAnd();
        while (true) {
            self.skipWhitespace();
            if (self.pos < self.expr.len and self.expr[self.pos] == '|') {
                self.pos += 1;
                const right = self.parseAnd();
                res = res or right;
            } else {
                break;
            }
        }
        return res;
    }

    fn parseAnd(self: *SelectorEvaluator) bool {
        var res = self.parsePrimary();
        while (true) {
            self.skipWhitespace();
            if (self.pos >= self.expr.len) break;
            const ch = self.expr[self.pos];
            if (ch == '-') {
                self.pos += 1;
                const right = self.parsePrimary();
                res = res and !right;
            } else if (ch == '&') {
                self.pos += 1;
                const right = self.parsePrimary();
                res = res and right;
            } else if (ch == '|' or ch == ')') {
                break;
            } else {
                const right = self.parsePrimary();
                res = res and right;
            }
        }
        return res;
    }
};

pub fn matchesScopeSelector(scopes: []const []const u8, selector: []const u8) bool {
    var alt_it = std.mem.splitScalar(u8, selector, ',');
    while (alt_it.next()) |alt| {
        const trimmed = std.mem.trim(u8, alt, " \t\r\n");
        if (trimmed.len == 0) continue;
        var trimmed_alt = trimmed;
        if (std.mem.startsWith(u8, trimmed_alt, "L:")) {
            trimmed_alt = trimmed_alt[2..];
        } else if (std.mem.startsWith(u8, trimmed_alt, "R:")) {
            trimmed_alt = trimmed_alt[2..];
        }
        var eval = SelectorEvaluator.init(scopes, trimmed_alt);
        if (eval.parseOr()) return true;
    }
    return false;
}
