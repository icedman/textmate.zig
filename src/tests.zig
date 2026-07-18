const std = @import("std");
const lib = @import("textmate_lib");

const Parser = lib.Parser;
const StateContextPack = lib.StateContextPack;

fn testSerializeDeserializeParseState(allocator: std.mem.Allocator) !void {
    const grammar_json =
        \\{
        \\  "scopeName": "source.test",
        \\  "patterns": [
        \\    {
        \\      "name": "block",
        \\      "begin": "\\{",
        \\      "end": "\\}"
        \\    }
        \\  ]
        \\}
    ;

    var gmr = try lib.Grammar.initWithData(allocator, grammar_json);
    defer gmr.deinit();

    var par = try Parser.init(allocator, gmr);
    defer par.deinit();

    var state = try par.initState();
    defer state.deinit();

    const line = "{\n";
    try par.parseLine(&state, line, true);

    var serial = try std.ArrayList(StateContextPack).initCapacity(allocator, 16);
    defer serial.deinit(allocator);
    try par.serialize(&state, &serial);

    try std.testing.expectEqual(state.stack.items.len, serial.items.len);

    var deserialized_state = try par.initState();
    defer deserialized_state.deinit();

    try par.deserialize(&deserialized_state, &serial);

    try std.testing.expectEqual(state.stack.items.len, deserialized_state.stack.items.len);
    for (state.stack.items, 0..) |item, i| {
        const deserialized_item = deserialized_state.stack.items[i];
        try std.testing.expectEqual(item.syntax, deserialized_item.syntax);
        try std.testing.expectEqual(item.anchor_start, deserialized_item.anchor_start);
        try std.testing.expectEqual(item.start, deserialized_item.start);
        try std.testing.expectEqual(item.rx_while.id, deserialized_item.rx_while.id);
        try std.testing.expectEqual(item.rx_end.id, deserialized_item.rx_end.id);
    }
}

fn testSerializeDeserializeEndToEndNestedParsing(allocator: std.mem.Allocator) !void {
    const grammar_json =
        \\{
        \\  "scopeName": "source.test",
        \\  "patterns": [
        \\    {
        \\      "name": "block",
        \\      "begin": "\\{",
        \\      "end": "\\}",
        \\      "patterns": [
        \\        { "include": "$self" }
        \\      ]
        \\    }
        \\  ]
        \\}
    ;

    var gmr = try lib.Grammar.initWithData(allocator, grammar_json);
    defer gmr.deinit();

    var par = try Parser.init(allocator, gmr);
    defer par.deinit();

    var state = try par.initState();
    defer state.deinit();

    // 1. Parse nested open brackets
    try par.parseLine(&state, "{\n", true);
    try par.parseLine(&state, "{\n", false);
    try par.parseLine(&state, "{\n", false);

    // Stack should have 4 elements: root syntax, and 3 nested blocks.
    try std.testing.expectEqual(@as(usize, 4), state.stack.items.len);

    // 2. Serialize the parse state
    var serial = try std.ArrayList(StateContextPack).initCapacity(allocator, 16);
    defer serial.deinit(allocator);
    try par.serialize(&state, &serial);

    try std.testing.expectEqual(@as(usize, 4), serial.items.len);

    // 3. Deserialize into a new state
    var deserialized_state = try par.initState();
    defer deserialized_state.deinit();

    try par.deserialize(&deserialized_state, &serial);

    try std.testing.expectEqual(@as(usize, 4), deserialized_state.stack.items.len);

    // 4. Continue parsing using the deserialized state
    // We should be able to close all the 3 blocks.
    try par.parseLine(&deserialized_state, "}\n", false);
    try std.testing.expectEqual(@as(usize, 3), deserialized_state.stack.items.len);

    try par.parseLine(&deserialized_state, "}\n", false);
    try std.testing.expectEqual(@as(usize, 2), deserialized_state.stack.items.len);

    try par.parseLine(&deserialized_state, "}\n", false);
    try std.testing.expectEqual(@as(usize, 1), deserialized_state.stack.items.len); // only root remains
}

