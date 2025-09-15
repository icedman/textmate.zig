const std = @import("std");
const processor = @import("processor.zig");
const Processor = processor.Processor;
const NullProcessor = processor.NullProcessor;
const parser = @import("../parser.zig");
const grammar = @import("../grammar.zig");
const theme = @import("../theme.zig");
const util = @import("../ansi_terminal.zig");
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

pub const RenderProcessor = struct {
    pub fn endLine(self: *Processor) void {
        var stdout_buffer: [1024]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
        const stdout = &stdout_writer.interface;

        const spans = self.produce() catch {
            return;
        };

        if (self.theme) |thm| {
            const default_style = theme.Style{
                .foreground_rgb = (thm.getColor("editor.foreground") orelse
                    thm.getColor("foreground") orelse theme.Style{}).foreground_rgb,
                // all colors in "colors" map will be in the foreground -> this is going to be a pitfall
                .background_rgb = (thm.getColor("editor.background") orelse
                    thm.getColor("background") orelse theme.Style{}).foreground_rgb, 
            };
            for (spans.items) |span| {
                var style = default_style;
                _ = thm.getSpanStyle(span.scopes, span.atoms, span.count, &style) catch {}; 
                if (style.foreground_rgb) |fg| {
                    setColorRgb(stdout, fg) catch {};
                }
                if (style.background_rgb) |bg| {
                    setBgColorRgb(stdout, bg) catch {};
                }
                stdout.print("{s}", .{span.text}) catch {};
                resetColor(stdout) catch {};
            }
        }

        stdout.flush() catch {};
    }

    pub fn init(allocator: Allocator) !Processor {
        const self = RenderProcessor;
        var proc = try NullProcessor.init(allocator);
        proc.end_line_fn = self.endLine;
        return proc;
    }
};
