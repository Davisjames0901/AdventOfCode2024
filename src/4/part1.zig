const std = @import("std");
const data = @embedFile("4.input");
const ArrayList = std.ArrayList;

pub fn main() !void {
    var colWidth: usize = 0;
    while (data[colWidth] != '\n') : (colWidth += 1) {}
    colWidth += 1;

    var total: i64 = 0;
    for (0..data.len) |i| {
        if (data.len < 4 + i)
            break;

        total += search(i, 0, 1, "SAMX");
        total += search(i, 0, 1, "XMAS");
        total += search(i, colWidth, 1, "XMAS");
        total += search(i, colWidth, 1, "SAMX");
        total += search(i, colWidth, -1, "XMAS");
        total += search(i, colWidth, -1, "SAMX");
        total += search(i, colWidth, 0, "XMAS");
        total += search(i, colWidth, 0, "SAMX");
    }
    std.debug.print("Answer: {}\n", .{total});
}

fn search(start: usize, colWidth: usize, directionToCheck: i32, pattern: *const [4:0]u8) i32 {
    for (pattern, 0..) |char, i| {
        const lineOffset = colWidth * i;
        var indexToCheck = start + lineOffset;
        if (directionToCheck == 1) {
            indexToCheck += i;
        } else if (directionToCheck == -1) {
            indexToCheck -= i;
        }

        if (indexToCheck > data.len)
            return 0;

        if (char != data[indexToCheck])
            return 0;
    }
    return 1;
}
