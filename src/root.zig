//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");

pub const oni = @import("oniguruma");
pub const theme = @import("theme.zig");
pub const grammar = @import("grammar.zig");
pub const parser = @import("parser.zig");
pub const processor = @import("processor.zig");

const testing = std.testing;
