const std = @import("std");
const data = @embedFile("7.input");

pub fn main() !void {
    var lines = std.mem.tokenizeAny(u8, data, "\n");
    var total: u64 = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var calibration = std.ArrayList(u64).init(allocator);

    while (lines.next()) |line| {
        var tokens = std.mem.tokenizeAny(u8, line, ": ");

        while (tokens.next()) |token| {
            const num = try std.fmt.parseInt(u64, token, 10);
            try calibration.append(num);
        }

        total += try getValueIfValid(&calibration);
        calibration.clearRetainingCapacity();
    }

    std.debug.print("Total {}\n", .{total});
}

fn getValueIfValid(calibration: *const std.ArrayList(u64)) !u64 {
    const target = calibration.items[0];
    const components = calibration.items[1..];
    if (components.len == 1 and components[0] == target)
        return target;

    var operations: [15]u2 = [_]u2{0} ** 15;

    sim: while (true) {
        const answer = try do(&components, &operations, target);
        if (answer == target) {
            return target;
        }
        for (0..components.len - 1) |i| {
            const op = operations[i];
            if (op < 2) {
                operations[i] = op + 1;
                for (0..i) |ix| {
                    operations[ix] = 0;
                }
                continue :sim;
            }
        }
        break;
    }

    return 0;
}

fn do(components: *const []u64, operations: *const [15]u2, target: u64) !u64 {
    var total = components.*[0];
    for (components.*[1..], 0..) |component, i| {
        const operation = operations[i];
        if (operation == 0) {
            total += component;
        } else if (operation == 1) {
            total *= component;
        } else if (operation == 2) {
            const len = std.math.log_int(u64, 10, component) + 1;
            //shift running total over by the length of the new component
            total *= std.math.pow(u64, 10, len);
            total += component;
        }
        if (total > target)
            return total;
    }
    return total;
}
