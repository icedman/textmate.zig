//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const oni = lib.oni;

const Theme = lib.Theme;
const ThemeLibrary = lib.ThemeLibrary;
const Grammar = lib.Grammar;
const GrammarLibrary = lib.GrammarLibrary;
const Parser = lib.Parser;
const ParseState = lib.ParseState;
const NullProcessor = lib.NullProcessor;
const DumpProcessor = lib.DumpProcessor;
const RenderProcessor = lib.RenderProcessor;
const RenderHtmlProcessor = lib.RenderHtmlProcessor;

const TEST_VERBOSELY = false;

fn printUsage() void {
    std.debug.print("Usage: textmate_zig [options] filename\n", .{});
    std.debug.print(" -s printout stats\n", .{});
    std.debug.print(" -m html output\n", .{});
    std.debug.print(" -n null output\n", .{});
    std.debug.print(" -d dump parsed scopes\n", .{});
    std.debug.print(" -g <grammar name> provide grammar by name\n", .{});
    std.debug.print(" -t <theme name> provide theme by name\n", .{});
    std.debug.print(" -r <path> resources path containing themes or grammars folder\n", .{});
    std.debug.print(" -l list avaiable themes and grammars\n", .{});
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    try oni.init(&.{oni.Encoding.utf8});
    try oni.testing.ensureInit();

    var dump: bool = false;
    var nllu: bool = false;
    var html: bool = false;
    var list: bool = false;
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
        } else if (std.mem.eql(u8, arg.?, "-m")) {
            html = true;
        } else if (std.mem.eql(u8, arg.?, "-n")) {
            nllu = true;
        } else if (std.mem.eql(u8, arg.?, "-d")) {
            dump = true;
        } else if (std.mem.eql(u8, arg.?, "-g")) {
            grammar_path = args.next();
        } else if (std.mem.eql(u8, arg.?, "-t")) {
            theme_path = args.next();
        } else if (std.mem.eql(u8, arg.?, "-h")) {
            printUsage();
            return;
        } else if (std.mem.eql(u8, arg.?, "-l")) {
            list = true;
        } else {
            file_path = arg;
        }
    }

    const warm_start = std.time.nanoTimestamp();

    ThemeLibrary.initLibrary(allocator) catch {
        return;
    };
    defer ThemeLibrary.deinitLibrary();
    if (ThemeLibrary.getLibrary()) |thl| {
        thl.addEmbeddedThemes() catch {
            std.debug.print("unable to add embedded themes\n", .{});
        };
        // thl.addThemes("./src/themes") catch {
        //     std.debug.print("unable to add themes directory\n", .{});
        // };
        if (list) {
            std.debug.print("\nThemes ({}):\n", .{thl.themes.items.len});
            for (thl.themes.items, 0..) |item, i| {
                std.debug.print("{s}  ", .{item.name});
                if ((i + 1) % 8 == 0) std.debug.print("\n", .{});
            }
            std.debug.print("\n", .{});
        }
    }

    GrammarLibrary.initLibrary(allocator) catch {
        return;
    };
    defer GrammarLibrary.deinitLibrary();
    if (GrammarLibrary.getLibrary()) |gml| {
        gml.addEmbeddedGrammars() catch {
            std.debug.print("unable to add embedded grammars\n", .{});
        };
        // gml.addGrammars("./src/grammars") catch {
        //     std.debug.print("unable to add grammars directory\n", .{});
        // };
        if (list) {
            std.debug.print("\nGrammars ({}):\n", .{gml.grammars.items.len});
            for (gml.grammars.items, 0..) |item, i| {
                std.debug.print("{s}  ", .{item.name});
                if ((i + 1) % 8 == 0) std.debug.print("\n", .{});
            }
            std.debug.print("\n", .{});
        }
    }

    if (list) {
        return;
    }

    if (file_path == null) {
        printUsage();
        return;
    }

    // var thm = Theme.init(allocator, theme_path orelse "data/tests/dracula.json") catch {
    //     std.debug.print("unable to open theme {s}\n", .{theme_path orelse ""});
    //     return;
    // };
    var thm: Theme = undefined;
    if (ThemeLibrary.getLibrary()) |thl| {
        if (std.mem.indexOf(u8, theme_path orelse "", ".json")) |_| {
            thm = Theme.init(allocator, theme_path orelse "") catch {
                std.debug.print("unable to open theme file\n", .{});
                return;
            };
        } else {
            thm = thl.themeFromName(theme_path orelse "dracula-soft") catch {
                std.debug.print("unable to open theme\n", .{});
                return;
            };
        }
    }
    defer thm.deinit();

    // var gmr = Grammar.init(allocator, grammar_path orelse "data/tests/zig.tmLanguage.json") catch {
    //     std.debug.print("unable to open grammar {s}\n", .{grammar_path orelse ""});
    //     return;
    // };
    var gmr: Grammar = undefined;
    if (GrammarLibrary.getLibrary()) |gml| {
        if (grammar_path) |gp| {
            if (std.mem.indexOf(u8, gp, ".json")) |_| {
                gmr = Grammar.init(allocator, gp) catch {
                    std.debug.print("unable to open grammar file\n", .{});
                    return;
                };
            } else {
                gmr = gml.grammarFromScopeName(gp) catch {
                    std.debug.print("unable to open grammar from scope name\n", .{});
                    return;
                };
            }
        } else {
            gmr = gml.grammarFromExtension(file_path orelse "") catch {
                std.debug.print("unable to open grammar from extension\n", .{});
                return;
            };
        }
    }
    defer gmr.deinit();

    var par = try Parser.init(allocator, &gmr);
    defer par.deinit();

    var state = try par.initState();
    defer state.deinit();

    var proc = blk: {
        if (dump) {
            break :blk try DumpProcessor.init(allocator);
        } else if (nllu) {
            break :blk try NullProcessor.init(allocator);
        } else if (html) {
            break :blk try RenderHtmlProcessor.init(allocator);
        } else {
            break :blk try RenderProcessor.init(allocator);
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

    var buf: [1024]u8 = undefined;
    var line_no: usize = 1;
    var reader = file.reader(&buf);

    const warm_end = std.time.nanoTimestamp();
    const warm_elapsed = @as(f64, @floatFromInt(warm_end - warm_start)) / 1_000_000_000.0;

    const start = std.time.nanoTimestamp();
    proc.startDocument();

    var line_writer = std.Io.Writer.Allocating.init(allocator);
    defer line_writer.deinit();

    while (reader.interface.streamDelimiter(&line_writer.writer, '\n')) |_| {
        try line_writer.writer.print("\n", .{});
        const slice: []u8 = line_writer.written();
        line_writer.clearRetainingCapacity();

        _ = try par.parseLine(&state, slice); 
        line_no += 1;
        reader.interface.toss(1);
    } else |err| if (err != error.EndOfStream) return err;

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
        std.debug.print("skips: {}\n", .{par.regex_skips});
        std.debug.print("warmup in {d:.6}s\n", .{warm_elapsed});
        std.debug.print("done in {d:.6}s\n", .{elapsed});
        std.debug.print("state depth: {}\n", .{state.size()});
        std.debug.print("retained: {}\n", .{proc.retained_captures.items.len});
        std.debug.print("grammar: {s}\n", .{gmr.name});
        std.debug.print("theme: {s}\n", .{thm.name});
        std.debug.print("theme atoms: {}\n", .{thm.atoms.count()});
        // state.dump();
    }
}

// TODO make proper tests
// test "grammar" {
//     try grammar.runTests(std.testing, TEST_VERBOSELY);
// }
// TODO make proper tests - test against vscode
// test "parser" {
//     try parser.runTests(std.testing, TEST_VERBOSELY);
// }

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("textmate_lib");
