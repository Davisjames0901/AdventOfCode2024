const std = @import("std");
const data = @embedFile("3.input");
const ArrayList = std.ArrayList;

pub fn main() !void {
    var buffer = ArrayList(u8).init(std.heap.page_allocator);
    defer buffer.deinit();

    var do = true;
    var total: i64 = 0;
    for (data) |char| {
        try buffer.append(char);

        if (buffer.items[0] == 'm' and do) {
            const mult = doMult(&buffer);
            if (mult == MultError.Incomplete)
                continue;

            total += mult catch 0;
        } else if (buffer.items[0] == 'd') {
            switch (validateDoDont(&buffer)) {
                DoDontStatus.Do => do = true,
                DoDontStatus.Dont => do = false,
                DoDontStatus.Incomplete => continue,
                else => {},
            }
        }
        buffer.clearRetainingCapacity();
    }
    std.debug.print("Answer: {}\n", .{total});
}

fn doMult(buf: *ArrayList(u8)) !i32 {
    if (std.mem.startsWith(u8, "mul(", buf.items)) {
        return MultError.Incomplete;
    } else if (buf.items.len > 4 and std.mem.eql(u8, "mul(", buf.items[0..4])) {
        const slice = buf.items[4..];
        var firstNum = ArrayList(u8).init(std.heap.page_allocator);
        var secondNum = ArrayList(u8).init(std.heap.page_allocator);
        defer firstNum.deinit();
        defer secondNum.deinit();

        var seperator = false;
        for (slice) |char| {
            if (char == ',') {
                if (seperator or firstNum.items.len == 0)
                    return MultError.Error;
                seperator = true;
                continue;
            }
            if (char == ')') {
                if (firstNum.items.len == 0 or secondNum.items.len == 0)
                    return MultError.Error;
                const first = try std.fmt.parseInt(i32, firstNum.items, 10);
                const second = try std.fmt.parseInt(i32, secondNum.items, 10);
                return first * second;
            }
            if (std.ascii.isDigit(char)) {
                if (seperator) {
                    try secondNum.append(char);
                } else {
                    try firstNum.append(char);
                }
                continue;
            }
            return MultError.Error;
        }
        return MultError.Incomplete;
    }
    return MultError.Error;
}

fn validateDoDont(buf: *ArrayList(u8)) DoDontStatus {
    if (std.mem.eql(u8, buf.items, "don't()"))
        return DoDontStatus.Dont;
    if (std.mem.eql(u8, buf.items, "do()"))
        return DoDontStatus.Do;

    if (std.mem.startsWith(u8, "don't()", buf.items) or std.mem.startsWith(u8, "do()", buf.items))
        return DoDontStatus.Incomplete;

    std.debug.print("Invalid: {any}", .{buf.items});
    return DoDontStatus.Error;
}

const DoDontStatus = enum { Error, Incomplete, Do, Dont };
const MultError = error{ Error, Incomplete };
