const std = @import("std");
const parser = @import("../parser.zig");
const grammar = @import("../grammar.zig");
const theme = @import("../theme.zig");
const atms = @import("../atoms.zig");
const config = @import("../config.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const ParseCapture = parser.ParseCapture;
const ParseState = parser.ParseState;
const Syntax = grammar.Syntax;
const Atom = atms.Atom;

pub const SpanCaptures = struct {
    text: []const u8,
    start: usize,
    end: usize,
    atoms: [config.max_span_captures]Atom = [_]Atom{Atom{}} ** config.max_span_captures,
    scopes: [config.max_span_captures][]const u8 = [_][]const u8{""} ** config.max_span_captures,
    count: u8 = 0,
};

// TODO comptime this
pub const Processor = struct {
    allocator: Allocator,
    captures: ArrayList(ParseCapture),
    spans: ArrayList(SpanCaptures),

    block: ?[]const u8 = null,
    theme: ?*theme.Theme = null,
    state: ?*ParseState = null,

    start_document_fn: ?*const fn (*Processor) void = null,
    end_document_fn: ?*const fn (*Processor) void = null,
    start_line_fn: ?*const fn (*Processor, block: []const u8) void = null,
    end_line_fn: ?*const fn (*Processor) void = null,
    open_tag_fn: ?*const fn (*Processor, *ParseCapture) void = null,
    close_tag_fn: ?*const fn (*Processor, *ParseCapture) void = null,
    capture_fn: ?*const fn (*Processor, *ParseCapture) void = null,

    // stats
    deepest: u32 = 0,

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
            // add root
            {
                const root = state.owner.lang.syntax.?.root();
                const name = root.getName();
                const c = ParseCapture{
                    .start = 0,
                    .end = block.len,
                    .syntax = root,
                    .atom = root.atom,
                    .scope = name,
                };
                self.captures.append(self.allocator, c) catch {};
            }
            for (state.stack.items) |context| {
                // add state tree
                if (context.syntax.rx_begin.valid == .Valid) {
                    const name = context.syntax.getName();
                    if (name.len > 0) {
                        const c = ParseCapture{
                            .start = 0,
                            .end = block.len,
                            .syntax = context.syntax,
                            .atom = context.syntax.atom,
                            .scope = name,
                        };
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
        if (cap.scope.len == 0) return;
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

        if (self.captures.items.len > self.deepest) {
            self.deepest = @intCast(self.captures.items.len);
        }
    }

    pub fn closeTag(self: *Processor, cap: *ParseCapture) void {
        if (cap.scope.len == 0) return;
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
        if (cap.scope.len == 0) return;
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
        self.spans.deinit(self.allocator);
    }

    fn appendTokens(self: *Processor, token: []const u8, allocator: Allocator, collect: *ArrayList([]const u8)) !void {
        const idx = std.mem.indexOf(u8, token, " ") orelse 0;
        if (idx > 0) {
            try self.appendTokens(token[0..idx], allocator, collect);
            try self.appendTokens(token[idx + 1 ..], allocator, collect);
            return;
        }
        // var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);
        // stdout.print("  !{s}\n", .{token}) catch {};
        try collect.append(allocator, token);
    }

    pub fn query(self: *Processor, start: usize, end: usize, allocator: Allocator, collect: ?*ArrayList([]const u8)) !void {
        // var stdout = @constCast(&std.fs.File.stdout().writerStreaming(&.{}).interface);
        if (self.block) |b| {
            _ = b;
            // stdout.print("...{s} {}-{}\n", .{ b[start..end], start, end }) catch {};
            for (self.captures.items) |cap| {
                if (start >= cap.start and end <= cap.end) {
                    if (collect) |c| {
                        try self.appendTokens(cap.scope, allocator, c);
                    }
                    // stdout.print("  ![{s}] {}-{}\n", .{ cap.scope, cap.start, cap.end }) catch {};
                }
            }
        }
    }

    fn add_cut_point(points: *[128]usize, count: *u8, pos: usize) void {
        if (count.* >= 128) return;
        for (0..count.*) |idx| {
            if (points[idx] == pos) return;
        }
        points[count.*] = pos;
        count.* += 1;
    }

    pub fn produce(self: *Processor) !*ArrayList(SpanCaptures) {
        self.spans.clearRetainingCapacity();

        var cut_points: [128]usize = [_]usize{0xffff} ** 128;
        var cut_points_count: u8 = 0;
        for (self.captures.items) |cap| {
            Processor.add_cut_point(&cut_points, &cut_points_count, cap.start);
            Processor.add_cut_point(&cut_points, &cut_points_count, cap.end);
        }

        std.sort.heap(usize, cut_points[0..cut_points_count], {}, comptime std.sort.asc(usize));

        if (cut_points_count < 2) return &self.spans;

        for (0..cut_points_count - 1) |idx| {
            const start = cut_points[idx];
            const end = cut_points[idx + 1];
            // std.debug.print(">{}-{}\n", .{start, end});
            if (self.block) |block| {
                var span = SpanCaptures{
                    .text = block[start..end],
                    .start = start,
                    .end = end,
                };
                for (self.captures.items) |cap| {
                    if (start >= cap.start and end <= cap.end) {
                        span.atoms[span.count] = cap.atom;
                        span.scopes[span.count] = cap.scope;

                        if (span.atoms[span.count].id == 0) {
                            if (self.theme) |thm| {
                                span.atoms[span.count].compute(cap.scope, &thm.atoms);
                            }
                        }

                        if (span.count > 0) {
                            if (span.atoms[span.count].id == span.atoms[span.count - 1].id) continue;
                        }

                        span.count += 1;
                        if (span.count >= config.max_span_captures) break;
                    }
                }

                // const max_spans = 6;
                // const max_spans_half = max_spans >> 1;
                // if (span.count > max_spans) {
                //     const tail_atoms = span.atoms[span.count - max_spans_half .. span.count];
                //     const tail_scopes = span.scopes[span.count - max_spans_half .. span.count];
                //     for(0..max_spans_half) |si| {
                //         span.atoms[max_spans_half + si] = tail_atoms[si];
                //         span.scopes[max_spans_half + si] = tail_scopes[si];
                //     }
                //     span.count = max_spans;
                // }

                try self.spans.append(self.allocator, span);
            }
        }

        return &self.spans;
    }

    pub fn dump(self: *Processor) void {
        for (self.captures.items) |cap| {
            std.debug.print("{s} {}-{}\n", .{ cap.scope, cap.start, cap.end });
        }
    }
};

pub const NullProcessor = struct {
    pub fn init(allocator: Allocator) !Processor {
        return Processor{
            .allocator = allocator,
            .captures = try ArrayList(ParseCapture).initCapacity(allocator, 32),
            .spans = try ArrayList(SpanCaptures).initCapacity(allocator, 32),
        };
    }
};

const dump_processor = @import("dump_processor.zig");
const render_console = @import("render_console.zig");
const render_html = @import("render_html.zig");

pub const DumpProcessor = dump_processor.DumpProcessor;
pub const RenderProcessor = render_console.RenderProcessor;
pub const RenderHtmlProcessor = render_html.RenderHtmlProcessor;
