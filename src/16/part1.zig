const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var unvisited = std.AutoArrayHashMap(Vec2, ?Edge).init(allocator);
    var visited = std.AutoArrayHashMap(Vec2, Edge).init(allocator);
    var end: Vec2 = undefined;

    var y: usize = 0;
    var x: i32 = 0;
    for (data) |char| {
        const pos = Vec2.init(x, y);
        switch (char) {
            '.' => try unvisited.put(pos, null),
            'S' => try unvisited.put(pos, .{ .cost = 0, .direction = Vec2.init(1, 0), .previous = null }),
            'E' => {
                end = pos;
                try unvisited.put(pos, null);
            },
            '\n' => {
                y += 1;
                x = -1;
            },
            else => {},
        }
        x += 1;
    }

    try visited.ensureTotalCapacity(visited.capacity());

    while (getCheapestVertex(&unvisited)) |key| {
        const edge = unvisited.get(key).?.?;

        const nextForward = key.add(&edge.direction);
        tryEstimate(&unvisited, key, nextForward, edge.direction, edge.cost + 1);

        const clockwize = edge.direction.rotateClockwise90();
        const nextClockwise = key.add(&clockwize);
        tryEstimate(&unvisited, key, nextClockwise, clockwize, edge.cost + 1001);

        const antiClockwize = edge.direction.rotateAntiClockwise90();
        const nextAntiClockwise = key.add(&antiClockwize);
        tryEstimate(&unvisited, key, nextAntiClockwise, antiClockwize, edge.cost + 1001);

        try visited.put(key, edge);
        _ = unvisited.swapRemove(key);
    }
    try drawMap(&visited, end);
    std.debug.print("Answer: {}", .{visited.get(end).?.cost});
}

fn tryEstimate(unvisited: *std.AutoArrayHashMap(Vec2, ?Edge), from: Vec2, next: Vec2, direction: Vec2, cost: usize) void {
    if (unvisited.get(next)) |current| {
        if (current == null or current.?.cost > cost)
            unvisited.putAssumeCapacity(next, .{ .cost = cost, .direction = direction, .previous = from });
    }
}

fn getCheapestVertex(unvisited: *std.AutoArrayHashMap(Vec2, ?Edge)) ?Vec2 {
    var min: ?Edge = null;
    var minKey: ?Vec2 = null;
    for (unvisited.keys()) |key| {
        const edge = unvisited.get(key).?;
        if (edge == null) {
            continue;
        }
        if (min == null or min.?.cost > edge.?.cost) {
            min = edge;
            minKey = key;
        }
    }
    return minKey;
}

const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(self: *const Vec2, right: *const Vec2) Vec2 {
        return .{ .x = self.x + right.x, .y = self.y + right.y };
    }

    pub fn eq(self: *const Vec2, right: *const Vec2) bool {
        return self.x == right.x and self.y == right.y;
    }

    pub fn rotateClockwise90(self: *const Vec2) Vec2 {
        return Vec2.init(self.y * -1, self.x);
    }

    pub fn rotateAntiClockwise90(self: *const Vec2) Vec2 {
        return Vec2.init(self.y, self.x * -1);
    }

    pub fn init(x: anytype, y: anytype) Vec2 {
        return .{ .x = @intCast(x), .y = @intCast(y) };
    }
    pub fn getChar(self: *const Vec2) u8 {
        if(self.x == 0) {
            if(self.y == -1) {
                return '^';
            } else {
                return 'v';
            }
        } else {
            if(self.x == -1) {
                return '<';
            } else {
                return '>';
            }
        }
    }
};

const Edge = struct { cost: usize, direction: Vec2, previous: ?Vec2 };

fn drawMap(map: *const std.AutoArrayHashMap(Vec2, Edge), end: Vec2) !void {
    const path = try getPath(map, end);
    var pos: Vec2 = .{ .x = 0, .y = 0 };
    for (data) |char| {
        switch (char) {
            '.' => {
                if(path.get(pos)) |edge| {
                    std.debug.print("{c}", .{edge.direction.getChar()});
                } else {
                    std.debug.print(" ", .{});
                }
            },
            'E' => std.debug.print("E", .{}),
            'S' => std.debug.print("S", .{}),
            '#' => std.debug.print("█", .{}),
            '\n' => {
                pos.y += 1;
                pos.x = -1;
                std.debug.print("\n", .{});
            },
            else => {},
        }
        pos.x += 1;
    }
    std.debug.print("\n", .{});
}

fn getPath(map: *const std.AutoArrayHashMap(Vec2, Edge), end: Vec2) !std.AutoArrayHashMap(Vec2, Edge) {
    var path = std.AutoArrayHashMap(Vec2, Edge).init(map.allocator);
    var next = map.get(end).?;
    var key = end;
    while(next.previous) |previous| {
        const edge = map.get(previous).?;
        try path.put(previous, edge);
        next = edge;
        key = previous;
    }
    return path;
}
