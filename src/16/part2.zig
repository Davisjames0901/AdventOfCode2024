const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var unvisited = std.AutoArrayHashMap(Vertex, Edge).init(allocator);
    var visited = std.AutoArrayHashMap(Vertex, Edge).init(allocator);
    var map = std.AutoHashMap(Vec2, void).init(allocator);
    var end: Vec2 = undefined;

    var y: usize = 0;
    var x: i32 = 0;
    for (data) |char| {
        const pos = Vec2.init(x, y);
        switch (char) {
            '.' => try map.put(pos, {}),
            'S' => try unvisited.put(.{ .pos = pos, .vel = Vec2.init(1, 0) }, .{ .cost = 0, .previous = std.ArrayList(Vertex).init(allocator) }),
            'E' => {
                end = pos;
                try map.put(pos, {});
            },
            '\n' => {
                y += 1;
                x = -1;
            },
            else => {},
        }
        x += 1;
    }

    var paths = std.AutoHashMap(Vec2, void).init(allocator);
    var endVertex: ?Vertex = null;
    while (getCheapestVertex(&unvisited)) |key| {
        const edge = unvisited.get(key).?;
        if (key.pos.eq(&end)) {
            if (endVertex == null)
                endVertex = key;
        }

        const nextForward = key.pos.add(&key.vel);
        if (map.contains(nextForward))
            try estimate(&unvisited, &visited, key, .{ .pos = nextForward, .vel = key.vel }, edge.cost + 1);

        const clockwise = key.vel.rotateClockwise90();
        const nextClockwise = key.pos.add(&clockwise);
        if (map.contains(nextClockwise))
            try estimate(&unvisited, &visited, key, .{ .pos = nextClockwise, .vel = clockwise }, edge.cost + 1001);

        const antiClockwise = key.vel.rotateAntiClockwise90();
        const nextAntiClockwise = key.pos.add(&antiClockwise);
        if (map.contains(nextAntiClockwise))
            try estimate(&unvisited, &visited, key, .{ .pos = nextAntiClockwise, .vel = antiClockwise }, edge.cost + 1001);

        try visited.put(key, edge);
        _ = unvisited.swapRemove(key);
    }

    try updatePaths(&visited, &paths, endVertex.?);

    drawMap(&paths);
    std.debug.print("Answer: {?}\n", .{paths.count()});
}

fn estimate(unvisited: *std.AutoArrayHashMap(Vertex, Edge), visited: *std.AutoArrayHashMap(Vertex, Edge), from: Vertex, next: Vertex, cost: usize) !void {
    if(visited.contains(next))
        return;

    var estimated = unvisited.get(next);
    if (estimated == null or estimated.?.cost > cost) {
        try unvisited.put(next, try Edge.init(cost, from, unvisited.allocator));
    } else if (estimated.?.cost == cost) {
        try estimated.?.previous.append(from);
        try unvisited.put(next, estimated.?);
    }
}

fn getCheapestVertex(unvisited: *std.AutoArrayHashMap(Vertex, Edge)) ?Vertex {
    var min: ?Edge = null;
    var minKey: ?Vertex = null;
    for (unvisited.keys()) |key| {
        const edge = unvisited.get(key).?;
        if (min == null or min.?.cost > edge.cost) {
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
        if (self.x == 0) {
            if (self.y == -1) {
                return '^';
            } else {
                return 'v';
            }
        } else {
            if (self.x == -1) {
                return '<';
            } else {
                return '>';
            }
        }
    }
};

const Edge = struct {
    cost: usize,
    previous: std.ArrayList(Vertex),
    fn init(cost: usize, prev: Vertex, alloc: std.mem.Allocator) !Edge {
        var arr = std.ArrayList(Vertex).init(alloc);
        try arr.append(prev);

        return .{ .cost = cost, .previous = arr };
    }
};
const Vertex = struct { pos: Vec2, vel: Vec2 };

fn getBestEnd(map: *const std.AutoArrayHashMap(Vertex, Edge), end: Vec2) struct { Vertex, usize } {
    var bestEnd: ?Vertex = null;
    var bestCost: ?usize = null;
    for (map.keys()) |key| {
        if (key.pos.eq(&end)) {
            const edge = map.get(key).?;
            if (bestEnd == null or bestCost.? > edge.cost) {
                bestEnd = key;
                bestCost = edge.cost;
            }
        }
    }
    return .{ bestEnd.?, bestCost.? };
}

fn updatePaths(map: *const std.AutoArrayHashMap(Vertex, Edge), paths: *std.AutoHashMap(Vec2, void), end: Vertex) !void {
    var next = map.get(end).?;
    try paths.put(end.pos, {});
    std.debug.print("{any}: Count: {}\n", .{ end, next.previous.items.len });
    while (next.previous.popOrNull()) |previous| {
        try updatePaths(map, paths, previous);
    }
}

fn drawMap(paths: *const std.AutoHashMap(Vec2, void)) void {
    var pos: Vec2 = .{ .x = 0, .y = 0 };
    for (data) |char| {
        switch (char) {
            '.' => {
                if (paths.contains(pos)) {
                    std.debug.print("#", .{});
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
