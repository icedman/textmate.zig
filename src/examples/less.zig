const oni = lib.oni;
const Regex = lib.Regex;

pub fn main() !void {
    std.debug.print("implement me\n", .{});

    const expr = "(^|\\G)(|\\s{0,3})(```)\\s*$";
    std.debug.print("compiling...{s}\n", .{expr});
    var r = Regex{};
    try r.compile(expr);
    std.debug.print("id: {}\n", .{r.id});
    const block = "```\n";
    if (r.regex) |*re| {
        std.debug.print("matching...\n", .{});
        var result: oni.Region = .{};
        _ = @constCast(re).searchAdvanced(block, 0, 4, &result, .{}) catch |err| {
            if (err == error.Mismatch) {
                std.debug.print("no match!\n", .{});
            }
        };
        std.debug.print("we have a match {}\n", .{result.count()});
    } else {
        std.debug.print("no regex compiled!\n", .{});
    }
}

const std = @import("std");
const lib = @import("textmate_lib");
