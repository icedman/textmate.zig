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

/// Set text color from a hex string like "#ffaabb"
fn setColorHex(stdout: anytype, hex: []const u8) !void {
    if (hex.len != 7 or hex[0] != '#') {
        return error.InvalidHexColor;
    }

    const r = try std.fmt.parseInt(u8, hex[1..3], 16);
    const g = try std.fmt.parseInt(u8, hex[3..5], 16);
    const b = try std.fmt.parseInt(u8, hex[5..7], 16);

    // 24-bit ANSI foreground color
    stdout.print("\x1b[38;2;{d};{d};{d}m", .{ r, g, b });
    // stdout.print("[{d};{d};{d}]\n", .{ r, g, b });
}

/// Reset to default color
fn resetColor(stdout: anytype) !void {
    stdout.print("\x1b[0m", .{});
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    try oni.init(&.{oni.Encoding.utf8});
    try oni.testing.ensureInit();

    var thm = try theme.Theme.init(allocator, "data/dracula.json");
    // var thm = try theme.Theme.init(allocator, "data/bluloco.json");
    defer thm.deinit();

    std.debug.print("{s}\n", .{thm.name});
    std.debug.print("colors: {}\n", .{thm.colors.?.count()});

    var gmr = try grammar.Grammar.init(allocator, "data/c.tmLanguage.json");
    defer gmr.deinit();
    std.debug.print("{s}\n", .{gmr.name});

    var par = try parser.Parser.init(allocator, &gmr);
    defer par.deinit();

    const syntax = gmr.syntax orelse {
        return;
    };
    var state = try parser.ParseState.init(allocator, syntax);
    defer state.deinit();

    // var proc = try processor.DumpProcessor.init(allocator);
    var proc = try processor.RenderProcessor.init(allocator);
    defer proc.deinit();
    par.processor = &proc;
    proc.theme = &thm;

    // par.begin();
    // _ = par.parseLine(&state, "int x = 123;\n");
    // _ = try par.parseLine(&state, "int main(int argc, char **argv) {\n");
    // _ = try par.parseLine(&state, "return 0;\n");
    // _ = try par.parseLine(&state, "}\n");

    if (true) { // Open file
        par.begin();
        var args = std.process.args();
        _ = args.next();
        const path = args.next() orelse "./data/test2.c";
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var reader = file.reader();

        // We'll read line-by-line
        var buf: [1024]u8 = undefined;
        var line_no: usize = 1;

        const start = std.time.nanoTimestamp();
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            // Remove trailing \r if present
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
        // std.debug.print("state stack\n", .{});
        // state.dump();

        std.debug.print("execs: {}\n", .{par.regex_execs});
        std.debug.print("skips: {}\n", .{par.regex_skips});
        std.debug.print("done in {d:.6}s\n", .{elapsed});
    }

    std.debug.print("state depth: {}\n", .{state.size()});
    std.debug.print("grammar.syntax: {*}\n", .{gmr.syntax});

    //
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    //
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();

    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // Don't forget to flush!
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("textmate_zig_lib");
