//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const oni = lib.oni;
const theme = lib.theme;
const grammar = lib.grammar;
const parser = lib.parser;
const processor = lib.processor;

const TEST_VERBOSELY = false;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    try oni.init(&.{oni.Encoding.utf8});
    try oni.testing.ensureInit();

    var dump: bool = false;
    var html: bool = false;
    var stats: bool = false;
    var grammar_path: ?[]const u8 = null;
    var theme_path: ?[]const u8 = null;
    var file_path: ?[]const u8 = null;
    var extra_resources_path: ?[]const u8 = null;

    var args = std.process.args();
    var arg = args.next(); // skips the executable name
    while (arg != null) {
        arg = args.next();
        if (arg == null) break;
        if (std.mem.eql(u8, arg.?, "-s")) {
            stats = true;
        } else if (std.mem.eql(u8, arg.?, "-r")) {
            extra_resources_path = args.next();
        } else if (std.mem.eql(u8, arg.?, "-h")) {
            html = true;
        } else if (std.mem.eql(u8, arg.?, "-d")) {
            dump = true;
        } else if (std.mem.eql(u8, arg.?, "-g")) {
            grammar_path = args.next();
        } else if (std.mem.eql(u8, arg.?, "-t")) {
            theme_path = args.next();
        } else {
            file_path = arg;
        }
    }

    if (file_path == null) {
        std.debug.print("provide a file to parse \n", .{});
        return;
    }

    theme.initThemeLibrary(allocator) catch {
        return;
    };
    defer theme.deinitThemeLibrary();
    if (theme.getThemeLibrary()) |thl| {
        thl.addEmbeddedThemes() catch {
            std.debug.print("unable to add embedded themes\n", .{});
        };
        // for (thl.themes.items) |item| {
        //     std.debug.print("{s}\n", .{item.name});
        // }
        // thl.addThemes("./src/themes") catch {
        //     std.debug.print("unable to add themes directory\n", .{});
        // };
    }

    grammar.initGrammarLibrary(allocator) catch {
        return;
    };
    defer grammar.deinitGrammarLibrary();
    if (grammar.getGrammarLibrary()) |gml| {
        gml.addEmbeddedGrammars() catch {
            std.debug.print("unable to add embedded grammars\n", .{});
        };
        // gml.addGrammars("./src/grammars") catch {
        //     std.debug.print("unable to add grammars directory\n", .{});
        // };
    }

    // var thm = theme.Theme.init(allocator, theme_path orelse "data/tests/dracula.json") catch {
    //     std.debug.print("unable to open theme {s}\n", .{theme_path orelse ""});
    //     return;
    // };
    var thm: theme.Theme = undefined;
    if (theme.getThemeLibrary()) |thl| {
        thm = thl.themeFromName(theme_path orelse "dracula-soft") catch {
            std.debug.print("unable to open theme\n", .{});
            return;
        };
    }
    defer thm.deinit();

    // var gmr = grammar.Grammar.init(allocator, grammar_path orelse "data/tests/zig.tmLanguage.json") catch {
    //     std.debug.print("unable to open grammar {s}\n", .{grammar_path orelse ""});
    //     return;
    // };
    var gmr: grammar.Grammar = undefined;
    if (grammar.getGrammarLibrary()) |gml| {
        if (grammar_path) |gp| {
            gmr = gml.grammarFromScopeName(gp) catch {
                std.debug.print("unable to open grammar from scope name\n", .{});
                return;
            };
        } else {
            gmr = gml.grammarFromExtension(file_path orelse "") catch {
                std.debug.print("unable to open grammar from extension\n", .{});
                return;
            };
        }
    }
    defer gmr.deinit();

    var par = try parser.Parser.init(allocator, &gmr);
    defer par.deinit();

    const syntax = gmr.syntax orelse {
        return;
    };
    var state = try parser.ParseState.init(allocator, syntax);
    defer state.deinit();

    var proc = blk: {
        if (dump) {
            break :blk try processor.DumpProcessor.init(allocator);
            // break :blk try processor.NullProcessor.init(allocator);
        } else if (html) {
            break :blk try processor.RenderHtmlProcessor.init(allocator);
        } else {
            break :blk try processor.RenderProcessor.init(allocator);
        }
    };

    defer proc.deinit();
    par.processor = &proc;
    proc.theme = &thm;

    par.begin();
    const path = file_path orelse "";
    var file = std.fs.cwd().openFile(path, .{}) catch {
        std.debug.print("unable to open file {s}\n", .{file_path orelse ""});
        return;
    };
    defer file.close();

    var reader = file.reader();

    var buf: [1024]u8 = undefined;
    var line_no: usize = 1;

    const start = std.time.nanoTimestamp();
    proc.startDocument();

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var slice = line;

        // Trim trailing \r if present
        if (slice.len > 0 and slice[slice.len - 1] == '\r') {
            slice = slice[0 .. slice.len - 1];
        }

        // Ensure it ends with '\n'
        if (slice.len == 0 or slice[slice.len - 1] != '\n') {
            // safe since readUntilDelimiterOrEof strips the delimiter, leaving room
            slice = buf[0 .. slice.len + 1];
            slice[slice.len - 1] = '\n';
        }

        _ = try par.parseLine(&state, slice);
        line_no += 1;

        // if (line_no > 50000) break;
    }
    proc.endDocument();
    const end = std.time.nanoTimestamp();
    const elapsed = @as(f64, @floatFromInt(end - start)) / 1_000_000_000.0;

    if (stats) {
        std.debug.print("==================\n", .{});
        std.debug.print("lines: {}\n", .{line_no - 1});
        std.debug.print("execs: {}\n", .{par.regex_execs});
        if (line_no > 0) {
            std.debug.print("execs/line: {}\n", .{par.regex_execs / line_no});
        }
        std.debug.print("recompile: {}\n", .{par.regex_compile});
        std.debug.print("skips: {}\n", .{par.regex_skips});
        std.debug.print("done in {d:.6}s\n", .{elapsed});
        std.debug.print("state depth: {}\n", .{state.size()});
        std.debug.print("retained: {}\n", .{proc.retained_captures.items.len});
        std.debug.print("grammar: {s}\n", .{gmr.name});
        std.debug.print("theme: {s}\n", .{thm.name});
        std.debug.print("theme atoms: {}\n", .{thm.atoms.?.count()});
        // state.dump();
    }
}

test "themes" {
    try theme.runTests(std.testing, TEST_VERBOSELY);
}

test "grammar" {
    try grammar.runTests(std.testing, TEST_VERBOSELY);
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("textmate_zig_lib");
