const std = @import("std");
const data = @embedFile("puzzle.input");

const ITERATIONS = 75;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tokens = std.mem.tokenize(u8, data, " ");
    var stoneLookup = std.AutoHashMap(Stone, u64).init(allocator);

    var total: u64 = 0;
    while (tokens.next()) |stone| {
        const num = try std.fmt.parseInt(u64, stone, 10);
        total += try getNumberOfStonesAfter(num, ITERATIONS, &stoneLookup);
    }
    std.debug.print("Answer: {}\n", .{total});
}

fn getNumberOfStonesAfter(start: u64, iterations: usize, lookup: *std.AutoHashMap(Stone, u64)) !u64 {
    var currentStone = start;
    var total: u64 = 1;

    const key = .{ .val = start, .i = iterations };
    if (lookup.get(key)) |hit|
        return hit;

    for (0..iterations) |i| {
        if (currentStone == 0) {
            currentStone = 1;
        } else if (splitNumber(currentStone)) |split| {
            currentStone = split.left;
            total += try getNumberOfStonesAfter(split.right, iterations - i - 1, lookup);
        } else {
            currentStone *= 2024;
        }
    }

    try lookup.put(key, total);

    return total;
}

fn splitNumber(num: u64) ?struct { left: u64, right: u64 } {
    const len = std.math.log_int(u64, 10, num) + 1;
    if (len % 2 == 0) {
        const half = len / 2;
        const pow = std.math.pow(u64, 10, half);
        const left = @divFloor(num, pow);
        const right = num - (left * pow);
        return .{ .left = left, .right = right };
    }
    return null;
}

const Stone = struct { val: u64, i: usize };
