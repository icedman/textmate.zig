const std = @import("std");
const parser = @import("parser.zig");

pub const TEMP_BUFFER_SIZE = 64;

fn applyRef(match: *const parser.Match, block: []const u8, target: []const u8, escape_character: u8, output: *[TEMP_BUFFER_SIZE]u8) []const u8 {
    var output_idx: usize = 0;
    var escape = false;
    var skip: usize = 0;
    for (target, 0..) |ch, idx| {
        if (skip > 0) {
            skip -= 1;
            continue;
        }
        if (output_idx >= output.len) break;
        if (escape and std.ascii.isDigit(ch)) {
            output_idx -= 1;
            for (0..match.count) |i| {
                const r = match.captures[i];
                const digit: u8 = blk: {
                    const d = ch - '0';
                    if (output_idx < output.len - 1) {
                        // check for another digit
                        const ch2 = target[idx + 1];
                        if (std.ascii.isDigit(ch2)) {
                            const d2 = ch2 - '0';
                            skip = 1;
                            const dd = d * 10 + d2;
                            break :blk dd;
                        }
                    }
                    break :blk d;
                };
                if (digit == r.group) {
                    for (r.start..r.end) |bi| {
                        output[output_idx] = block[bi];
                        output_idx += 1;
                    }
                }
            }
        } else {
            output[output_idx] = ch;
            output_idx += 1;
        }
        escape = (!escape) and (ch == escape_character);
    }

    // std.debug.print("{s}\n", .{output});
    return output;
}

pub fn applyReferences(match: *const parser.Match, block: []const u8, target: []const u8, output: *[TEMP_BUFFER_SIZE]u8) []const u8 {
    return applyRef(match, block, target, '\\', output);
}

pub fn applyCaptures(match: *const parser.Match, block: []const u8, target: []const u8, output: *[TEMP_BUFFER_SIZE]u8) []const u8 {
    return applyRef(match, block, target, '$', output);
}
