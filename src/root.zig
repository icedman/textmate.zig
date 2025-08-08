//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");

pub const oni = @import("oniguruma");
pub const theme = @import("theme.zig");
pub const grammar = @import("grammar.zig");
pub const parser = @import("parser.zig");

const testing = std.testing;

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

test "oniguruma" {
    const block = "xx mrv snchz mrv";
    const regex = "mrv";
    var re = try oni.Regex.init(
        regex,
        .{},
        oni.Encoding.utf8,
        oni.Syntax.default,
        null,
    );
    defer re.deinit();
    const reg = blk: {
        const result = re.search(block, .{}) catch |err| {
            if (err == error.Mismatch) {
                // std.debug.print("no match\n", .{});
                break :blk null; // return null instead
            } else {
                return;
            }
        };
        break :blk result;
    };
    if (reg) |r| {
        std.debug.print("found!<<<<<<<<<<<<<<<<<<<\n", .{});
        std.debug.print("count: {d}\n", .{r.count()});
        std.debug.print("starts: {d}\n", .{r.starts()});
        std.debug.print("ends: {d}\n", .{r.ends()});
    }
}
