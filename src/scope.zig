// TODO
// scope selection needs to be accurate for rendering to be accurate
const std = @import("std");
const resources = @import("resources.zig");
const theme = @import("theme.zig");
const util = @import("util.zig");
const ThemeInfo = resources.ThemeInfo;

// TODO
// These needs to be in a config or option.zig and in smallcaps
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
        // ID is positio in the map as it is added
        gop.value_ptr.* = 1 + map.count();
    }
}

// TODO should be extractAtomsFromScopeName
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
    // has -
    {
        const idx = std.mem.indexOf(u8, scope, " - ") orelse 0;
        if (idx > 0) {
            extractAtom(scope[0..idx], map);
            extractAtom(scope[idx + 3 ..], map);
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

// Given the default 60 themes only 743 unique IDs were generated (u128 for ID with u10 for IDs will be more than enough)
fn testLoadingAllThemes(allocator: std.mem.Allocator) !void {
    var map = std.StringHashMap(u32).init(allocator);
    defer map.deinit();

    var list = std.ArrayList(ThemeInfo).init(allocator);
    defer list.deinit();
    try resources.listThemes(allocator, "./src/themes", &list);

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
        if (thm.token_colors) |tc| {
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

// define a scope by into chunks separated by '.' each identified by a unique number encoded into u10
// combine the chunk ids into one u128
pub const Atom = struct {
    id: u128 = 0,
    count: u8 = 0,

    pub fn fromScopeName(scope: []const u8, map: *std.StringHashMap(u32)) Atom {
        var a = Atom{};
        a.compute(scope, map);
        return a;
    }

    pub fn compute(self: *Atom, scope: []const u8, map: *std.StringHashMap(u32)) void {
        const a = atomize(scope, map);
        self.id = a.id;
        self.count = a.count;
    }

    pub fn cmp(a: Atom, b: Atom) u8 {
        return atomsCmp(a, b);
    }
};

// This converts a scope entity.name.function.c into a u128 atom (with section having its u10 id)
// IDs are given by map which is generated and provide by the Theme.
// Anything not in the map will just be dropped.
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

            // u128 -- so only a max of 11 chunks here + 1 more trailing
            // if (atom.count == (128 / BITS_PER_ATOM) - 1) break;
            if (atom.count == 11) break;

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

// TODO this comparison still misses comparing the front bits of A with the last bits of B
pub fn atomsCmp(a_: Atom, b_: Atom) u8 {
    const a = if (a_.count > b_.count) a_ else b_;
    const b = if (a_.count > b_.count) b_ else a_;
    var matches: u8 = 0;
    var shift: u7 = 0;

    // Try all alignments of b against a
    for (0..a.count) |j| {
        const shifted_b = b.id << shift;

        // j - as we're shifting left .. no need to check trailing bits
        for (j..a.count) |i| {
            const mask = masks[i];
            if ((a.id & mask) == (shifted_b & mask)) {
                matches += 1;
                // TODO avoid lazy cheating like below
                // This gives higher value to leading bits or preceeding atoms
                matches += @as(u8, @intCast(i >> 1));
            }
        }

        shift += BITS_PER_ATOM;
    }
    return matches;
}

fn testTheme(allocator: std.mem.Allocator) !void {
    // dracula "meta.function.arguments variable.other.php"
    // everforest-dark "keyword, storage.type"
    // var thm = theme.Theme.init(allocator, "./src/themes/aurora-x.json") catch {
    // var thm = theme.Theme.init(allocator, "./src/themes/vitesse-dark.json") catch {
    // var thm = theme.Theme.init(allocator, "./src/themes/everforest-dark.json") catch {
    var thm = theme.Theme.init(allocator, "./src/themes/monokai.json") catch {
        // var thm = theme.Theme.init(allocator, "./src/themes/dracula.json") catch {
        unreachable;
    };
    defer thm.deinit();

    var map = std.StringHashMap(u32).init(allocator);
    defer map.deinit();

    std.debug.print("----------------\n", .{});
    std.debug.print("{s}\n", .{thm.name});
    std.debug.print("----------------\n", .{});
    if (thm.token_colors) |tc| {
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

    // TODO add an actual check on which token should win
    const scope_inputs = [_][]const u8{
        "entity.name.function.c",
        // "punctuation.section.parameters.begin.bracket.round.c",
        // "meta.function.definition.parameters.c",
        // "punctuation.section.parameters.end.bracket.round.c",
        // "markup.list.unnumbered.markdown",
    };

    for (scope_inputs) |scope_input| {
        std.debug.print("----------------\n", .{});
        std.debug.print("{s}\n", .{scope_input});
        const sa = atomize(scope_input, &map);
        if (thm.token_colors) |tc| {
            for (tc) |tokenColor| {
                if (tokenColor.scope) |sc| {
                    for (sc) |scope_name| {
                        // TODO Handle ',' separated for grouped tokens
                        if (std.mem.indexOf(u8, scope_name, ",")) |_| continue;
                        // TODO Handle ' ' separated for ascendant handling
                        if (std.mem.indexOf(u8, scope_name, " ")) |_| continue;
                        // TODO Handle '-' separated for exclusions
                        // if (std.mem.indexOf(u8, scope_name, "-")) |_| continue;
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
}
