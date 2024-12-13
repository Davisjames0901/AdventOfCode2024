const std = @import("std");
const data = @embedFile("4.input");
const ArrayList = std.ArrayList;

pub fn main() !void {
    var colWidth: usize = 0;
    while (data[colWidth] != '\n') : (colWidth += 1) {}
    colWidth += 1;
    std.debug.print("Cols: {}\n", .{colWidth});
    var total: i64 = 0;
    //skip the last 2 lines
    for (0..data.len - (colWidth * 2)) |i| {
        if (i % colWidth >= colWidth - 2)
            continue;

        if ((searchDiag(i, colWidth, 1, "MAS") or
            searchDiag(i, colWidth, 1, "SAM")) and
            (searchDiag(i + 2, colWidth, -1, "MAS") or
            searchDiag(i + 2, colWidth, -1, "SAM")))
            total += 1;
    }
    std.debug.print("Answer: {}\n", .{total});
}

fn searchDiag(start: usize, colWidth: usize, direction: i32, pattern: *const [3:0]u8) bool {
    for (pattern, 0..) |char, i| {
        const lineOffset = colWidth * i;
        var indexToCheck = start + lineOffset;
        if (direction == 1) {
            indexToCheck += i;
        } else if (direction == -1) {
            indexToCheck -= i;
        }

        if (indexToCheck > data.len)
            return false;

        if (char != data[indexToCheck])
            return false;
    }
    return true;
}
