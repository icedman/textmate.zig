// TODO
// scope selection needs to be accurate for rendering to be accurate
const std = @import("std");
const resources = @import("resources.zig");
const theme = @import("theme.zig");
const util = @import("util.zig");
const ThemeInfo = resources.ThemeInfo;

const BITS_PER_ATOM = 10;

fn addAtom(scope: []const u8, map: *std.StringHashMap(u32)) void {
    // std.debug.print("[{s}]\n", .{scope});
    var sc = scope[0..scope.len];
    while (sc.len > 0) {
        if (sc[0] == ' ') {
            sc = sc[1..sc.len];
        } else {
            break;
        }
    }
    if (sc.len == 0) return;

    const gop = map.getOrPut(sc) catch {
        // failing silently
        return;
    };
    if (!gop.found_existing) {
        // gop.value_ptr.* = 0;
        gop.value_ptr.* = 1 + map.count();
    }
    // gop.value_ptr.* += 1;
}

pub fn extractAtom(scope_: []const u8, map: *std.StringHashMap(u32)) void {
    if (scope_.len == 0) {
        return;
    }

    var scope = scope_[0..scope_.len];
    if (scope[0] == '.') {
        scope = scope[1..scope.len];
    }

    // has comma
    {
        const idx = std.mem.indexOf(u8, scope, ",") orelse 0;
        if (idx > 0) {
            extractAtom(scope[0..idx], map);
            extractAtom(scope[idx + 1 ..], map);
            return;
        }
    }
    // has space
    {
        const idx = std.mem.indexOf(u8, scope, " ") orelse 0;
        if (idx > 0) {
            extractAtom(scope[0..idx], map);
            extractAtom(scope[idx + 1 ..], map);
            return;
        }
    }

    // split by "."
    const idx = std.mem.indexOf(u8, scope, ".") orelse 0;
    if (idx > 0) {
        // std.debug.print("{s}\n", .{scope[idx+1..]});
        addAtom(scope[0..idx], map);
        extractAtom(scope[idx + 1 ..], map);
        return;
    }
    addAtom(scope, map);
}

fn testLoadingAllThemes(allocator: std.mem.Allocator) !void {
    var map = std.StringHashMap(u32).init(allocator);
    defer map.deinit();

    var list = std.ArrayList(ThemeInfo).init(allocator);
    defer list.deinit();
    try resources.listThemes(allocator, "./data/themes", &list);

    var themes = std.ArrayList(theme.Theme).init(allocator);
    defer themes.deinit();
    for (list.items) |item| {
        const p: []const u8 = &item.full_path;
        const thm = theme.Theme.init(allocator, util.toSlice([]const u8, p)) catch {
            unreachable;
        };

        try themes.append(thm);

        std.debug.print("----------------\n", .{});
        std.debug.print(" {s}\n", .{thm.name});
        std.debug.print("----------------\n", .{});
        if (thm.tokenColors) |tc| {
            for (tc) |tokenColor| {
                if (tokenColor.scope) |sc| {
                    // std.debug.print("{s}\n", .{sc});
                    for (sc) |scope_name| {
                        extractAtom(scope_name, &map);
                    }
                }
            }
        }
    }

    if (true) {
        var num: usize = 1;
        var it = map.iterator();
        while (it.next()) |item| {
            const k = item.key_ptr.*;
            const v = item.value_ptr.*;
            std.debug.print("{} {s} {}\n", .{ num, k, v });
            num += 1;
        }
    }

    for (themes.items) |*item| {
        item.deinit();
    }
}

pub const Atom = struct {
    id: u128 = 0,
    count: u8 = 0,

    pub fn compute(self: *Atom, scope: []const u8, map: *std.StringHashMap(u32)) void {
        const a = atomize(scope, map);
        self.id = a.id;
        self.count = a.count;
    }

    pub fn cmp(a: Atom, b: Atom) u8 {
        return atomsCmp(a, b);
    }
};

