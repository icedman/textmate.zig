const std = @import("std");
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
                    if (context.syntax.rx_begin.is_comment_block or context.syntax.rx_begin.is_string_block) {
                        var c = ParseCapture{
                            .start = 0,
                            .end = block.len,
                            .syntax = context.syntax,
                            .atom = context.syntax.atom,
                        };
                        if (c.atom.count == 0) {
                            const name = context.syntax.getName();
                            c.scope = name;
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

pub const NullProcessor = struct {
    pub fn init(allocator: Allocator) !Processor {
        return Processor{
            .allocator = allocator,
            .captures = try std.ArrayList(ParseCapture).initCapacity(allocator, 32),
        };
    }
};

const dump_processor = @import("dump_processor.zig");
const render_console = @import("render_console.zig");
const render_html = @import("render_html.zig");

pub const DumpProcessor = dump_processor.DumpProcessor;
pub const RenderProcessor = render_console.RenderProcessor;
pub const RenderHtmlProcessor = render_html.RenderHtmlProcessor;
