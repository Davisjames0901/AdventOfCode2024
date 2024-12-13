const std = @import("std");
const data = @embedFile("7.input");

pub fn main() !void {
    var lines = std.mem.tokenizeAny(u8, data, "\n");
    var total: u64 = 0;

    while (lines.next()) |line| {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        var tokens = std.mem.tokenizeAny(u8, line, ": ");
        var calibration = std.ArrayList(u64).init(allocator);

        while (tokens.next()) |token| {
            const num = try std.fmt.parseInt(u64, token, 10);
            try calibration.append(num);
        }

        total += getValueIfValid(&calibration);
    }

    std.debug.print("Total {}\n", .{total});
}

fn getValueIfValid(calibration: *const std.ArrayList(u64)) u64 {
    const target = calibration.items[0];
    const components = calibration.items[1..];

    if (components.len == 1 and components[0] == target)
        return target;

    const maxOperation = (@as(usize, 1) << @intCast(components.len - 1));
    for (0..maxOperation) |i| {
        const answer = do(components, i);
        if (answer == target) {
            return target;
        }
    }

    return 0;
}

fn do(components: []u64, operations: usize) u64 {
    var total = components[0];
    for (components[1..], 0..) |component, i| {
        const operation = (operations >> @intCast(i)) & 1;
        if (operation == 0) {
            total += component;
        }
        if (operation == 1) {
            total *= component;
        }
    }
    return total;
}
