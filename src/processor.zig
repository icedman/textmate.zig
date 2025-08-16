const std = @import("std");
const parser = @import("parser.zig");
const theme = @import("theme.zig");

pub const Processor = struct {
    allocator: std.mem.Allocator,
    block: ?[]const u8 = null,
    theme: ?*theme.Theme = null,

    captures: std.ArrayList(parser.Capture),

    start_line_fn: ?*const fn (*Processor, block: []const u8) void = null,
    end_line_fn: ?*const fn (*Processor) void = null,
    open_tag_fn: ?*const fn (*Processor, *const parser.Match) void = null,
    close_tag_fn: ?*const fn (*Processor, *const parser.Match) void = null,
    capture_fn: ?*const fn (*Processor, parser.Capture) void = null,

    pub fn startLine(self: *Processor, block: []const u8) void {
        self.block = block;
        self.captures.clearRetainingCapacity();
        if (self.start_line_fn) |f| {
            f(self, block);
        }
    }

    pub fn endLine(self: *Processor) void {
        if (self.end_line_fn) |f| {
            f(self);
        }
    }

    // TODO push Capture instead of Match
    pub fn openTag(self: *Processor, match: *const parser.Match) void {
        // TODO add this to captures!
        var end = match.end;
        if (self.block) |b| {
            end = b.len;
        }
        const name = blk: {
            if (match.syntax) |syn| {
                if (syn.content_name.len > 0) {
                    break :blk syn.content_name;
                }
                if (syn.scope_name.len > 0) {
                    break :blk syn.scope_name;
                }
                break :blk syn.name;
            }
            break :blk "";
        };
        var scope_name: [128]u8 = [_]u8{0} ** 128;
        for (0..name.len) |i| {
            scope_name[i] = name[i];
        }

        self.captures.append(parser.Capture{
            .start = match.start,
            .end = end,
            .scope = scope_name,
            .block = true,
        }) catch {};
        if (self.open_tag_fn) |f| {
            f(self, match);
        }
    }

    // close the Capture (properly set the end pos)
    pub fn closeTag(self: *Processor, match: *const parser.Match) void {
        if (self.close_tag_fn) |f| {
            f(self, match);
        }
    }

    pub fn capture(self: *Processor, cap: parser.Capture) void {
        self.captures.append(cap) catch {};
        if (self.capture_fn) |f| {
            f(self, cap);
        }
    }

    pub fn deinit(self: *Processor) void {
        self.captures.deinit();
    }
};

// dump Processor
pub const DumpProcessor = struct {
    pub fn startLine(self: *Processor, block: []const u8) void {
        _ = block;
        std.debug.print("[[==================================\n", .{});
        std.debug.print("{s}\n", .{self.block orelse "?"});
    }

    pub fn endLine(self: *Processor) void {
        _ = self;
        std.debug.print("----------------------------------]]\n\n", .{});
    }

    pub fn openTag(self: *Processor, match: *const parser.Match) void {
        if (self.block) |b| {
            const text = b[match.start..match.end];
            const name = blk: {
                if (match.syntax) |syn| {
                    if (syn.content_name.len > 0) {
                        break :blk syn.content_name;
                    }
                    if (syn.scope_name.len > 0) {
                        break :blk syn.scope_name;
                    }
                    break :blk syn.name;
                }
                break :blk "";
            };
            std.debug.print("open: {s} {}-{} {s}\n", .{ text, match.start, match.end, name });
        }
    }

    pub fn closeTag(self: *Processor, match: *const parser.Match) void {
        if (self.block) |b| {
            const text = b[match.start..match.end];
            const name = blk: {
                if (match.syntax) |syn| {
                    if (syn.content_name.len > 0) {
                        break :blk syn.content_name;
                    }
                    if (syn.scope_name.len > 0) {
                        break :blk syn.scope_name;
                    }
                    break :blk syn.name;
                }
                break :blk "";
            };
            std.debug.print("close: {s} {}-{} {s}\n", .{ text, match.start, match.end, name });
        }
    }

    pub fn capture(self: *Processor, cap: parser.Capture) void {
        if (self.block) |b| {
            const text = b[cap.start..cap.end];
            std.debug.print("capture: {s} {}-{} {s}\n", .{ text, cap.start, cap.end, cap.scope });
        }
    }

    pub fn init(allocator: std.mem.Allocator) !Processor {
        const self = DumpProcessor;
        return Processor{
            .allocator = allocator,
            .start_line_fn = self.startLine,
            .end_line_fn = self.endLine,
            .open_tag_fn = self.openTag,
            .close_tag_fn = self.closeTag,
            .capture_fn = self.capture,
            .captures = std.ArrayList(parser.Capture).init(allocator),
        };
    }
};

const setColorHex = theme.setColorHex;
const resetColor = theme.resetColor;

pub const RenderProcessor = struct {
    pub fn endLine(self: *Processor) void {
        if (self.theme) |thm| {
            const captures = self.captures;
            const block = self.block orelse "";
            for (block, 0..) |ch, i| {
                var cap: parser.Capture = parser.Capture{};
                for (0..captures.items.len) |ci| {
                    if (i >= captures.items[ci].start and i < captures.items[ci].end) {
                        cap = captures.items[ci];
                        // std.debug.print("\n{s} {}-{} [{}]\n", .{ cap.scope, captures.items[ci].start, captures.items[ci].end, i });
                        break;
                    }
                }

                var colors = theme.Settings{};
                const scope = thm.getScope(cap.scope[0..cap.scope.len], &colors);
                _ = scope;
                if (colors.foreground) |fg| {
                    setColorHex(std.debug, fg) catch {};
                    // std.debug.print("{s} fg: {s}\n", .{ cap.scope, fg });
                }

                // _ = ch;
                if (ch == '\t') {
                    std.debug.print("  ", .{});
                } else {
                    std.debug.print("{c}", .{ch});
                }

                if (i + 1 >= cap.end) {
                    resetColor(std.debug) catch {};
                }
            }
            std.debug.print("\n", .{});
        } else {
            std.debug.print("theme is not set\n", .{});
        }
    }

    pub fn init(allocator: std.mem.Allocator) !Processor {
        const self = RenderProcessor;
        return Processor{
            .allocator = allocator,
            .end_line_fn = self.endLine,
            .captures = std.ArrayList(parser.Capture).init(allocator),
        };
    }
};
