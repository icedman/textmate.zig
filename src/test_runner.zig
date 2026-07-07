const oni = lib.oni;

const Regex = lib.Regex;
const Theme = lib.Theme;
const ThemeLibrary = lib.ThemeLibrary;
const Grammar = lib.Grammar;
const GrammarLibrary = lib.GrammarLibrary;
const Parser = lib.Parser;
const ParseState = lib.ParseState;
const NullProcessor = lib.NullProcessor;
const DumpProcessor = lib.DumpProcessor;
const RenderProcessor = lib.RenderProcessor;
const TestProcessor = NullProcessor;
const Rgb = lib.Rgb;
const util = lib.AnsiTerminal;

const ArrayList = std.ArrayList;

const setColorHex = util.setColorHex;
const setColorRgb = util.setColorRgb;
const setBgColorHex = util.setBgColorHex;
const setBgColorRgb = util.setBgColorRgb;
const resetColor = util.resetColor;

var line_tests: usize = 0;
var line_tests_passed: usize = 0;
var line_tests_failed: usize = 0;

var end_on_fail = false;

fn compare_tokens(hay: *ArrayList([]const u8), needles: std.json.Value) bool {
    var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);
    var eq = true;
    for (needles.array.items) |n| {
        const ns = n.string;
        var found = false;
        for (hay.items) |h| {
            if (std.mem.eql(u8, h, ns)) {
                found = true;
                break;
            }
        }
        if (!found) {
            eq = false;
            setColorRgb(stdout, Rgb{ .r = 50, .g = 150, .b = 150, .a = 255 }) catch {};
            stdout.print("!missing {s}\n", .{ns}) catch {};
            resetColor(stdout) catch {};
        }
    }
    stdout.flush() catch {};
    return eq;
}

pub fn run_parse_test(allocator: std.mem.Allocator, json: std.json.Value, base_path: []const u8) !bool {
    var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);
    var buf: [1024]u8 = undefined; // fixed buffer
    GrammarLibrary.initLibrary(allocator) catch {
        return false;
    };
    defer GrammarLibrary.deinitLibrary();

    if (GrammarLibrary.getLibrary()) |gml| {
        const grammars = json.object.get("grammars");
        if (grammars) |gmrs| {
            if (gmrs == .array) {
                for (gmrs.array.items) |g| {
                    const s = try std.fmt.bufPrint(&buf, "{s}/{s}", .{ base_path, g.string });
                    _ = gml.addGrammar(s) catch {
                        // skip test if grammars can't be loaded (plists)
                        return false;
                    };
                }
            }
        }
    }

    const grammar_path = json.object.get("grammarPath");
    var gmr: ?*Grammar = null;
    if (grammar_path) |p| {
        if (p == .string) {
            const s = try std.fmt.bufPrint(&buf, "{s}/{s}", .{ base_path, p.string });
            // if (std.mem.indexOf(u8, s, "json")) |_| {
            //     // we support only json files
            // } else {
            //     try stdout.print("unsupported file {s}\n", .{s});
            //     return error.UnsupportedFile;
            // }
            try stdout.print("{s}\n", .{s});
            gmr = try Grammar.init(allocator, s);
            // gmr.syntax.?.dump(0, false);
        }
    }

    if (gmr) |grammar| {
        defer grammar.deinit();

        const desc = json.object.get("desc");
        if (desc) |d| {
            stdout.print("===========\n{s}\n===========\n", .{d.string}) catch {};
        }

        var par = try Parser.init(allocator, grammar);
        defer par.deinit();

        var state = try par.initState();
        defer state.deinit();

        var proc = try TestProcessor.init(allocator);
        defer proc.deinit();

        par.processor = &proc;
        proc.state = &state;

        var collect = try ArrayList([]const u8).initCapacity(allocator, 32);
        defer collect.deinit(allocator);

        var lineSlice = try ArrayList(u8).initCapacity(allocator, 512);
        defer lineSlice.deinit(allocator);

        const lines = json.object.get("lines");
        if (lines) |ll| {
            if (ll == .array) {
                proc.startDocument();
                var first_line = true;
                for (ll.array.items) |l| {
                    collect.clearRetainingCapacity();

                    const line = l.object.get("line").?.string;
                    lineSlice.clearRetainingCapacity();
                    try lineSlice.appendSlice(allocator, line);
                    try lineSlice.appendSlice(allocator, "\n");
                    _ = try par.parseLine(&state, lineSlice.items, first_line);
                    first_line = false;
                    try stdout.print("Line: {s} {}\n", .{ line, line.len });
                    proc.dump();

                    const tokens = l.object.get("tokens").?.array;
                    var idx: usize = 0;
                    var passed = true;
                    for (tokens.items) |t| {
                        const value = t.object.get("value").?.string;
                        const scopes = t.object.get("scopes");
                        const s = idx;
                        const e = s + value.len;
                        try stdout.print("[{s}]\n", .{value});
                        try stdout.print(" ?: {f}\n", .{std.json.fmt(scopes, .{})});
                        try proc.query(s, e, allocator, &collect);
                        if (!compare_tokens(&collect, scopes.?)) {
                            passed = false;
                        }
                        idx = e;
                    }

                    line_tests += 1;
                    if (!passed) {
                        try setColorRgb(stdout, Rgb{ .r = 255, .g = 50, .b = 50, .a = 255 });
                        try stdout.print("line test failed\n", .{});
                        try resetColor(stdout);
                        line_tests_failed += 1;
                        if (end_on_fail) {
                            return false;
                        }
                    } else {
                        try setColorRgb(stdout, Rgb{ .r = 50, .g = 255, .b = 50, .a = 255 });
                        try stdout.print("line test passed\n", .{});
                        try resetColor(stdout);
                        line_tests_passed += 1;
                    }
                }
                proc.endDocument();
            }
        }
    }

    stdout.flush() catch {};

    return true;
}

