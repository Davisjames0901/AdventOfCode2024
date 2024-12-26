const std = @import("std");
const data = @embedFile("test.input");

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

    var relationships = std.StringArrayHashMap(void).init(allocator);
    for (computerLookup.keys()) |first| {
        const firstConnections = computerLookup.get(first).?;
        std.debug.print("{s} =>", .{first});
        for(firstConnections.keys()) |key| {
            std.debug.print(" {s}", .{key});
        }
        std.debug.print("\n", .{});

        if(first[0] != 't')
            continue;

        for(firstConnections.keys()) |key| {
            var relationship = std.ArrayList([]const u8).init(allocator);
            defer relationship.deinit();
            try relationship.append(first);
            try relationship.append(key);

            for(firstConnections.keys()) |inner| {
                const innerConnections =  computerLookup.get(inner).?;
                if(innerConnections.contains(key)) {
                    try relationship.append(inner);
                }
            }

            std.sort.insertion([]const u8, relationship.items, {}, compareStrings);
            var relationshipKey = try allocator.alloc(u8, relationship.items.len * 2);
            var i:usize = 0;
            for(relationship.items) |r| {
                for(r) |c| {
                    relationshipKey[i] = c;
                    i += 1;
                }
            }
            try relationships.put(relationshipKey, {});
        }
    }

    var best: ?[]const u8 = null;
    for(relationships.keys()) |key| {
        if(best == null or best.?.len < key.len) {
            best = key;
        }
    }

    std.debug.print("Answer: {s}\n", .{best.?});
}

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}
