const std = @import("std");
const parser = @import("parser.zig");
const theme = @import("theme.zig");
const util = @import("util.zig");
const setColorHex = util.setColorHex;
const setColorRgb = util.setColorRgb;
const setBgColorHex = util.setBgColorHex;
const setBgColorRgb = util.setBgColorRgb;
const resetColor = util.resetColor;

pub const Processor = struct {
    allocator: std.mem.Allocator,
    block: ?[]const u8 = null,
    theme: ?*theme.Theme = null,

    captures: std.ArrayList(parser.Capture),
    retained_captures: std.ArrayList(parser.Capture),

    start_document_fn: ?*const fn (*Processor) void = null,
    end_document_fn: ?*const fn (*Processor) void = null,
    start_line_fn: ?*const fn (*Processor, block: []const u8) void = null,
    end_line_fn: ?*const fn (*Processor) void = null,
    open_tag_fn: ?*const fn (*Processor, parser.Capture) void = null,
    close_tag_fn: ?*const fn (*Processor, parser.Capture) void = null,
    capture_fn: ?*const fn (*Processor, parser.Capture) void = null,

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
        for (0..self.retained_captures.items.len) |i| {
            var cap = self.retained_captures.items[i];
            cap.start = 0;
            if (self.block) |b| {
                cap.end = b.len;
            }
            self.captures.append(cap) catch {};
        }
        if (self.start_line_fn) |f| {
            f(self, block);
        }
    }

    pub fn endLine(self: *Processor) void {
        if (self.end_line_fn) |f| {
            f(self);
        }

        // can't be inside both comment and string
        if (self.retained_captures.items.len > 0) return;

        self.retained_captures.clearRetainingCapacity();
        for (0..self.captures.items.len) |i| {
            const cap = self.captures.items[i];
            if (cap.retain) {
                self.retained_captures.append(cap) catch {};
            }
        }
    }

    pub fn openTag(self: *Processor, cap: parser.Capture) void {
        var c = cap;
        if (self.block) |b| {
            if (c.start > b.len and b.len > 0) {
                c.start = b.len;
            }
            c.end = b.len;
            // c.retain = true;
            // TODO retain only string and comment blocks?
            // set retention at Parser, since capture only has syntax_id
        }
        self.captures.append(c) catch {};
        if (self.open_tag_fn) |f| {
            f(self, c);
        }
    }

    pub fn closeTag(self: *Processor, cap: parser.Capture) void {
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
        while (i > 0) : (i -= 1) {
            if (self.captures.items[i - 1].syntax_id == c.syntax_id) {
                self.captures.items[i - 1].end = c.end;
                self.captures.items[i - 1].retain = false;
                break;
            }
        }

        if (self.close_tag_fn) |f| {
            f(self, c);
        }
    }

    pub fn capture(self: *Processor, cap: parser.Capture) void {
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

        self.captures.append(c) catch {};
        if (self.capture_fn) |f| {
            f(self, c);
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

    pub fn openTag(self: *Processor, cap: parser.Capture) void {
        if (self.block) |b| {
            const text = b[cap.start..cap.end];
            std.debug.print("open: {s} {}-{} {s}\n", .{ text, cap.start, cap.end, cap.scope });
        }
    }

    pub fn closeTag(self: *Processor, cap: parser.Capture) void {
        if (self.block) |b| {
            const text = b[cap.start..cap.end];
            std.debug.print("close: {s} {}-{} {s}\n", .{ text, cap.start, cap.end, cap.scope });
        }
    }

    pub fn capture(self: *Processor, cap: parser.Capture) void {
        if (self.block) |b| {
            if (cap.start >= b.len) return;
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
            .retained_captures = std.ArrayList(parser.Capture).init(allocator),
        };
    }
};

const Rgb = theme.Rgb;

pub const RenderProcessor = struct {
    pub fn endLine(self: *Processor) void {
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
                var cap: parser.Capture = parser.Capture{};
                for (0..captures.items.len) |ci| {
                    if (i == captures.items[ci].start) {
                        cap = captures.items[ci];

                        var colors = theme.Settings{};
                        const scope = thm.getScope(cap.scope[0..cap.scope.len], &colors);
                        _ = scope;
                        // std.debug.print("?", .{});

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
                    setColorRgb(std.debug, current_color) catch {};
                }

                // _ = ch;
                if (ch == '\t') {
                    std.debug.print("  ", .{});
                } else {
                    std.debug.print("{c}", .{ch});
                }

                for (0..captures.items.len) |ci| {
                    if (i + 1 == captures.items[ci].end) {
                        if (color_stack_idx > 1) {
                            color_stack_idx -= 1;
                        }
                        current_color = Rgb{};
                        resetColor(std.debug) catch {};
                    }
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
            .retained_captures = std.ArrayList(parser.Capture).init(allocator),
        };
    }
};

pub const RenderHtmlProcessor = struct {
    pub fn startDocument(self: *Processor) void {
        const stdout = std.io.getStdOut().writer();
        if (self.theme) |thm| {
            const default_color = thm.getColor("editor.background") orelse
                thm.getColor("background");
            if (default_color) |c| {
                if (c.foreground) |fg| {
                    stdout.print("<html><body style=\"background: {s};\"><span>", .{fg[0..7]}) catch {};
                }
            }
        }
    }

    pub fn endDocument(self: *Processor) void {
        const stdout = std.io.getStdOut().writer();
        stdout.print("</body></html>", .{}) catch {};
        _ = self;
    }

    pub fn endLine(self: *Processor) void {
        const stdout = std.io.getStdOut().writer();
        if (self.theme) |thm| {
            // const defaultColor: ?theme.Settings = theme.Settings{.foreground_rgb = theme.Rgb {.r = 255 }};
            // const default_color = (thm.getColor("editor.foreground") orelse
            //     thm.getColor("foreground") orelse theme.Settings{.foreground = "#FFFFFF"}).foreground.?;

            const captures = self.captures;
            const block = self.block orelse "";

            for (block, 0..) |ch, i| {
                if (ch == '\n') break;
                var cap: parser.Capture = parser.Capture{};
                for (0..captures.items.len) |ci| {
                    if (i == captures.items[ci].start) {
                        cap = captures.items[ci];

                        var colors = theme.Settings{};
                        const scope = thm.getScope(cap.scope[0..cap.scope.len], &colors);
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
                } else if (ch == '\t') {
                    stdout.print("&nbsp;&nbsp;", .{}) catch {};
                } else {
                    stdout.print("{c}", .{ch}) catch {};
                }

                for (0..captures.items.len) |ci| {
                    if (i == captures.items[ci].end) {
                        var colors = theme.Settings{};
                        const scope = thm.getScope(cap.scope[0..cap.scope.len], &colors);
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
    }

    pub fn init(allocator: std.mem.Allocator) !Processor {
        const self = RenderHtmlProcessor;
        return Processor{
            .allocator = allocator,
            .start_document_fn = self.startDocument,
            .end_document_fn = self.endDocument,
            .end_line_fn = self.endLine,
            .captures = std.ArrayList(parser.Capture).init(allocator),
            .retained_captures = std.ArrayList(parser.Capture).init(allocator),
        };
    }
};

pub const NullProcessor = struct {
    pub fn init(allocator: std.mem.Allocator) !Processor {
        return Processor{
            .allocator = allocator,
            .captures = std.ArrayList(parser.Capture).init(allocator),
            .retained_captures = std.ArrayList(parser.Capture).init(allocator),
        };
    }
};