pub fn run_test_suit(allocator: std.mem.Allocator, base_path: []const u8, source_path: []const u8) !bool {
    var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);
    var buf: [1024]u8 = undefined; // fixed buffer
    const file_path = try std.fmt.bufPrint(&buf, "{s}/{s}", .{ base_path, source_path });

    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    // const file_size = (try file.stat()).size;
    // const file_contents = try file.readToEndAlloc(allocator, file_size);
    const file_contents = try std.fs.cwd().readFileAlloc(file_path, allocator, .limited(1 << 30));
    defer allocator.free(file_contents);

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, file_contents, .{ .ignore_unknown_fields = true });
    defer parsed.deinit();
    const root = parsed.value;

    if (root == .array) {
        for (root.array.items) |item| {
            if (item == .object) {
                // if (item.object.get("skip")) |_| {
                //     std.debug.print("skipping...{s}\n", .{item.object.get("desc").?.string});
                //     continue;
                // }
                const res = run_parse_test(allocator, item, base_path) catch {
                    std.debug.print("unable to finish test\n", .{});
                    if (end_on_fail) {
                        return false;
                    }
                    return true;
                };
                if (res == false and end_on_fail) {
                    return false;
                }
            }
        }
    }

    stdout.flush() catch {};
    return true;
}

pub fn run_theme_library(allocator: std.mem.Allocator) !void {
    var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);
    ThemeLibrary.initLibrary(allocator) catch {
        return;
    };
    defer ThemeLibrary.deinitLibrary();
    if (ThemeLibrary.getLibrary()) |thl| {
        thl.addEmbeddedThemes() catch {};
        for (thl.themes.items) |thm| {
            try stdout.print("theme: {s}\n", .{thm.name});
            if (thm.embedded_file) |f| {
                var t = try Theme.initWithData(allocator, f);
                try stdout.print("..{s}\n", .{t.name});
                defer t.deinit();
            }
        }
    }

    stdout.flush() catch {};
}

pub fn run_grammar_library(allocator: std.mem.Allocator) !void {
    var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);
    GrammarLibrary.initLibrary(allocator) catch {
        return;
    };
    defer GrammarLibrary.deinitLibrary();
    if (GrammarLibrary.getLibrary()) |gml| {
        gml.addEmbeddedGrammars() catch {};
        for (gml.grammars.items) |gmr| {
            try stdout.print("grammar: {s}\n", .{gmr.scope_name});
            if (gmr.embedded_file) |f| {
                var t = Grammar.initWithData(allocator, f) catch |err| {
                    try stdout.print("!{any}\n", .{err});
                    continue;
                };
                defer t.deinit();
                if (t.syntax) |s| {
                    try stdout.print("..{s}\n", .{s.getName()});
                }
            }
        }
    }

    stdout.flush() catch {};
}

pub fn main() !void {
    var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var args = std.process.args();
    _ = args.next(); // skip binary name
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--end-on-fail") or std.mem.eql(u8, arg, "-e")) {
            end_on_fail = true;
        }
    }

    if (try run_test_suit(allocator, "data/test-cases/first-mate", "tests.json")) {
        if (try run_test_suit(allocator, "data/test-cases/suite1", "tests.json")) {
            _ = try run_test_suit(allocator, "data/test-cases/suite1", "whileTests.json");
        }
    }
    // try run_theme_library(allocator);
    // try run_grammar_library(allocator);

    stdout.print("\n==================\n", .{}) catch {};
    stdout.print("line tests: {}/{}\n", .{ line_tests_passed, line_tests }) catch {};
}

const std = @import("std");
const lib = @import("textmate_lib");