fn atomize(scope_: []const u8, map: *std.StringHashMap(u32)) Atom {
    var atom = Atom{};
    // std.debug.print("{s}\n", .{scope_});
    var scope = scope_[0..scope_.len];
    var shift: u7 = 0;
    while (std.mem.indexOf(u8, scope, ".")) |idx| {
        if (map.get(scope[0..idx])) |g| {
            const ga: u128 = g;
            atom.id = atom.id | (ga << shift);
            atom.count += 1;
            // std.debug.print("{} {s} {}\n", .{shift, scope[0..idx], g});
            shift += BITS_PER_ATOM;
        }
        scope = scope[idx + 1 ..];
    }
    if (map.get(scope[0..])) |g| {
        const ga: u128 = g;
        atom.id = atom.id | (ga << shift);
        atom.count += 1;
        // std.debug.print("{s} {}\n", .{scope[0..], g});
    }
    return atom;
}

const masks = [_]u128{
    (@as(u128, 0b1111111111)) << 0,
    (@as(u128, 0b1111111111)) << 10,
    (@as(u128, 0b1111111111)) << 20,
    (@as(u128, 0b1111111111)) << 30,
    (@as(u128, 0b1111111111)) << 40,
    (@as(u128, 0b1111111111)) << 50,
    (@as(u128, 0b1111111111)) << 60,
    (@as(u128, 0b1111111111)) << 70,
    (@as(u128, 0b1111111111)) << 80,
    (@as(u128, 0b1111111111)) << 90,
    (@as(u128, 0b1111111111)) << 100,
    (@as(u128, 0b1111111111)) << 110,
};

pub fn atomsCmp(a_: Atom, b_: Atom) u8 {
    const a = if (a_.count > b_.count) a_ else b_;
    const b = if (a_.count > b_.count) b_ else a_;

    var matches: u8 = 0;
    var shift: u7 = 0;

    // Try all alignments of b against a
    for (0..a.count) |_| {
        const shifted_b = b.id << shift;

        for (0..a.count) |i| {
            const mask = masks[i];
            if ((a.id & mask) == (shifted_b & mask)) {
                matches += 1;
            }
        }

        shift += BITS_PER_ATOM;
    }
    return matches;
}

fn testTheme(allocator: std.mem.Allocator) !void {
    var thm = theme.Theme.init(allocator, "./data/themes/aurora-x.json") catch {
        // var thm = theme.Theme.init(allocator, "./data/themes/vitesse-dark.json") catch {
        unreachable;
    };
    defer thm.deinit();

    var map = std.StringHashMap(u32).init(allocator);
    defer map.deinit();

    std.debug.print("----------------\n", .{});
    std.debug.print("{s}\n", .{thm.name});
    std.debug.print("----------------\n", .{});
    if (thm.tokenColors) |tc| {
        for (tc) |tokenColor| {
            if (tokenColor.scope) |sc| {
                // std.debug.print("{s}\n", .{sc});
                for (sc) |scope_name| {
                    extractAtom(scope_name, &map);
                }
            }
            // if (tokenColor.settings) |ss| {
            //     std.debug.print("{s}\n", .{ss.foreground orelse "???"});
            // }
        }
    }

    std.debug.print("----------------\n", .{});
    const scope_input = "entity.name.function.c";
    // const scope_input = "punctuation.section.parameters.begin.bracket.round.c";
    // const scope_input = "meta.function.definition.parameters.c";
    // const scope_input = "punctuation.section.parameters.end.bracket.round.c";
    // const scope_input = "markup.list.unnumbered.markdown";
    const sa = atomize(scope_input, &map);
    std.debug.print("{s}\n", .{scope_input});
    if (thm.tokenColors) |tc| {
        for (tc) |tokenColor| {
            if (tokenColor.scope) |sc| {
                for (sc) |scope_name| {
                    if (std.mem.indexOf(u8, scope_name, ",")) |_| continue;
                    if (std.mem.indexOf(u8, scope_name, " ")) |_| continue;
                    const sca = atomize(scope_name, &map);
                    const matches = atomsCmp(sa, sca);
                    if (matches > 0) {
                        std.debug.print("-- {s} {} => {s}\n", .{ scope_name, matches, tokenColor.settings.?.foreground orelse "" });
                        if (matches == sa.count) break;
                    }
                }
            }
        }
    }

    if (false) {
        var it = map.iterator();
        while (it.next()) |item| {
            const k = item.key_ptr.*;
            const v = item.value_ptr.*;
            std.debug.print("{s} {}\n", .{ k, v });
        }
    }
}

test "scopes" {
    const allocator = std.testing.allocator;
    // try testLoadingAllThemes(allocator);
    try testTheme(allocator);
    //
    // test .. markup.list.unnumbered.markdown
}
