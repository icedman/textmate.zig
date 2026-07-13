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

// dump leaks
const TEST_WITH_GPA = true;

fn printUsage() void {
    std.debug.print("Usage: textmate_zig [options] filename\n", .{});
    std.debug.print(" -s printout stats\n", .{});
    std.debug.print(" -m html output\n", .{});
    std.debug.print(" -n null output\n", .{});
    std.debug.print(" -d dump parsed scopes\n", .{});
    std.debug.print(" -g <grammar name> provide grammar by name\n", .{});
    std.debug.print(" -t <theme name> provide theme by name\n", .{});
    std.debug.print(" -r <path> resources path containing 'themes' and/or 'grammars' folder\n", .{});
    std.debug.print(" -G list avaiable grammars\n", .{});
    std.debug.print(" -T list avaiable themes\n", .{});
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_buffer: [2048]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const allocator = if (TEST_WITH_GPA and builtin.mode == .Debug) init.gpa else std.heap.page_allocator;

    try oni.init(&.{oni.Encoding.utf8});
    try oni.testing.ensureInit();

    var dump: bool = false;
    var nllu: bool = false;
    var html: bool = false;
    var list_grammars: bool = false;
    var list_themes: bool = false;
    var stats: bool = false;
    var grammar_path: ?[]const u8 = null;
    var theme_path: ?[]const u8 = null;
    var file_path: ?[]const u8 = null;
    var resources_path: ?[]const u8 = null;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
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
        } else if (std.mem.eql(u8, arg.?, "-G")) {
            list_grammars = true;
        } else if (std.mem.eql(u8, arg.?, "-T")) {
            list_themes = true;
        } else if (std.mem.eql(u8, arg.?, "-h")) {
            printUsage();
            return;
        } else {
            file_path = arg;
        }
    }

    const warm_start = std.Io.Timestamp.now(io, .awake);

    ThemeLibrary.initLibrary(io, allocator) catch {
        return;
    };
    defer ThemeLibrary.deinitLibrary();
    if (ThemeLibrary.getLibrary()) |thl| {
        thl.addEmbeddedThemes() catch {
            std.debug.print("unable to add embedded themes\n", .{});
        };
        if (resources_path) |rp| {
            const themes_path = try std.Io.Dir.path.join(allocator, &.{ rp, "themes" });
            thl.addThemes(themes_path) catch {
                std.debug.print("unable to add themes directory\n", .{});
            };
        }
        if (list_themes) {
            std.debug.print("\nThemes ({}):\n", .{thl.themes.items.len});
            for (thl.themes.items, 0..) |item, i| {
                std.debug.print("{s}  ", .{item.name});
                if ((i + 1) % 8 == 0) std.debug.print("\n", .{});
            }
            std.debug.print("\n", .{});
        }
    }

    GrammarLibrary.initLibrary(io, allocator) catch {
        return;
    };
    defer GrammarLibrary.deinitLibrary();
    if (GrammarLibrary.getLibrary()) |gml| {
        gml.addEmbeddedGrammars() catch {
            std.debug.print("unable to add embedded grammars\n", .{});
        };
        if (resources_path) |rp| {
            const grammars_path = try std.Io.Dir.path.join(allocator, &.{ rp, "grammars" });
            gml.addGrammars(grammars_path) catch {
                std.debug.print("unable to add grammars directory\n", .{});
            };
        }
        if (list_grammars) {
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
                std.debug.print("{s}({s}) ", .{ item.name, item.scope_name });
                if ((i + 1) % 8 == 0) std.debug.print("\n", .{});
            }
        }
    }

    if (list_grammars or list_themes) {
        return;
    }

    if (file_path == null) {
        printUsage();
        return;
    }

    var thm: *Theme = undefined;
    if (ThemeLibrary.getLibrary()) |thl| {
        if (std.mem.indexOf(u8, theme_path orelse "", ".json")) |_| {
            const ti = try thl.addTheme(theme_path orelse "");
            thm = thl.themeFromId(ti.id) catch {
                std.debug.print("unable to open theme\n", .{});
                return;
            };
        } else {
            thm = thl.themeFromName(theme_path orelse "dracula-soft") catch {
                std.debug.print("unable to open theme\n", .{});
                return;
            };
        }
    }

    var gmr: *Grammar = undefined;
    if (GrammarLibrary.getLibrary()) |gml| {
        if (grammar_path) |gp| {
            if (std.mem.indexOf(u8, gp, ".json")) |_| {
                const gi = try gml.addGrammar(gp);
                gmr = gml.grammarFromId(gi.id) catch {
                    std.debug.print("unable to open grammar {s}\n", .{gp});
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

    var par = try Parser.init(allocator, gmr);
    defer par.deinit();

    var state = try par.initState();
    defer state.deinit();

    var proc = blk: {
        if (dump) {
            break :blk try DumpProcessor.init(io, allocator);
        } else if (nllu) {
            break :blk try NullProcessor.init(io, allocator);
        } else if (html) {
            break :blk try RenderHtmlProcessor.init(io, allocator);
        } else {
            break :blk try RenderProcessor.init(io, allocator);
        }
    };

    defer proc.deinit();
    par.processor = &proc;
    par.atoms = &thm.atoms;
    proc.theme = thm;

    par.resetStats();
    const path = file_path orelse "";
    var file = std.Io.Dir.cwd().openFile(io, path, .{}) catch {
        std.debug.print("unable to open file {s}\n", .{file_path orelse ""});
        return;
    };
    defer file.close(io);

    var buf: [1024]u8 = undefined;
    var line_no: usize = 1;
    var reader = file.reader(io, &buf);

    const warm_end = std.Io.Timestamp.now(io, .awake);
    const warm_elapsed = @as(f64, @floatFromInt(warm_start.durationTo(warm_end).nanoseconds)) / 1_000_000_000.0;

    const start = std.Io.Timestamp.now(io, .awake);
    proc.startDocument();

    var line_writer = std.Io.Writer.Allocating.init(allocator);
    defer line_writer.deinit();

    proc.state = &state;

    var first_line = true;
    while (reader.interface.streamDelimiter(&line_writer.writer, '\n')) |_| {
        try line_writer.writer.print("\n", .{});
        const slice: []u8 = line_writer.written();
        line_writer.clearRetainingCapacity();
        _ = try par.parseLine(&state, slice, first_line);
        first_line = false;
        line_no += 1;
        reader.interface.toss(1);
        // if (line_no > 30) break;
        // const spans = try proc.produce();
        // for (spans.items) |span| {
        //     std.debug.print("{s}", .{span.text});
        //     if (span.text.len == 1 and span.text[0] == ' ') {
        //         continue;
        //     }
        //     std.debug.print("(", .{});
        //     for (0..span.count) |idx| {
        //         const atom = span.atoms[idx];
        //         const scope = span.scopes[idx];
        //         if (idx > 0) {
        //             std.debug.print(" ", .{});
        //         }
        //         std.debug.print("{s}[{}]", .{scope, atom.count});
        //     }
        //     std.debug.print(") ", .{});
        // }
        // std.debug.print("\n", .{});
    } else |err| if (err != error.EndOfStream) return err;

    proc.endDocument();
    const end = std.Io.Timestamp.now(io, .awake);
    const elapsed = @as(f64, @floatFromInt(start.durationTo(end).nanoseconds)) / 1_000_000_000.0;

    if (stats) {
        std.debug.print("==================\n", .{});
        std.debug.print("lines: {}\n", .{line_no - 1});
        std.debug.print("execs: {}\n", .{par.regex_execs});
        if (line_no > 0) {
            std.debug.print("execs/line: {}\n", .{par.regex_execs / line_no});
            std.debug.print("patterns/line: {}\n", .{par.total_pats / line_no});
        }
        std.debug.print("skips: {}\n", .{par.regex_skips});
        std.debug.print("compiles: {}\n", .{par.regex_compiles});
        std.debug.print("warmup in {d:.6}s\n", .{warm_elapsed});
        std.debug.print("done in {d:.6}s\n", .{elapsed});
        std.debug.print("lines/sec: {}\n", .{@as(usize, @intFromFloat(@as(f64, @floatFromInt(line_no)) / elapsed))});
        std.debug.print("state depth: {}\n", .{state.size()});
        std.debug.print("max state depth: {}\n", .{par.deepest});
        std.debug.print("max processor depth: {}\n", .{proc.deepest});
        // std.debug.print("retained: {}\n", .{proc.retained_captures.items.len});
        std.debug.print("grammar: {s}\n", .{gmr.name});
        std.debug.print("theme: {s}\n", .{thm.name});
        std.debug.print("theme atoms: {}\n", .{thm.atoms.count()});
        std.debug.print("-----\n", .{});
        // state.dump();
        // proc.dump();
    }

    stdout.flush() catch {};
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
