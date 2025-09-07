const std = @import("std");
const util = @import("util.zig");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayList;

const empty_string = "";

pub const StringsArena = struct {
    allocator: Allocator,
    arena: ArrayList([:0]const u8),
    hashed: std.AutoHashMap(u64, []const u8),

    pub fn init(allocator: std.mem.Allocator) !StringsArena {
        return StringsArena{
            .allocator = allocator,
            .arena = try ArrayList([:0]const u8).initCapacity(allocator, 128),
            .hashed = std.AutoHashMap(u64, []const u8).init(allocator),
        };
    }

    pub fn deinit(self: *StringsArena) void {
        self.hashed.deinit();
        for (self.arena.items) |item| {
            self.allocator.free(item);
        }
        self.arena.deinit(self.allocator);
    }

    pub fn append(self: *StringsArena, str: []const u8) ![]const u8 {
        if (str.len == 0) return empty_string;
        const buf = try self.allocator.dupeZ(u8, str);
        try self.arena.append(self.allocator, buf);
        return buf[0..str.len];
    }

    pub fn appendHashed(self: *StringsArena, str: []const u8) !struct { u64, []const u8 } {
        if (str.len == 0) {
            return .{ 0, empty_string };
        }

        const hash: u64 = util.toHash(str);
        const gop = try self.hashed.getOrPut(hash);

        if (!gop.found_existing) {
            const slice = try self.append(str);
            gop.value_ptr.* = slice;
        }

        return .{ hash, gop.value_ptr.* };
    }

    pub fn appendUnique(self: *StringsArena, str: []const u8) ![]const u8 {
        if (str.len == 0) return empty_string;
        const h = try self.appendHashed(str);
        return h[1];
    }

    pub fn clear(self: *StringsArena) void {
        for (self.arena.items) |item| {
            self.allocator.free(item);
        }
        self.arena.clearRetainingCapacity();
        self.hashed.clearRetainingCapacity();
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
