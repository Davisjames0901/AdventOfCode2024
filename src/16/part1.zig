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
            'S' => try unvisited.put(.{ .pos = pos, .vel = Vec2.init(0, -1) }, .{ .cost = 0, .previous = null }),
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

    try visited.ensureTotalCapacity(map.capacity());

    var bestEnd: ?Vertex = null;
    var endCost: ?usize = null;
    while (getCheapestVertex(&unvisited)) |key| {
        const edge = unvisited.get(key).?;
        if(key.pos.eq(&end)) {
            bestEnd = key;
            endCost = edge.cost;
            try visited.put(key, edge);
            std.debug.print("Done. {}", .{edge.cost});
            break;
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

    if(bestEnd == null){
        std.debug.print("Unroutable.\n", .{});
        return;
    }
    try drawMap(&visited, bestEnd.?);
    std.debug.print("Answer: {?}", .{endCost});
}

fn estimate(unvisited: *std.AutoArrayHashMap(Vertex, Edge), visited: *std.AutoArrayHashMap(Vertex, Edge), from: Vertex, next: Vertex, cost: usize) !void {
    if(visited.contains(next))
        return;
    const estimated = unvisited.get(next);
    if (estimated == null or estimated.?.cost >= cost) {
        try unvisited.put(next, .{ .cost = cost, .previous = from });
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

const Edge = struct { cost: usize, previous: ?Vertex };
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
fn drawMap(map: *const std.AutoArrayHashMap(Vertex, Edge), end: Vertex) !void {
    const path = try getPath(map, end);
    var pos: Vec2 = .{ .x = 0, .y = 0 };
    for (data) |char| {
        switch (char) {
            '.' => {
                if (path.get(pos)) |dir| {
                    std.debug.print("{c}", .{dir.getChar()});
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

fn getPath(map: *const std.AutoArrayHashMap(Vertex, Edge), end: Vertex) !std.AutoArrayHashMap(Vec2, Vec2) {
    var path = std.AutoArrayHashMap(Vec2, Vec2).init(map.allocator);
    var next = map.get(end).?;
    while (next.previous) |previous| {
        const edge = map.get(previous).?;
        try path.put(previous.pos, previous.vel);
        next = edge;
    }
    return path;
}
