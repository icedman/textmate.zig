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
const RenderHtmlProcessor = lib.RenderHtmlProcessor;

pub fn run_parse_test(allocator: std.mem.Allocator, json: std.json.Value, base_path: []const u8) !void {
    var buf: [1024]u8 = undefined; // fixed buffer
    const grammar_path = json.object.get("grammarPath");
    var gmr: ?*Grammar = null;
    if (grammar_path) |p| {
        if (p == .string) {
            const s = try std.fmt.bufPrint(&buf, "{s}/{s}", .{ base_path, p.string });
            if (std.mem.indexOf(u8, s, "json")) |_| {
                // we support only json files
            } else {
                std.debug.print("unsupported file {s}\n", .{s});
                return error.UnsupportedFile;
            }
            std.debug.print("{s}\n", .{s});
            gmr = try Grammar.init(allocator, s);
            // gmr.syntax.?.dump(0, false);
        }
    }

    if (gmr) |grammar| {
        defer grammar.deinit();

        var par = try Parser.init(allocator, grammar);
        defer par.deinit();

        var state = try par.initState();
        defer state.deinit();

        var proc = try NullProcessor.init(allocator);
        defer proc.deinit();

        par.processor = &proc;
        proc.state = &state;

        const lines = json.object.get("lines");
        if (lines) |ll| {
            if (ll == .array) {
                proc.startDocument();
                for (ll.array.items) |l| {
                    const line = l.object.get("line").?.string;
                    _ = try par.parseLine(&state, line);
                    std.debug.print("Line: {s}\n", .{line});

                    const tokens = l.object.get("tokens").?.array;
                    var idx: usize = 0;
                    for (tokens.items) |t| {
                        const value = t.object.get("value").?.string;
                        const scopes = t.object.get("scopes");
                        const s = idx;
                        const e = s + value.len;
                        std.debug.print("[{s}]\n", .{value});
                        std.debug.print(" ?: {f}\n", .{std.json.fmt(scopes, .{})});
                        proc.query(s, e);
                        idx = e;
                    }
                }
                proc.endDocument();
            }
        }
    }
}

pub fn run_test_suit(allocator: std.mem.Allocator, base_path: []const u8, source_path: []const u8) !void {
    var buf: [1024]u8 = undefined; // fixed buffer
    const file_path = try std.fmt.bufPrint(&buf, "{s}/{s}", .{ base_path, source_path });

    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    const file_size = (try file.stat()).size;
    const file_contents = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(file_contents);

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, file_contents, .{ .ignore_unknown_fields = true });
    defer parsed.deinit();
    const root = parsed.value;

    if (root == .array) {
        for (root.array.items) |item| {
            if (item == .object) {
                run_parse_test(allocator, item, base_path) catch {};
                // break;
            }
        }
    }
}

pub fn run_theme_library(allocator: std.mem.Allocator) !void {
    ThemeLibrary.initLibrary(allocator) catch {
        return;
    };
    defer ThemeLibrary.deinitLibrary();
    if (ThemeLibrary.getLibrary()) |thl| {
        thl.addEmbeddedThemes() catch {};
        for (thl.themes.items) |thm| {
            std.debug.print("theme: {s}\n", .{thm.name});
            if (thm.embedded_file) |f| {
                var t = try Theme.initWithData(allocator, f);
                std.debug.print("..{s}\n", .{t.name});
                defer t.deinit();
            }
        }
    }
}

pub fn run_grammar_library(allocator: std.mem.Allocator) !void {
    GrammarLibrary.initLibrary(allocator) catch {
        return;
    };
    defer GrammarLibrary.deinitLibrary();
    if (GrammarLibrary.getLibrary()) |gml| {
        gml.addEmbeddedGrammars() catch {};
        for (gml.grammars.items) |gmr| {
            std.debug.print("grammar: {s}\n", .{gmr.scope_name});
            if (gmr.embedded_file) |f| {
                var t = Grammar.initWithData(allocator, f) catch |err| {
                    std.debug.print("!{any}\n", .{err});
                    continue;
                };
                defer t.deinit();
                if (t.syntax) |s| {
                    std.debug.print("..{s}\n", .{s.getName()});
                }
            }
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    try run_test_suit(allocator, "data/test-cases/first-mate", "tests.json");
    try run_test_suit(allocator, "data/test-cases/suite1", "tests.json");
    // try run_theme_library(allocator);
    // try run_grammar_library(allocator);
}

const std = @import("std");
const lib = @import("textmate_lib");
