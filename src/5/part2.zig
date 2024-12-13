const std = @import("std");
const data = @embedFile("5.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = std.mem.tokenizeAny(u8, data, "\n");
    var orderLookup = std.AutoHashMap(i32, std.ArrayList(i32)).init(allocator);

    var update = std.ArrayList(i32).init(allocator);
    var visitedLookup = std.AutoHashMap(i32, bool).init(allocator);

    var total: i32 = 0;
    while (tokens.next()) |rule| {
        if (rule[2] == '|') {
            try parsePair(rule, &orderLookup, allocator);
            continue;
        }
        try parseUpdate(rule, &update);
        std.debug.print("Update: {any}\n", .{update.items});
        try populateLookup(&update, &orderLookup, &visitedLookup);

        total += try orderAndGetMiddle(&update, &orderLookup);
    }

    std.debug.print("Answer: {}\n", .{total});
}

fn parsePair(line: []const u8, lookup: *std.AutoHashMap(i32, std.ArrayList(i32)), allocator: std.mem.Allocator) !void {
    const seperator = std.mem.indexOf(u8, line, "|") orelse return std.fmt.ParseIntError.InvalidCharacter;
    const first = try std.fmt.parseInt(i32, line[0..seperator], 10);
    const second = try std.fmt.parseInt(i32, line[seperator + 1 .. line.len], 10);
    if (!lookup.contains(second)) {
        var list = std.ArrayList(i32).init(allocator);
        try list.append(first);
        try lookup.put(second, list);
        return;
    }
    var list = lookup.getPtr(second).?;
    try list.append(first);
}

fn parseUpdate(rule: []const u8, update: *std.ArrayList(i32)) !void {
    update.clearRetainingCapacity();
    var buf = std.ArrayList(u8).init(std.heap.page_allocator);
    defer buf.deinit();
    for (rule) |char| {
        if (std.ascii.isDigit(char)) {
            try buf.append(char);
        } else {
            const page = try std.fmt.parseInt(i32, buf.items, 10);
            try update.append(page);
            buf.clearRetainingCapacity();
        }
    }
    const page = try std.fmt.parseInt(i32, buf.items, 10);
    try update.append(page);
}

fn validate(list: *const std.ArrayList(i32), orderLookup: *const std.AutoHashMap(i32, std.ArrayList(i32))) !?Swap {
    var visited = std.AutoHashMap(i32, void).init(list.allocator);
    defer visited.deinit();

    for (list.items, 0..) |page, i| {
        const prerequisites = orderLookup.get(page);
        try visited.put(page, {});
        if (prerequisites == null)
            continue;
        for (prerequisites.?.items) |prerequisite| {
            const inx = array_indexOf(i32, list.items, prerequisite);
            if (inx != null and !visited.contains(prerequisite)) {
                return .{ .a = i, .b = inx.? };
            }
        }
    }
    return null;
}

fn populateLookup(list: *const std.ArrayList(i32), orderLookup: *const std.AutoHashMap(i32, std.ArrayList(i32)), lookup: *std.AutoHashMap(i32, bool)) !void {
    lookup.clearRetainingCapacity();
    for (list.items) |item| {
        if (!orderLookup.contains(item))
            continue;
        for (orderLookup.get(item).?.items) |prereq| {
            if (!array_contains(i32, list.items, prereq))
                continue;
            try lookup.put(prereq, false);
        }
    }
}

fn array_contains(comptime T: type, haystack: []T, needle: T) bool {
    for (haystack) |element|
        if (element == needle)
            return true;
    return false;
}
fn array_indexOf(comptime T: type, haystack: []T, needle: T) ?usize {
    for (haystack, 0..) |element, i|
        if (element == needle)
            return i;
    return null;
}

fn orderAndGetMiddle(update: *std.ArrayList(i32), orderLookup: *const std.AutoHashMap(i32, std.ArrayList(i32))) !i32 {
    var counter: usize = 0;
    while (counter < 1000) : (counter += 1) {
        const result = try validate(update, orderLookup);
        if (result == null) {
            if (counter == 0)
                return 0;
            const middle = update.items[update.items.len / 2];
            std.debug.print("\tOrdered: {any}, Middle: {}\n", .{ update.items, middle });
            return middle;
        }
        const tmp = update.items[result.?.a];
        update.items[result.?.a] = update.items[result.?.b];
        update.items[result.?.b] = tmp;
    }
    std.debug.print("MAX ITER!\n", .{});
    return 0;
}

const Swap = struct { a: usize, b: usize };
