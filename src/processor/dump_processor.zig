const std = @import("std");
const processor = @import("processor.zig");
const Processor = processor.Processor;
const parser = @import("../parser.zig");
const grammar = @import("../grammar.zig");
const theme = @import("../theme.zig");
const util = @import("../util.zig");
const atms = @import("../atoms.zig");

const Allocator = std.mem.Allocator;

const setColorHex = util.setColorHex;
const setColorRgb = util.setColorRgb;
const setBgColorHex = util.setBgColorHex;
const setBgColorRgb = util.setBgColorRgb;
const resetColor = util.resetColor;

const ParseCapture = parser.ParseCapture;
const ParseState = parser.ParseState;
const Syntax = grammar.Syntax;
const Atom = atms.Atom;
const Rgb = theme.Rgb;

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

    pub fn openTag(self: *Processor, cap: *ParseCapture) void {
        if (self.block) |b| {
            const text = b[cap.start..cap.end];
            std.debug.print("open: {s} {}-{} {s}\n", .{ text, cap.start, cap.end, cap.scope });
        }
    }

    pub fn closeTag(self: *Processor, cap: *ParseCapture) void {
        if (self.block) |b| {
            const text = b[cap.start..cap.end];
            std.debug.print("close: {s} {}-{} {s}\n", .{ text, cap.start, cap.end, cap.scope });
        }
    }

    pub fn capture(self: *Processor, cap: *ParseCapture) void {
        if (self.block) |b| {
            if (cap.start >= b.len) return;
            const text = b[cap.start..cap.end];
            std.debug.print("capture: {s} {}-{} {s}\n", .{ text, cap.start, cap.end, cap.scope });
        }
    }

    pub fn init(allocator: Allocator) !Processor {
        const self = DumpProcessor;
        return Processor{
            .allocator = allocator,
            .start_line_fn = self.startLine,
            .end_line_fn = self.endLine,
            .open_tag_fn = self.openTag,
            .close_tag_fn = self.closeTag,
            .capture_fn = self.capture,
            .captures = try std.ArrayList(ParseCapture).initCapacity(allocator, 32),
        };
    }
};
