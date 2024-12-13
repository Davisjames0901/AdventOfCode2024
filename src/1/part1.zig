const std = @import("std");
const data = @embedFile("1.input");

pub fn main() !void {
    var tokens = std.mem.tokenizeAny(u8, data, " \n");
    var leftColumn = [_]i32{0} ** 1000;
    var rightColumn = [_]i32{0} ** 1000;

    var inx: u16 = 0;
    while (tokens.next()) |tokenLeft| : (inx += 1) {
        const tokenRight = tokens.next() orelse break;

        const left = try std.fmt.parseInt(i32, tokenLeft, 10);
        const right = try std.fmt.parseInt(i32, tokenRight, 10);

        leftColumn[inx] = left;
        rightColumn[inx] = right;
    }

    std.mem.sort(i32, &leftColumn, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, &rightColumn, {}, comptime std.sort.asc(i32));

    var totalDistance: u32 = 0;
    for (leftColumn, rightColumn) |left, right| {
        totalDistance += @abs(left - right);
    }
    std.debug.print("Answer: {}\n", .{totalDistance});
}
