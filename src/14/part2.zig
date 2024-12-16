const std = @import("std");
const math = std.math;
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    std.debug.print("Answer: {}", .{total});
}
