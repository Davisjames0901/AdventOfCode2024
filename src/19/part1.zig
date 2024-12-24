const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    const tsStart = std.time.microTimestamp();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var towels = std.ArrayList([]const u8).init(allocator);
    var lines = std.mem.tokenize(u8, data, "\n");
    var towelTokens = std.mem.tokenizeAny(u8, lines.next().?, ", ");
    var memo = std.StringHashMap(bool).init(allocator);

    while (towelTokens.next()) |towel| {
        try towels.append(towel);
        try memo.put(towel, true);
    }

    var solveCount: usize = 0;
    var i: usize = 0;
    while (lines.next()) |input| : (i += 1) {
        if (try match(input, &towels, &memo))
            solveCount += 1;
    }
    const tsEnd = std.time.microTimestamp();
    std.debug.print("Answer: {} in {}\n", .{solveCount, tsEnd - tsStart});
}

fn match(line: []const u8, towels: *std.ArrayList([]const u8), memo: *std.StringHashMap(bool)) !bool {
    if (memo.get(line)) |solvable|
        return solvable;

    for (towels.items) |towel| {
        if (!std.mem.startsWith(u8, line, towel))
            continue;

        if (try match(line[towel.len..], towels, memo)) {
            try memo.put(line, true);
            return true;
        }
    }
    try memo.put(line, false);
    return false;
}