const std = @import("std");
const data = @embedFile("1.input");

pub fn main() !void {
    var tokens = std.mem.tokenizeAny(u8, data, " \n");
    var leftColumn = [_]i32{0} ** 1000;

    var lookup = std.AutoHashMap(i32, i32).init(std.heap.page_allocator);
    defer lookup.deinit();

    var inx: u16 = 0;
    while (tokens.next()) |tokenLeft| : (inx += 1) {
        const tokenRight = tokens.next() orelse break;

        const left = try std.fmt.parseInt(i32, tokenLeft, 10);
        const right = try std.fmt.parseInt(i32, tokenRight, 10);

        leftColumn[inx] = left;
        var lookup_val = lookup.get(right) orelse 0;
        lookup_val += 1;
        try lookup.put(right, lookup_val);
    }

    var similarity: i32 = 0;
    for (leftColumn) |left| {
        const occurrance = lookup.get(left) orelse 0;
        similarity += left * occurrance;
    }
    std.debug.print("Answer: {}\n", .{similarity});
}
