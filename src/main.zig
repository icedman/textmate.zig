//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const oni = lib.oni;
const theme = lib.theme;
const grammar = lib.grammar;
const parser = lib.parser;
const utils = lib.utils;

fn dumpSyntax(syntax: *const grammar.Syntax, block: []const u8) !void {
    // std.debug.print("===================\nSyntax\n------------\n", .{});
    // std.debug.print("{s}\n", .{syntax.name});
    if (syntax.regex_match) |*re| {
        // std.debug.print("matching\n", .{});
        const reg = blk: {
            const result = @constCast(re).search(block, .{}) catch |err| {
                if (err == error.Mismatch) {
                    // std.debug.print("no match\n", .{});
                    break :blk null; // return null instead
                } else {
                    return err; // propagate other errors
                }
            };
            break :blk result;
        };

        if (reg) |r| {
            std.debug.print("found!<<<<<<<<<<<<<<<<<<<\n", .{});
            std.debug.print("count: {d}\n", .{r.count()});
            std.debug.print("starts: {d}\n", .{r.starts()});
            std.debug.print("ends: {d}\n", .{r.ends()});
        } else {
            // std.debug.print("no match, continuing\n", .{});
        }
    }
    // std.debug.print("match:{s}\n", .{syntax.regexs_match orelse "(null)"});
    // std.debug.print("begin:{s}\n", .{syntax.regexs_begin orelse "(null)"});
    // std.debug.print("while:{s}\n", .{syntax.regexs_while orelse "(null)"});
    // std.debug.print("end:{s}\n", .{syntax.regexs_end orelse "(null)"});
    // std.debug.print("------------\nSyntax::Patterns\n------------\n", .{});
    if (syntax.patterns) |patterns| {
        for (patterns) |p| {
            const ls = p.lookup(&p);
            if (ls) |s| {
                try dumpSyntax(s, block);
            }
            // if (p.include_path != null) {
            //     std.debug.print("include:{s}\n", .{p.include_path orelse "(null)"});
            //     const ls = p.lookup(&p);
            //     if (ls) |s| {
            //         try dumpSyntax(s, block);
            //     } else {
            //         std.debug.print("include not found:{s}\n", .{p.include_path orelse "(null)"});
            //     }
            // }
            // std.debug.print("{s}\n", .{p.name});
        }
    }
    // std.debug.print("------------\nSyntax::Repository\n------------\n", .{});
    // if (syntax.repository) |map| {
    //     var it = map.iterator();
    //     while (it.next()) |kv| {
    //         // const k = kv.key_ptr.*;
    //         // std.debug.print("{s}\n", .{k});
    //         const v = kv.value_ptr.*;
    //         const syn = v;
    //         try dumpSyntax(&syn, block);
    //     }
    // }
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    try oni.init(&.{oni.Encoding.utf8});
    try oni.testing.ensureInit();

    var thm = try theme.Theme.init(allocator, "data/dracula.json");
    defer thm.deinit();

    std.debug.print("{s}\n", .{thm.name});
    std.debug.print("colors: {}\n", .{thm.colors.?.count()});

    var gmr = try grammar.Grammar.init(allocator, "data/c.tmLanguage.json");
    defer gmr.deinit();
    std.debug.print("{s}\n", .{gmr.name});

    // try dumpSyntax(&gmr.syntax, "int main(int argc, char **argv)");
    // try dumpSyntax(&gmr.syntax, "typedef");

    var par = try parser.Parser.init(allocator, &gmr);
    defer par.deinit();

    var state = try parser.ParseState.init(allocator, gmr.syntax);
    defer state.deinit();

    par.begin();
    //par.parseLine(&state, "int x = 123;\n");
    par.parseLine(&state, "int main(int argc, char **argv) {\n");
    par.parseLine(&state, "return 0;\n");
    par.parseLine(&state, "}\n");

    if (true) { // Open file
        par.begin();
        var args = std.process.args();
        _ = args.next();
        const path = args.next() orelse "./data/test.c";
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

            std.debug.print("{} {s}\n", .{ line_no, trimmed });
            par.parseLine(&state, trimmed);
            line_no += 1;
        }
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f64, @floatFromInt(end - start)) / 1_000_000_000.0;
        std.debug.print("execs: {}\n", .{par.regex_execs});
        std.debug.print("done in {d:.6}s\n", .{elapsed});
    }

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

test "test references" {
    const block: []const u8 = "abcdefg";
    var m = parser.Match{};
    m.count = 2;
    m.captures[0].group = 1;
    m.captures[0].start = 0;
    m.captures[0].end = 2;
    m.captures[1].group = 2;
    m.captures[1].start = 3;
    m.captures[1].end = 5;
    var output: [utils.TEMP_BUFFER_SIZE]u8 = [_]u8{0} ** utils.TEMP_BUFFER_SIZE;
    _ = utils.applyReferences(&m, block, "hello \\1 world \\2.", &output);

    const expectedOutput = "hello ab world de.";
    try std.testing.expectEqualStrings(output[0..expectedOutput.len], expectedOutput);
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("textmate_zig_lib");
