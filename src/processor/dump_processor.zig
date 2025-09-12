const std = @import("std");
const processor = @import("processor.zig");
const Processor = processor.Processor;
const NullProcessor = processor.NullProcessor;
const parser = @import("../parser.zig");
const grammar = @import("../grammar.zig");
const theme = @import("../theme.zig");
const atms = @import("../atoms.zig");

const Allocator = std.mem.Allocator;

const ParseCapture = parser.ParseCapture;
const ParseState = parser.ParseState;
const Syntax = grammar.Syntax;
const Atom = atms.Atom;
const Rgb = theme.Rgb;

// dump Processor
pub const DumpProcessor = struct {
    pub fn startLine(self: *Processor, block: []const u8) void {
        var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);
        _ = block;
        stdout.print("[[==================================\n", .{}) catch {};
        stdout.print("{s}\n", .{self.block orelse "?"}) catch {};
    }

    pub fn endLine(self: *Processor) void {
        var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);
        _ = self;
        stdout.print("----------------------------------]]\n\n", .{}) catch {};
    }

    pub fn openTag(self: *Processor, cap: *ParseCapture) void {
        var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);
        if (self.block) |b| {
            const text = b[cap.start..cap.end];
            stdout.print("open: {s} {}-{} {s}\n", .{ text, cap.start, cap.end, cap.scope }) catch {};
        }
    }

    pub fn closeTag(self: *Processor, cap: *ParseCapture) void {
        var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);
        if (self.block) |b| {
            const text = b[cap.start..cap.end];
            stdout.print("close: {s} {}-{} {s}\n", .{ text, cap.start, cap.end, cap.scope }) catch {};
        }
    }

    pub fn capture(self: *Processor, cap: *ParseCapture) void {
        var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);
        if (self.block) |b| {
            if (cap.start >= b.len) return;
            const text = b[cap.start..cap.end];
            stdout.print("capture: {s} {}-{} {s}\n", .{ text, cap.start, cap.end, cap.scope }) catch {};
        }
    }

    pub fn init(allocator: Allocator) !Processor {
        const self = DumpProcessor;
        var proc = try NullProcessor.init(allocator);
        proc.start_line_fn = self.startLine;
        proc.end_line_fn = self.endLine;
        proc.open_tag_fn = self.openTag;
        proc.close_tag_fn = self.closeTag;
        proc.capture_fn = self.capture;
        return proc;
    }
};
