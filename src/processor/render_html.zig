const std = @import("std");
const processor = @import("processor.zig");
const Processor = processor.Processor;
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

pub const RenderHtmlProcessor = struct {
    pub fn startDocument(self: *Processor) void {
        var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);

        if (self.theme) |thm| {
            const default_color = thm.getColor("editor.background") orelse
                thm.getColor("background");
            if (default_color) |c| {
                if (c.foreground) |fg| {
                    stdout.print("<html><body style=\"background: {s};\"><span>", .{fg[0..7]}) catch {};
                }
            }
        }

        stdout.flush() catch {};
    }

    pub fn endDocument(self: *Processor) void {
        _ = self;
        var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);

        stdout.print("</body></html>", .{}) catch {};
        stdout.flush() catch {};
    }

    pub fn endLine(self: *Processor) void {
        var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);

        var atoms: [4]Atom = [_]Atom{Atom{}} ** 4;

        if (self.theme) |thm| {
            const captures = self.captures;
            const block = self.block orelse "";

            var color_stack: [32]Rgb = [_]Rgb{Rgb{}} ** 32;
            var color_stack_idx: usize = 0;
            var current_color = Rgb{};
            var current_scope: []const u8 = "";

            const default_color = thm.getColor("editor.foreground") orelse
                thm.getColor("foreground");

            if (default_color) |c| {
                if (c.foreground_rgb) |fg| {
                    color_stack[color_stack_idx] = fg;
                    color_stack_idx += 1;
                }
            }

            for (block, 0..) |ch, i| {
                if (ch == '\n') break;
                var cap: ParseCapture = ParseCapture{};
                for (0..captures.items.len) |ci| {
                    if (i == captures.items[ci].start) {
                        cap = captures.items[ci];

                        var colors = theme.Settings{};
                        atoms[0] = cap.atom;

                        const scope = thm.getScope(cap.scope, &atoms, &colors);
                        _ = scope;

                        current_scope = cap.scope;

                        // std.debug.print("{}? ", .{scope_name.len});

                        // if (colors.foreground) |fgs| {
                        //     std.debug.print("{s}\n", .{fgs});
                        // }

                        if (colors.foreground_rgb) |fg| {
                            color_stack[color_stack_idx] = fg;
                        } else {
                            color_stack[color_stack_idx] = color_stack[color_stack_idx - 1];
                        }

                        color_stack_idx += 1;
                    }
                }

                const top_color = color_stack[color_stack_idx - 1];
                if (top_color.r != current_color.r or
                    top_color.g != current_color.g or
                    top_color.b != current_color.b)
                {
                    current_color = top_color;
                    stdout.print("<span title=\"{s}\" style=\"color: rgb({},{},{});\">", .{ current_scope, top_color.r, top_color.g, top_color.b }) catch {};
                }

                // _ = ch;
                if (ch == ' ') {
                    stdout.print("&nbsp;", .{}) catch {};
                } else if (ch == '\t') {
                    stdout.print("&nbsp;&nbsp;&nbsp;", .{}) catch {};
                } else {
                    stdout.print("{c}", .{ch}) catch {};
                }

                for (0..captures.items.len) |ci| {
                    if (i + 1 == captures.items[ci].end) {
                        if (color_stack_idx > 1) {
                            color_stack_idx -= 1;
                        }
                        current_color = Rgb{};
                        stdout.print("</span>", .{}) catch {};
                    }
                }
            }

            stdout.print("<br/>\n", .{}) catch {};
        } else {
            stdout.print("theme is not set\n", .{}) catch {};
        }

        stdout.flush() catch {};
    }

    pub fn init(allocator: Allocator) !Processor {
        const self = RenderHtmlProcessor;
        return Processor{
            .allocator = allocator,
            .start_document_fn = self.startDocument,
            .end_document_fn = self.endDocument,
            .end_line_fn = self.endLine,
            .captures = try std.ArrayList(ParseCapture).initCapacity(allocator, 32),
        };
    }
};
