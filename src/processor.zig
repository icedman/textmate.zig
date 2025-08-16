const std = @import("std");
const parser = @import("parser.zig");

pub const Processor = struct {
    allocator: std.mem.Allocator,
    block: ?[]const u8 = null,

    start_line_fn: ?*const fn (*Processor, block: []const u8) void = null,
    end_line_fn: ?*const fn (*Processor) void = null,
    open_tag_fn: ?*const fn (*Processor, *const parser.Match) void = null,
    close_tag_fn: ?*const fn (*Processor, *const parser.Match) void = null,
    capture_fn: ?*const fn (*Processor, parser.Capture) void = null,

    pub fn startLine(self: *Processor, block: []const u8) void {
        self.block = block;
        if (self.start_line_fn) |f| {
            f(self, block);
        }
    }

    pub fn endLine(self: *Processor) void {
        if (self.end_line_fn) |f| {
            f(self);
        }
    }

    pub fn openTag(self: *Processor, match: *const parser.Match) void {
        if (self.open_tag_fn) |f| {
            f(self, match);
        }
    }

    pub fn closeTag(self: *Processor, match: *const parser.Match) void {
        if (self.close_tag_fn) |f| {
            f(self, match);
        }
    }

    pub fn capture(self: *Processor, cap: parser.Capture) void {
        if (self.capture_fn) |f| {
            f(self, cap);
        }
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
        };
    }
};
