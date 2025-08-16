//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const oni = lib.oni;
const theme = lib.theme;
const grammar = lib.grammar;
const parser = lib.parser;
const processor = lib.processor;

fn isBracketOrPunctuation(ch: u8) bool {
    return ch == '(' or ch == ')' or
        ch == '{' or ch == '}' or
        ch == '[' or ch == ']' or
        ch == ',' or ch == '.';
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    try oni.init(&.{oni.Encoding.utf8});
    try oni.testing.ensureInit();

    var dump: bool = false;
    var grammar_path: ?[]const u8 = null;
    var theme_path: ?[]const u8 = null;
    var file_path: ?[]const u8 = null;

    var args = std.process.args();
    var arg = args.next(); // skips the executable name
    while (arg != null) {
        arg = args.next();
        if (arg == null) break;
        if (std.mem.eql(u8, arg.?, "-d")) {
            dump = true;
        } else if (std.mem.eql(u8, arg.?, "-g")) {
            grammar_path = args.next();
        } else if (std.mem.eql(u8, arg.?, "-t")) {
            theme_path = args.next();
        } else {
            file_path = arg;
        }
    }

    var thm = try theme.Theme.init(allocator, theme_path orelse "data/dracula.json");
    defer thm.deinit();

    var gmr = try grammar.Grammar.init(allocator, grammar_path orelse "data/zig.tmLanguage.json");
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
        } else {
            break :blk try processor.RenderProcessor.init(allocator);
        }
    };

    defer proc.deinit();
    par.processor = &proc;
    proc.theme = &thm;

    par.begin();
    const path = file_path orelse "./src/grammar.zig";
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var reader = file.reader();

    var buf: [1024]u8 = undefined;
    var line_no: usize = 1;

    const start = std.time.nanoTimestamp();
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const trimmed = if (line.len > 0 and line[line.len - 1] == '\r')
            line[0 .. line.len - 1]
        else
            line;

        _ = try par.parseLine(&state, trimmed);
        line_no += 1;
    }
    const end = std.time.nanoTimestamp();
    const elapsed = @as(f64, @floatFromInt(end - start)) / 1_000_000_000.0;

    std.debug.print("==================\n", .{});
    // state.dump();
    std.debug.print("execs: {}\n", .{par.regex_execs});
    std.debug.print("skips: {}\n", .{par.regex_skips});
    std.debug.print("done in {d:.6}s\n", .{elapsed});
    std.debug.print("state depth: {}\n", .{state.size()});
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("textmate_zig_lib");
