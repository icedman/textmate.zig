//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const oni = lib.oni;
const theme = lib.theme;
const grammar = lib.grammar;
const parser = lib.parser;

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

    var state = try parser.ParseState.init(allocator, &gmr.syntax);
    defer state.deinit();

    par.parseLine(&state, "int main(int argc, char **argv)");

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

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "use other module" {
    try std.testing.expectEqual(@as(i32, 150), lib.add(100, 50));
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("cc_textmate_zig_lib");
