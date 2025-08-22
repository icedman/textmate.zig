//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");

pub const oni = @import("oniguruma");

const theme = @import("theme.zig");
const grammar = @import("grammar.zig");
const parser = @import("parser.zig");
const processor = @import("processor.zig");

// Types
pub const ThemeLibrary = theme.ThemeLibrary;
pub const Theme = theme.Theme;

pub const GrammarLibrary = grammar.GrammarLibrary;
pub const Grammar = grammar.Grammar;
pub const Syntax = grammar.Syntax;

pub const Parser = parser.Parser;
pub const ParseState = parser.ParseState;
pub const ParseCapture = parser.Capture;

pub const Processor = processor.Processor;
pub const NullProcessor = processor.NullProcessor;
pub const DumpProcessor = processor.DumpProcessor;
pub const RenderProcessor = processor.RenderProcessor;
pub const RenderHtmlProcessor = processor.RenderHtmlProcessor;

const testing = std.testing;
