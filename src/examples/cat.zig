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
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    stdout.print("Usage: textmate_zig [options] filename\n", .{}) catch {};
    stdout.print(" -s printout stats\n", .{}) catch {};
    stdout.print(" -m html output\n", .{}) catch {};
    stdout.print(" -n null output\n", .{}) catch {};
    stdout.print(" -d dump parsed scopes\n", .{}) catch {};
    stdout.print(" -g <grammar name> provide grammar by name\n", .{}) catch {};
    stdout.print(" -t <theme name> provide theme by name\n", .{}) catch {};
    stdout.print(" -r <path> resources path containing 'themes' and/or 'grammars' folder\n", .{}) catch {};
    stdout.print(" -l list avaiable themes and grammars\n", .{}) catch {};
    stdout.flush() catch {};
}

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = switch (builtin.mode) {
        .Debug => gpa.allocator(),
        else => std.heap.page_allocator,
    };

    // const allocator = std.heap.page_allocator;

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
    var resources_path: ?[]const u8 = null;

    var args = std.process.args();
    var arg = args.next(); // skips the executable name
    while (arg != null) {
        arg = args.next();
        if (arg == null) break;
        if (std.mem.eql(u8, arg.?, "-s")) {
            stats = true;
        } else if (std.mem.eql(u8, arg.?, "-r")) {
            resources_path = args.next();
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
        if (resources_path) |rp| {
            const themes_path = try std.fs.path.join(allocator, &.{ rp, "themes" });
            thl.addThemes(themes_path) catch {
                std.debug.print("unable to add themes directory\n", .{});
            };
        }
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
        if (resources_path) |rp| {
            const grammars_path = try std.fs.path.join(allocator, &.{ rp, "grammars" });
            gml.addGrammars(grammars_path) catch {
                std.debug.print("unable to add grammars directory\n", .{});
            };
        }
        if (list) {
            var injectors: usize = 0;
            for (gml.grammars.items) |item| {
                if (item.inject_only) {
                    injectors += 1;
                }
            }
            std.debug.print("\nGrammars ({}):\n", .{gml.grammars.items.len - injectors});
            for (gml.grammars.items, 0..) |item, i| {
                if (item.inject_only) {
                    continue;
                }
                std.debug.print("{s}({s}) ", .{item.name, item.scope_name});
                if ((i + 1) % 8 == 0) std.debug.print("\n", .{});
            }
        }
    }

    if (list) {
        return;
    }

    if (file_path == null) {
        printUsage();
        return;
    }

    var thm: *Theme = undefined;
    if (ThemeLibrary.getLibrary()) |thl| {
        if (std.mem.indexOf(u8, theme_path orelse "", ".json")) |_| {
            thm = Theme.init(allocator, theme_path orelse "") catch {
                std.debug.print("unable to open theme file\n", .{});
                return;
            };
            defer thm.deinit();
        } else {
            thm = thl.themeFromName(theme_path orelse "dracula-soft") catch {
                std.debug.print("unable to open theme\n", .{});
                return;
            };
        }
    }
    // let the library deinit library-loaded thee 
    // defer thm.deinit();

    var gmr: *Grammar = undefined;
    if (GrammarLibrary.getLibrary()) |gml| {
        if (grammar_path) |gp| {
            if (std.mem.indexOf(u8, gp, ".json")) |_| {
                gmr = Grammar.init(allocator, gp) catch {
                    std.debug.print("unable to open grammar file\n", .{});
                    return;
                };
                defer gmr.deinit();
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


    // let the library deinit library-loaded grammars 
    // defer gmr.deinit();

    var par = try Parser.init(allocator, gmr);
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
    par.atoms = &thm.atoms;
    proc.theme = thm;

    par.resetStats();
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

    proc.state = &state;

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
        stdout.print("==================\n", .{}) catch {};
        stdout.print("lines: {}\n", .{line_no - 1}) catch {};
        stdout.print("execs: {}\n", .{par.regex_execs}) catch {};
        if (line_no > 0) {
            stdout.print("execs/line: {}\n", .{par.regex_execs / line_no}) catch {};
        }
        stdout.print("skips: {}\n", .{par.regex_skips}) catch {};
        stdout.print("warmup in {d:.6}s\n", .{warm_elapsed}) catch {};
        stdout.print("done in {d:.6}s\n", .{elapsed}) catch {};
        stdout.print("state depth: {}\n", .{state.size()}) catch {};
        // stdout.print("retained: {}\n", .{proc.retained_captures.items.len}) catch {};
        stdout.print("grammar: {s}\n", .{gmr.name}) catch {};
        stdout.print("theme: {s}\n", .{thm.name}) catch {};
        stdout.print("theme atoms: {}\n", .{thm.atoms.count()}) catch {};
        // state.dump();
        stdout.flush() catch {};
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
const builtin = @import("builtin");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("textmate_lib");
