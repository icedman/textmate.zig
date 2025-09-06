const std = @import("std");
const util = @import("util.zig");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayList;

const empty_string = "";

pub const StringsArena = struct {
    allocator: Allocator,
    arena: std.heap.ArenaAllocator,
    hashed: std.AutoHashMap(u64, []const u8),

    pub fn init(allocator: std.mem.Allocator) !StringsArena {
        return StringsArena{
            .allocator = allocator,
            .arena = std.heap.ArenaAllocator.init(allocator),
            .hashed = std.AutoHashMap(u64, []const u8).init(allocator),
        };
    }

    pub fn deinit(self: *StringsArena) void {
        self.hashed.deinit();
        self.arena.deinit();
    }

    pub fn append(self: *StringsArena, str: []const u8) ![]const u8 {
        if (str.len == 0) return empty_string;
        return try self.arena.allocator().dupe(u8, str);
    }

    pub fn appendHashed(self: *StringsArena, str: []const u8) !struct { u64, []const u8 } {
        if (str.len == 0) {
            return .{ 0, "" };
        }

        const hash: u64 = util.toHash(str);
        const gop = try self.hashed.getOrPut(hash);

        if (!gop.found_existing) {
            const slice = try self.arena.allocator().dupe(u8, str);
            gop.value_ptr.* = slice;
        }

        return .{ hash, gop.value_ptr.* };
    }

    pub fn appendUnique(self: *StringsArena, str: []const u8) ![]const u8 {
        if (str.len == 0) return empty_string;
        const h = try self.appendHashed(str);
        return h[1];
    }
};

test "strings" {
    var strings = try StringsArena.init(std.testing.allocator);
    defer strings.deinit();

    var buf: [128]u8 = undefined;
    for (0..200) |idx| {
        const s = try std.fmt.bufPrint(&buf, "{s} {d}", .{ "hello", idx * 0 });
        const c = try strings.appendHashed(s);
        // _ = c;
        std.debug.print("{} {s}\n", .{ c[0], c[1] });
    }
}
