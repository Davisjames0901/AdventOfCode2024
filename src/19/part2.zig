const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var towels = std.ArrayList([]const u8).init(allocator);
    var lines = std.mem.tokenize(u8, data, "\n");
    var towelTokens = std.mem.tokenizeAny(u8, lines.next().?, ", ");
    var memo = std.StringArrayHashMap(usize).init(allocator);

    while (towelTokens.next()) |towel| {
        try towels.append(towel);
    }

    for (towels.items) |towel| {
        _ = try match(towel, &towels, &memo);
    }

    var solveCount: usize = 0;
    var i: usize = 0;
    while (lines.next()) |input| : (i += 1) {
        const numSolutions = try match(input, &towels, &memo);
        solveCount += numSolutions;
    }

    std.debug.print("Answer: {} in {}\n", .{solveCount});
}

fn match(line: []const u8, towels: *std.ArrayList([]const u8), memo: *std.StringArrayHashMap(usize)) !usize {
    if (memo.get(line)) |solutions|
        return solutions;

    var solutions: usize = 0;
    for (towels.items) |towel| {
        if (!std.mem.startsWith(u8, line, towel))
            continue;

        if (towel.len == line.len)
            solutions += 1;

        solutions += try match(line[towel.len..], towels, memo);
    }
    try memo.put(line, solutions);
    return solutions;
}

fn lessThan(_: void, a: []const u8, b: []const u8) bool {
    return a.len < b.len;
}
