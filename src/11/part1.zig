const std = @import("std");
const data = @embedFile("test.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tokens = std.mem.tokenize(u8, data, " ");

    var stones = std.ArrayList(u64).init(allocator);
    while(tokens.next()) |stone|{
        const num = try std.fmt.parseInt(u64, stone, 10);
        try stones.append(num);
    }

    for(0..7) |i| {
        std.debug.print("Blink: {}\n", .{i});
        const nextStones = try applyRules(&stones);
        stones.deinit();
        stones = nextStones;
    }

    std.debug.print("Answer: {}", .{stones.items.len});
}

fn applyRules(stones: *std.ArrayList(u64)) !std.ArrayList(u64) {
    var nextStones = std.ArrayList(u64).init(stones.allocator);
    for(stones.items) |stone| {
        if(stone == 0){
            try nextStones.append(1);
            continue;
        }

        const len = std.math.log_int(u64, 10, stone) + 1;
        if(len % 2 == 0){
            const half = len / 2;
            const pow = std.math.pow(u64, 10, half);
            const firstNum = @divFloor(stone, pow);
            const secondNum = stone - (firstNum * pow);
            try nextStones.append(firstNum);
            try nextStones.append(secondNum);
            continue;
        }
        const mult = stone * 2024;
        try nextStones.append(mult);
    }

    return nextStones;
}

