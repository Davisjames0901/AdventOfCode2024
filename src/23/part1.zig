const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = std.mem.tokenizeAny(u8, data, "-\n");
    var computerLookup = std.StringArrayHashMap(std.StringArrayHashMap(void)).init(allocator);
    while (tokens.peek()) |_| {
        const one = tokens.next().?;
        const two = tokens.next().?;
        if (computerLookup.contains(one)) {
            var connections = computerLookup.get(one).?;
            try connections.put(two, {});
            try computerLookup.put(one, connections);
        } else {
            var list = std.StringArrayHashMap(void).init(allocator);
            try list.put(two, {});
            try computerLookup.put(one, list);
        }

        if (computerLookup.contains(two)) {
            var connections = computerLookup.get(two).?;
            try connections.put(one, {});
            try computerLookup.put(two, connections);
        } else {
            var list = std.StringArrayHashMap(void).init(allocator);
            try list.put(one, {});
            try computerLookup.put(two, list);
        }
    }

    var relationships = std.StringHashMap(void).init(allocator);
    for (computerLookup.keys()) |first| {
        const firstConnections = computerLookup.get(first).?;
        std.debug.print("{s} =>", .{first});
        for(firstConnections.keys()) |key| {
            std.debug.print(" {s}", .{key});
        }
        std.debug.print("\n", .{});

        if(first[0] != 't')
            continue;

        var innerCount: usize = 0;
        for(firstConnections.keys()) |key| {
            for(firstConnections.keys()) |inner| {
                const innerConnections =  computerLookup.get(inner).?;
                if(innerConnections.contains(key)) {
                    var relationship = [_][]const u8{
                        first,
                        key,
                        inner
                    };
                    std.sort.insertion([]const u8, &relationship, {}, compareStrings);
                    var relationshipKey = try allocator.alloc(u8, 6);
                    var i:usize = 0;
                    for(relationship) |r| {
                        for(r) |c| {
                            relationshipKey[i] = c;
                            i += 1;
                        }
                    }
                    try relationships.put(relationshipKey, {});
                    innerCount += 1;
                }
            }
        }
        innerCount = @divFloor(innerCount, 2);
        if(innerCount != 0)
            std.debug.print("got: {}\n", .{innerCount});
    }

    std.debug.print("Answer: {}\n", .{relationships.count()});
}

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}
