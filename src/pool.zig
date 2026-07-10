const std = @import("std");

pub fn Pool(comptime T: type) type {
    return struct {
        const Self = @This();

        list: std.ArrayList(T),

        pub fn init(allocator: std.mem.Allocator) !Self {
            return .{
                .list = try std.ArrayList(T).initCapacity(allocator, 1024),
            };
        }

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.list.deinit(allocator);
        }

        /// Allocate an uninitialized object.
        pub fn create(self: *Self) !*T {
            try self.list.appendBounded(undefined);
            return &self.list.items[self.list.items.len - 1];
        }

        pub fn items(self: *Self) []T {
            return self.list.items;
        }
    };
}
