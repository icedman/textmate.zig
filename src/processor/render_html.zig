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

pub const RenderHtmlProcessor = struct {
    pub fn startDocument(self: *Processor) void {
        var stdout_writer = std.Io.File.stdout().writerStreaming(self.io, &.{});
        const stdout = &stdout_writer.interface;

        if (self.theme) |thm| {
            const bg_color = thm.getColor("editor.background") orelse
                thm.getColor("background") orelse theme.Style{};
            const fg_color = thm.getColor("editor.foreground") orelse
                thm.getColor("foreground") orelse theme.Style{};

            const bg = bg_color.foreground orelse "#1e1e1e";
            const fg = fg_color.foreground orelse "#ffffff";

            stdout.print("<html><body style=\"background: {s}; color: {s};\"><pre style=\"font-family: monospace; margin: 0;\">", .{ bg, fg }) catch {};
        }

        stdout.flush() catch {};
    }

    pub fn endDocument(self: *Processor) void {
        var stdout_writer = std.Io.File.stdout().writerStreaming(self.io, &.{});
        const stdout = &stdout_writer.interface;

        stdout.writeAll("</pre></body></html>") catch {};
        stdout.flush() catch {};
    }

    fn writeEscaped(stdout: anytype, text: []const u8) void {
        var last_idx: usize = 0;
        for (text, 0..) |ch, i| {
            const replacement = switch (ch) {
                '&' => "&amp;",
                '<' => "&lt;",
                '>' => "&gt;",
                '"' => "&quot;",
                '\'' => "&#39;",
                else => null,
            };
            if (replacement) |rep| {
                if (i > last_idx) {
                    _ = stdout.write(text[last_idx..i]) catch {};
                }
                _ = stdout.write(rep) catch {};
                last_idx = i + 1;
            }
        }
        if (text.len > last_idx) {
            _ = stdout.write(text[last_idx..]) catch {};
        }
    }

    pub fn endLine(self: *Processor) void {
        var stdout_writer = std.Io.File.stdout().writerStreaming(self.io, &.{});
        const stdout = &stdout_writer.interface;
        const spans = self.produce() catch @panic("unable to produce");

        if (self.theme) |thm| {
            const fg_style = thm.getColor("editor.foreground") orelse thm.getColor("foreground");
            const bg_style = thm.getColor("editor.background") orelse thm.getColor("background");
            const default_style = theme.Style{
                .foreground_rgb = if (fg_style) |s| s.foreground_rgb else null,
                .background_rgb = if (bg_style) |s| s.foreground_rgb else null,
            };
            for (spans.items) |span| {
                var style = default_style;
                _ = thm.getSpanStyle(span.scopes, span.atoms, span.count, &style) catch {};

                if (style.foreground_rgb) |fg| {
                    stdout.print("<span style=\"color: rgb({},{},{});\">", .{ fg.r, fg.g, fg.b }) catch {};
                } else {
                    stdout.writeAll("<span>") catch {};
                }

                writeEscaped(stdout, span.text);

                stdout.writeAll("</span>") catch {};
            }
        } else {
            stdout.writeAll("theme is not set\n") catch {};
        }

        stdout.flush() catch {};
    }

    pub fn init(io: std.Io, allocator: Allocator) !Processor {
        const self = RenderHtmlProcessor;
        var proc = try NullProcessor.init(io, allocator);
        proc.start_document_fn = self.startDocument;
        proc.end_document_fn = self.endDocument;
        proc.end_line_fn = self.endLine;
        return proc;
    }
};
