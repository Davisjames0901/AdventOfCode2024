const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var tokens = std.mem.tokenizeAny(u8, data, "\n");
    var total: i64 = 0;
    while(tokens.next()) |price| {
        var start = try std.fmt.parseInt(i64, price, 10);
        for(0..2000) |_| {
            start = next(start);
        }
        total += start;
    }
    std.debug.print("Answer: {}\n", .{total});
}

fn next(start: i64) i64 {
    var part = @mod(start ^ (start * 64), 16777216);
    part = @mod(part ^ @divFloor(part, 32), 16777216);
    return @mod(part ^ (part * 2048), 16777216);
}