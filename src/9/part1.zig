const std = @import("std");
const data = @embedFile("9test.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var fs = std.ArrayList(?usize).init(allocator);

    for (0..data.len) |inx| {
        const count = quickInt(data[inx]);
        var value: ?usize = null;
        //file block
        if (inx % 2 == 0) {
            value = @divFloor(inx, 2);
        }
        for (0..count) |_| {
            try fs.append(value);
        }
    }

    printFs(&fs);

    var total: usize = 0;
    for (0..fs.items.len) |i| {
        if (fs.items[i] == null) {
            const newVal = getRemoveLastValue(&fs, i);
            if (newVal == null)
                break;
            fs.items[i] = newVal;
        }
        total += fs.items[i].? * i;
    }

    printFs(&fs);
    // var total = 0;

    std.debug.print("Answer: {}\n", .{total});
}

fn getRemoveLastValue(fs: *const std.ArrayList(?usize), cutOff: usize) ?usize {
    for (0..fs.items.len) |i| {
        const reverseInx = fs.items.len - 1 - i;
        if (reverseInx == cutOff)
            return null;

        const val = fs.items[reverseInx];
        if (val != null) {
            fs.items[reverseInx] = null;
            return val.?;
        }
    }
    return null;
}

fn quickInt(char: u8) usize {
    return switch (char) {
        '0' => 0,
        '1' => 1,
        '2' => 2,
        '3' => 3,
        '4' => 4,
        '5' => 5,
        '6' => 6,
        '7' => 7,
        '8' => 8,
        '9' => 9,
        else => unreachable,
    };
}

fn printFs(fs: *const std.ArrayList(?usize)) void {
    for (fs.items) |value| {
        if (value == null) {
            std.debug.print(".", .{});
        } else {
            std.debug.print("{}", .{value.?});
        }
    }
    std.debug.print("\n", .{});
}
