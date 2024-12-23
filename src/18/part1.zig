const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const mapSize: Vec2 = .{ .x = 70, .y = 70 };
    const iterations = 1024;

    var lines = std.mem.tokenize(u8, data, "\n,");
    var bytes = std.AutoHashMap(Vec2, void).init(allocator);

    for (0..iterations) |_| {
        try bytes.put(try Vec2.init(lines.next().?, lines.next().?), {});
    }

    var unvisited = std.AutoArrayHashMap(Vec2, Edge).init(allocator);
    var visited = std.AutoArrayHashMap(Vec2, Edge).init(allocator);

    try unvisited.put(.{ .x = 0, .y = 0 }, .{ .cost = 0, .previous = null });

    while (getCheapestVertex(&unvisited)) |vertex| {
        var next = vertex.pos.goUp();
        if (next.inside(&mapSize) and !bytes.contains(next) and !visited.contains(next))
            try unvisited.put(next, .{ .cost = vertex.edge.cost + 1, .previous = vertex.pos });

        next = vertex.pos.goDown();
        if (next.inside(&mapSize) and !bytes.contains(next) and !visited.contains(next))
            try unvisited.put(next, .{ .cost = vertex.edge.cost + 1, .previous = vertex.pos });

        next = vertex.pos.goLeft();
        if (next.inside(&mapSize) and !bytes.contains(next) and !visited.contains(next))
            try unvisited.put(next, .{ .cost = vertex.edge.cost + 1, .previous = vertex.pos });

        next = vertex.pos.goRight();
        if (next.inside(&mapSize) and !bytes.contains(next) and !visited.contains(next))
            try unvisited.put(next, .{ .cost = vertex.edge.cost + 1, .previous = vertex.pos });

        try visited.put(vertex.pos, vertex.edge);
        _ = unvisited.swapRemove(vertex.pos);
    }

    var path = std.AutoHashMap(Vec2, void).init(allocator);
    var next = visited.get(mapSize).?;
    while (next.previous) |key| {
        try path.put(key, {});
        next = visited.get(key).?;
    }

    drawMap(mapSize, &bytes, &path);

    std.debug.print("Answer: {}\n", .{visited.get(mapSize).?});
}

fn getCheapestVertex(unvisited: *const std.AutoArrayHashMap(Vec2, Edge)) ?struct { pos: Vec2, edge: Edge } {
    var best: ?Vec2 = null;
    var bestEdge: ?Edge = null;
    for (unvisited.keys()) |key| {
        const edge = unvisited.get(key).?;
        if (best == null or bestEdge.?.cost > edge.cost) {
            best = key;
            bestEdge = edge;
        }
    }

    if (best == null or bestEdge == null)
        return null;

    return .{ .pos = best.?, .edge = bestEdge.? };
}

const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn eq(self: *const Vec2, right: *const Vec2) bool {
        return self.x == right.x and self.y == right.y;
    }

    pub fn goUp(self: *const Vec2) Vec2 {
        return .{
            .x = self.x,
            .y = self.y - 1,
        };
    }
    pub fn goDown(self: *const Vec2) Vec2 {
        return .{
            .x = self.x,
            .y = self.y + 1,
        };
    }
    pub fn goLeft(self: *const Vec2) Vec2 {
        return .{
            .x = self.x - 1,
            .y = self.y,
        };
    }
    pub fn goRight(self: *const Vec2) Vec2 {
        return .{
            .x = self.x + 1,
            .y = self.y,
        };
    }

    pub fn init(x: []const u8, y: []const u8) !Vec2 {
        return .{ .x = try std.fmt.parseInt(i32, x, 10), .y = try std.fmt.parseInt(i32, y, 10) };
    }

    pub fn inside(self: *const Vec2, right: *const Vec2) bool {
        return self.x >= 0 and self.x <= right.x and self.y >= 0 and self.y <= right.y;
    }
};

const Edge = struct {
    cost: usize,
    previous: ?Vec2,
};

fn drawMap(mapSize: Vec2, bytes: *const std.AutoHashMap(Vec2, void), path: *const std.AutoHashMap(Vec2, void)) void {
    var writeHead: Vec2 = .{ .x = 0, .y = 0 };
    for (0..@intCast(mapSize.y + 1)) |y| {
        writeHead.y = @intCast(y);
        for (0..@intCast(mapSize.x + 1)) |x| {
            writeHead.x = @intCast(x);
            if (path.contains(writeHead)) {
                std.debug.print(".", .{});
            } else if (bytes.contains(writeHead)) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(" ", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}
