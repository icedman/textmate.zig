const oni = lib.oni;
const Rule = lib.Rule;
const Grammar = lib.Grammar;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    std.debug.print("implement me\n", .{});

    // const expr = "(^|\\G)(|\\s{0,3})(```)\\s*$";
    const expr = "(\\[)((?<square>[^]\\[\\\\]|\\\\.|\\[\\g<square>*+])*+)(])(\\()[\\t ]*((<)((?:\\\\[<>]|[^\\n<>])*)(>)|((?<url>(?>[^()\\s]+)|\\(\\g<url>*\\))*))[\\t ]*(?:((\\()[^()]*(\\)))|((\")[^\"]*(\"))|((')[^']*(')))?\\s*(\\))";

    std.debug.print("compiling...{s}\n", .{expr});
    var r = Rule{};
    try r.compile(expr);
    std.debug.print("id: {}\n", .{r.id});
    // const block = "```\n";
    const block = "[title](https://www.example.com)";
    if (r.regex) |*re| {
        std.debug.print("matching...\n", .{});
        var result: oni.Region = .{};
        _ = @constCast(re).searchAdvanced(block, 0, 4, &result, .{}) catch |err| {
            if (err == error.Mismatch) {
                std.debug.print("no match!\n", .{});
            }
        };
        std.debug.print("we have a match {}\n", .{result.count()});
        const cnt = result.count();
        const starts = result.starts();
        const ends = result.ends();
        for (0..cnt) |i| {
            std.debug.print("{}?\n", .{starts[i]});
            if (starts[i] < 0) continue;
            const s: usize = @intCast(starts[i]);
            const e: usize = @intCast(ends[i]);
            std.debug.print("{}-{} {s}\n", .{ s, e, block[s..e] });
        }
    } else {
        std.debug.print("no regex compiled!\n", .{});
    }

    const g = try Grammar.init(allocator, "./src/resources/grammars/markdown.json");
    defer g.deinit();
}

const std = @import("std");
const lib = @import("textmate_lib");
