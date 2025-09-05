const std = @import("std");
const parser = @import("parser.zig");
const grammar = @import("grammar.zig");
const theme = @import("theme.zig");
const util = @import("util.zig");
const atms = @import("atoms.zig");

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

pub const Processor = struct {
    allocator: Allocator,
    block: ?[]const u8 = null,
    theme: ?*theme.Theme = null,
    state: ?*ParseState = null,
    captures: std.ArrayList(ParseCapture),

    start_document_fn: ?*const fn (*Processor) void = null,
    end_document_fn: ?*const fn (*Processor) void = null,
    start_line_fn: ?*const fn (*Processor, block: []const u8) void = null,
    end_line_fn: ?*const fn (*Processor) void = null,
    open_tag_fn: ?*const fn (*Processor, *ParseCapture) void = null,
    close_tag_fn: ?*const fn (*Processor, *ParseCapture) void = null,
    capture_fn: ?*const fn (*Processor, *ParseCapture) void = null,

    pub fn startDocument(self: *Processor) void {
        if (self.start_document_fn) |f| {
            f(self);
        }
    }

    pub fn endDocument(self: *Processor) void {
        if (self.end_document_fn) |f| {
            f(self);
        }
    }

    pub fn startLine(self: *Processor, block: []const u8) void {
        self.block = block;
        self.captures.clearRetainingCapacity();

        if (self.state) |state| {
            for (state.stack.items) |context| {
                if (context.syntax.rx_begin.valid == .Valid) {
                    if (context.syntax.rx_begin.is_comment_block) {
                        var c = ParseCapture{
                            .start = 0,
                            .end = block.len,
                            .syntax = context.syntax,
                            .atom = context.syntax.atom,
                        };
                        if (c.atom.count == 0) {
                            const name = context.syntax.getName();
                            @memcpy(c.scope[0..name.len], name);
                        }
                        self.captures.append(self.allocator, c) catch {};
                    } else if (context.syntax.rx_begin.is_string_block) {
                        var c = ParseCapture{
                            .start = 0,
                            .end = block.len,
                            .syntax = context.syntax,
                            .atom = context.syntax.atom,
                        };
                        if (c.atom.count == 0) {
                            const name = context.syntax.getName();
                            @memcpy(c.scope[0..name.len], name);
                        }
                        self.captures.append(self.allocator, c) catch {};
                    }
                }
            }
        }

        if (self.start_line_fn) |f| {
            f(self, block);
        }
    }

    pub fn endLine(self: *Processor) void {
        if (self.end_line_fn) |f| {
            f(self);
        }
    }

    pub fn openTag(self: *Processor, cap: *ParseCapture) void {
        var c = cap;
        if (self.block) |b| {
            if (c.start > b.len and b.len > 0) {
                c.start = b.len;
            }
            c.end = b.len;
        }
        self.captures.append(self.allocator, c.*) catch {};
        if (self.open_tag_fn) |f| {
            f(self, c);
        }
    }

    pub fn closeTag(self: *Processor, cap: *ParseCapture) void {
        var c = cap;
        if (self.block) |b| {
            // this happens if parser adds '\n' at every parse
            if (c.start > b.len and b.len > 0) {
                c.start = b.len;
            }
            if (c.end >= b.len and b.len > 0) {
                c.end = b.len;
            }
        }
        // close the Capture (properly set the end pos)
        var i = self.captures.items.len;
        var close_syntax: ?*Syntax = null;
        while (i > 0) : (i -= 1) {
            if (self.captures.items[i - 1].syntax == c.syntax) {
                self.captures.items[i - 1].end = c.end;
                close_syntax = c.syntax;
            } else if (close_syntax != null and close_syntax != c.syntax) {
                break;
            }
        }

        if (self.close_tag_fn) |f| {
            f(self, c);
        }
    }

    pub fn capture(self: *Processor, cap: *ParseCapture) void {
        var c = cap;
        if (self.block) |b| {
            // this happens if parser adds '\n' at every parse
            if (c.start > b.len and b.len > 0) {
                c.start = b.len;
            }
            if (c.end > b.len and b.len > 0) {
                c.end = b.len;
            }
        }

        self.captures.append(self.allocator, c.*) catch {};
        if (self.capture_fn) |f| {
            f(self, c);
        }
    }

    pub fn deinit(self: *Processor) void {
        self.captures.deinit(self.allocator);
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

const Rgb = theme.Rgb;

pub const RenderProcessor = struct {
    pub fn endLine(self: *Processor) void {
        var stdout_buffer: [1024]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
        const stdout = &stdout_writer.interface;

        var atoms: [4]Atom = [_]Atom{Atom{}} ** 4;

        if (self.theme) |thm| {
            // const defaultColor: ?theme.Settings = theme.Settings{.foreground_rgb = theme.Rgb {.r = 255 }};
            const captures = self.captures;
            const block = self.block orelse "";

            var color_stack: [1024]Rgb = [_]Rgb{Rgb{}} ** 1024;
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
                        const scope_name = cap.scope[0..cap.scope.len]; // util.toSlice([98]u8, cap.scope);
                        const scope = thm.getScope(scope_name, &atoms, &colors);
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

pub const RenderHtmlProcessor = struct {
    pub fn startDocument(self: *Processor) void {
        var stdout_buffer: [1024]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
        const stdout = &stdout_writer.interface;
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
        var stdout_buffer: [1024]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
        const stdout = &stdout_writer.interface;
        stdout.print("</body></html>", .{}) catch {};
        _ = self;
        stdout.flush() catch {};
    }

    pub fn endLine(self: *Processor) void {
        var stdout_buffer: [1024]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
        const stdout = &stdout_writer.interface;

        var atoms: [4]Atom = [_]Atom{Atom{}} ** 4;

        if (self.theme) |thm| {
            // const defaultColor: ?theme.Settings = theme.Settings{.foreground_rgb = theme.Rgb {.r = 255 }};
            // const default_color = (thm.getColor("editor.foreground") orelse
            //     thm.getColor("foreground") orelse theme.Settings{.foreground = "#FFFFFF"}).foreground.?;

            const captures = self.captures;
            const block = self.block orelse "";

            for (block, 0..) |ch, i| {
                if (ch == '\n') break;
                var cap: ParseCapture = ParseCapture{};
                for (0..captures.items.len) |ci| {
                    if (i == captures.items[ci].start) {
                        cap = captures.items[ci];

                        var colors = theme.Settings{};
                        atoms[0] = cap.atom;
                        const scope_name = cap.scope[0..cap.scope.len]; // util.toSlice([98]u8, cap.scope);
                        const scope = thm.getScope(scope_name, &atoms, &colors);
                        _ = scope;
                        if (colors.foreground) |fg| {
                            const scope_len = for (0..64) |si| {
                                if (cap.scope[si] == 0) break si;
                            } else 0;
                            stdout.print("<span class=\"{s}\" style=\"color:{s};\">", .{ cap.scope[0..scope_len], fg[0..7] }) catch {};
                        }
                        // std.debug.print("\n{s} {}-{} [{}]\n", .{ cap.scope, captures.items[ci].start, captures.items[ci].end, i });
                    }
                }

                // _ = ch;
                if (ch == '<') {
                    stdout.print("&lt;", .{}) catch {};
                } else if (ch == ' ') {
                    stdout.print("&nbsp;", .{}) catch {};
                } else if (ch == '\t') {
                    stdout.print("&nbsp;&nbsp;", .{}) catch {};
                } else {
                    stdout.print("{c}", .{ch}) catch {};
                }

                for (0..captures.items.len) |ci| {
                    if (i == captures.items[ci].end) {
                        var colors = theme.Settings{};
                        const scope = thm.getScope(cap.scope[0..cap.scope.len], &atoms, &colors);
                        _ = scope;
                        if (colors.foreground) |fg| {
                            _ = fg;
                            stdout.print("</span>", .{}) catch {};
                        }
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

pub const NullProcessor = struct {
    pub fn init(allocator: Allocator) !Processor {
        return Processor{
            .allocator = allocator,
            .captures = try std.ArrayList(ParseCapture).initCapacity(allocator, 32),
        };
    }
};
