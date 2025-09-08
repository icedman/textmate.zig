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

pub const RenderProcessor = struct {
    pub fn endLine(self: *Processor) void {
        var stdout_buffer: [1024]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
        const stdout = &stdout_writer.interface;
        // var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);

        var atoms: [4]Atom = [_]Atom{Atom{}} ** 4;

        if (self.theme) |thm| {
            const captures = self.captures;
            const block = self.block orelse "";

            var color_stack: [32]Rgb = [_]Rgb{Rgb{}} ** 32;
            var color_stack_idx: usize = 0;
            var current_color = Rgb{};

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
                    // std.debug.print("-", .{});
                    setColorRgb(stdout, current_color) catch {};
                }

                // _ = ch;
                if (ch == '\t') {
                    stdout.print("  ", .{}) catch {};
                } else {
                    stdout.print("{c}", .{ch}) catch {};
                }

                for (0..captures.items.len) |ci| {
                    if (i + 1 == captures.items[ci].end) {
                        if (color_stack_idx > 1) {
                            color_stack_idx -= 1;
                        }
                        current_color = Rgb{};
                        resetColor(stdout) catch {};
                    }
                }
            }

            stdout.print("\n", .{}) catch {};
        } else {
            stdout.print("theme is not set\n", .{}) catch {};
        }

        stdout.flush() catch {};
    }

    pub fn init(allocator: Allocator) !Processor {
        const self = RenderProcessor;
        return Processor{
            .allocator = allocator,
            .end_line_fn = self.endLine,
            .captures = try std.ArrayList(ParseCapture).initCapacity(allocator, 32),
        };
    }
};