fn testSerializeDeserializeStateWithDynamicReferences(allocator: std.mem.Allocator) !void {
    const grammar_json =
        \\{
        \\  "scopeName": "source.test",
        \\  "patterns": [
        \\    {
        \\      "name": "string",
        \\      "begin": "([a-z]+)",
        \\      "end": "\\1"
        \\    }
        \\  ]
        \\}
    ;

    var gmr = try lib.Grammar.initWithData(allocator, grammar_json);
    defer gmr.deinit();

    var par = try Parser.init(allocator, gmr);
    defer par.deinit();

    var state = try par.initState();
    defer state.deinit();

    // 1. Parse a line that triggers the begin pattern and dynamically compiles end pattern.
    // The match group 1 is "hello", so end pattern should dynamically become "hello".
    try par.parseLine(&state, "hello\n", true);

    // Stack should have 2 elements: root syntax, and the dynamic string match context.
    try std.testing.expectEqual(@as(usize, 2), state.stack.items.len);
    
    // The active rule's dynamic end pattern ID should be set in rx_end.id
    const active_ctx = state.stack.items[1];
    try std.testing.expect(active_ctx.rx_end.id > 0);

    // 2. Serialize
    var serial = try std.ArrayList(StateContextPack).initCapacity(allocator, 16);
    defer serial.deinit(allocator);
    try par.serialize(&state, &serial);

    // 3. Deserialize
    var deserialized_state = try par.initState();
    defer deserialized_state.deinit();

    try par.deserialize(&deserialized_state, &serial);

    try std.testing.expectEqual(state.stack.items.len, deserialized_state.stack.items.len);
    
    const deserialized_active_ctx = deserialized_state.stack.items[1];
    try std.testing.expectEqual(active_ctx.rx_end.id, deserialized_active_ctx.rx_end.id);
    
    // Check that rx_end is correctly resolved from the parser's regex_map
    try std.testing.expectEqualStrings(active_ctx.rx_end.expr.?, deserialized_active_ctx.rx_end.expr.?);

    // 4. Continue parsing with the deserialized state using the dynamic end pattern
    // If we parse "world\n", it shouldn't match "hello", so we stay in the string context.
    try par.parseLine(&deserialized_state, "world\n", false);
    try std.testing.expectEqual(@as(usize, 2), deserialized_state.stack.items.len);

    // If we parse "hello\n", it should match the dynamic end pattern "hello" and pop the string context.
    try par.parseLine(&deserialized_state, "hello\n", false);
    try std.testing.expectEqual(@as(usize, 1), deserialized_state.stack.items.len);
}

fn testSerializeDeserializeContinueParsing(allocator: std.mem.Allocator, io: std.Io) !void {
    const grammar_json =
        \\{
        \\  "scopeName": "source.test",
        \\  "patterns": [
        \\    {
        \\      "name": "comment.block",
        \\      "begin": "/\\*",
        \\      "end": "\\*/"
        \\    }
        \\  ]
        \\}
    ;

    var gmr = try lib.Grammar.initWithData(allocator, grammar_json);
    defer gmr.deinit();

    // Scenario A: Parse Line 1 -> Serialize -> Deserialize into Parser 2 -> Parse Line 2 & 3
    var par_b1 = try Parser.init(allocator, gmr);
    defer par_b1.deinit();

    var state_b1 = try par_b1.initState();
    defer state_b1.deinit();

    try par_b1.parseLine(&state_b1, "/* start\n", true);



    // Serialize state
    var serial = try std.ArrayList(StateContextPack).initCapacity(allocator, 16);
    defer serial.deinit(allocator);
    try par_b1.serialize(&state_b1, &serial);

    // Initialize Parser 2 (fresh instance)
    var par_b2 = try Parser.init(allocator, gmr);
    defer par_b2.deinit();

    var state_b2 = try par_b2.initState();
    defer state_b2.deinit();

    var proc_b2 = try lib.NullProcessor.init(io, allocator);
    defer proc_b2.deinit();
    par_b2.processor = &proc_b2;
    proc_b2.state = &state_b2;

    // Deserialize serialized state into Parser 2's state
    try par_b2.deserialize(&state_b2, &serial);



    // Now parse Line 2 on Parser 2
    try par_b2.parseLine(&state_b2, "middle\n", false);

    // Verify that the parser stayed inside the comment block on line 2
    var found_comment_block = false;
    for (proc_b2.captures.items) |cap| {
        if (std.mem.eql(u8, cap.scope, "comment.block")) {
            found_comment_block = true;
        }
    }
    try std.testing.expect(found_comment_block);

    // Now parse Line 3 on Parser 2
    try par_b2.parseLine(&state_b2, "end */\n", false);

    // Verify that Parser 2 successfully popped the comment context upon hitting the end pattern on line 3
    try std.testing.expectEqual(@as(usize, 1), state_b2.stack.items.len);
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try stdout.print("Running serialize/deserialize tests...\n", .{});

    try stdout.print("1. testSerializeDeserializeParseState...", .{});
    try testSerializeDeserializeParseState(allocator);
    try stdout.print(" passed\n", .{});

    try stdout.print("2. testSerializeDeserializeEndToEndNestedParsing...", .{});
    try testSerializeDeserializeEndToEndNestedParsing(allocator);
    try stdout.print(" passed\n", .{});

    try stdout.print("3. testSerializeDeserializeStateWithDynamicReferences...", .{});
    try testSerializeDeserializeStateWithDynamicReferences(allocator);
    try stdout.print(" passed\n", .{});

    try stdout.print("4. testSerializeDeserializeContinueParsing...", .{});
    try testSerializeDeserializeContinueParsing(allocator, io);
    try stdout.print(" passed\n", .{});

    try stdout.print("\nAll serialize/deserialize tests passed successfully!\n", .{});
    try stdout.flush();
}
