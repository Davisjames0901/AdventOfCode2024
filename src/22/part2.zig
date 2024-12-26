const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var patternLookup = std.StringArrayHashMap(void).init(allocator);
    var monkeyLookups = std.ArrayList(struct {start: []const u8, sells: std.StringArrayHashMap(i64)}).init(allocator);

    var tokens = std.mem.tokenizeAny(u8, data, "\n");
    var total: i64 = 0;
    while(tokens.next()) |price| {
        var start = try std.fmt.parseInt(i64, price, 10);
        var lastPrice = @mod(start, 10);
        var buffer = std.ArrayList(u8).init(allocator);
        var monkeyLookup = std.StringArrayHashMap(i64).init(allocator);

        for(0..2000) |_| {
            start = next(start);
            const currentPrice = @mod(start, 10);
            const change = lastPrice - currentPrice;
            try buffer.append(@intCast(change + 40));
            if(buffer.items.len >= 4) {
                var key = try allocator.alloc(u8, 4);
                for(buffer.items[buffer.items.len - 4..buffer.items.len], 0..) |char, i| {
                    key[i] = char;
                }
                if(!monkeyLookup.contains(key)) {
                    try monkeyLookup.put(key, currentPrice);
                    try patternLookup.put(key, {});
                }
            }
            lastPrice = currentPrice;
        }
        try monkeyLookups.append(.{.start = price, .sells = monkeyLookup});
        total += start;
    }

    var maxSeq: ?[]const u8 = null;
    var maxBananas: ?i64 = null;

    for (patternLookup.keys()) |key| {
        var bananas: i64 = 0;
        for(monkeyLookups.items) |monkey| {
            if(monkey.sells.get(key)) |val| {
                bananas += val;
            }
        }
        if(maxSeq == null or maxBananas.? < bananas){
            maxSeq = key;
            maxBananas = bananas;
        }

    }

    for(monkeyLookups.items) |monkey| {
        if(monkey.sells.get(maxSeq.?)) |val| {
            std.debug.print("{s} Monkey gives: {}\n", .{monkey.start, val});
        } else {
            std.debug.print("{s} Monkey doesnt sell\n", .{monkey.start});
        }
    }
    std.debug.print("Count: {?}, Seq: {any}\n", .{maxBananas, maxSeq});
}

fn next(start: i64) i64 {
    var part = @mod(start ^ (start * 64), 16777216);
    part = @mod(part ^ @divFloor(part, 32), 16777216);
    return @mod(part ^ (part * 2048), 16777216);
}