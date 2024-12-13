const std = @import("std");
const data = @embedFile("6.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = std.mem.tokenizeAny(u8, data, "\n");
    var obsticals = std.AutoHashMap(Vec2, void).init(allocator);
    var guard: Guard = undefined;

    var lineNum: i32 = 0;
    var cols: ?i32 = null;
    while (lines.next()) |line| : (lineNum += 1) {
        if (cols == null)
            cols = @intCast(line.len);

        for (line, 0..) |char, i| {
            if (char == '#') {
                const obsPosition: Vec2 = .{ .x = @intCast(i), .y = lineNum };
                try obsticals.put(obsPosition, {});
            } else if (char == '^') {
                guard = try Guard.init(@intCast(i), lineNum, .{ .x = 0, .y = -1 }, allocator);
            }
        }
    }

    const mapSize: Vec2 = .{ .x = cols.?, .y = lineNum };
    while (true) {
        const action = guard.step(&obsticals, &mapSize);
        if (action == PathStatus.Complete) {
            break;
        } else if (action == PathStatus.CycleDetected) {
            std.debug.print("This shouldnt happen...", .{});
            return;
        }
    }

    const moves = try guard.getOrderedMoves();

    var seen = std.AutoHashMap(Vec2, void).init(allocator);
    var cycles: i32 = 0;
    for (moves[0 .. moves.len - 1], 1..) |move, next| {
        if (!isPositionValid(&moves[next], &obsticals, &seen))
            continue;
        guard.reset(&move);

        try seen.put(moves[next].position, {});
        try obsticals.put(moves[next].position, {});
        defer _ = obsticals.remove(moves[next].position);

        const status = sim: while (true) {
            const status = guard.step(&obsticals, &mapSize);
            if (status == PathStatus.NotComplete) {
                continue :sim;
            }
            break :sim status;
        };
        if (status == PathStatus.CycleDetected) {
            cycles += 1;
        }
        // printMap(&mapSize, &guard, &obsticals);
        // std.debug.print("^ {s}\n\n", .{@tagName(status)});
    }
    std.debug.print("Detected {} cycles, checked {} positions\n", .{ cycles, seen.count() });
}

fn isPositionValid(move: *const Movement, obs: *const std.AutoHashMap(Vec2, void), seen: *const std.AutoHashMap(Vec2, void)) bool {
    if (seen.contains(move.position))
        return false;
    return !obs.contains(move.position);
}

fn printMap(mapSize: *const Vec2, guard: *const Guard, obsticals: *const std.AutoHashMap(Vec2, void)) void {
    for (0..@intCast(mapSize.y)) |line| {
        for (0..@intCast(mapSize.x)) |col| {
            const l: i32 = @intCast(line);
            const c: i32 = @intCast(col);
            const pos: Vec2 = .{ .x = c, .y = l };
            if (pos.x == guard.original.position.x and pos.y == guard.original.position.y) {
                std.debug.print("S", .{});
            } else if (pos.x == guard.current.position.x and pos.y == guard.current.position.y) {
                std.debug.print("E", .{});
            } else if (obsticals.contains(pos)) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

const Guard = struct {
    current: Movement,
    original: Movement,
    path: std.AutoArrayHashMap(Movement, usize),

    pub fn init(x: i32, y: i32, direction: Vec2, alloc: std.mem.Allocator) !Guard {
        var path = std.AutoArrayHashMap(Movement, usize).init(alloc);
        const position: Vec2 = .{ .x = x, .y = y };
        const movement: Movement = .{ .position = position, .direction = direction };
        try path.put(movement, 0);
        return .{ .current = movement, .original = movement, .path = path };
    }

    pub fn reset(self: *Guard, movement: ?*const Movement) void {
        if (movement != null) {
            self.current = movement.?.*;
        } else {
            self.current = self.original;
        }

        self.path.clearRetainingCapacity();
    }

    pub fn getOrderedMoves(self: *const Guard) ![]Movement {
        const keys = self.path.keys();
        var orderedMoves: []Movement = try self.path.allocator.alloc(Movement, keys.len);
        for (keys) |key| {
            const inx = self.path.get(key).?;
            orderedMoves[inx] = key;
        }
        return orderedMoves;
    }

    pub fn step(self: *Guard, obs: *const std.AutoHashMap(Vec2, void), mapSize: *const Vec2) PathStatus {
        const nextMove = self.current.advance();

        if (nextMove.position.isOutside(mapSize))
            return PathStatus.Complete;

        if (obs.contains(nextMove.position)) {
            self.current = self.current.rotateRight90();
            return PathStatus.NotComplete;
        }

        if (self.path.contains(nextMove)) {
            return PathStatus.CycleDetected;
        }
        self.path.put(nextMove, self.path.count()) catch {};
        self.current = nextMove;
        return PathStatus.NotComplete;
    }
};

const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(self: *const Vec2, right: *const Vec2) Vec2 {
        return .{ .x = self.x + right.x, .y = self.y + right.y };
    }

    pub fn rotateRight90(self: *const Vec2) Vec2 {
        return .{ .x = self.y * -1, .y = self.x };
    }

    pub fn isOutside(self: *const Vec2, upper: *const Vec2) bool {
        if (self.x < 0 or self.x > upper.x - 1 or self.y < 0 or self.y > upper.y - 1) {
            return true;
        }
        return false;
    }
};

const Movement = struct {
    position: Vec2,
    direction: Vec2,
    pub fn advance(self: *const Movement) Movement {
        return .{ .position = self.position.add(&self.direction), .direction = self.direction };
    }

    pub fn rotateRight90(self: *const Movement) Movement {
        return .{ .position = self.position, .direction = self.direction.rotateRight90() };
    }
};

const PathStatus = enum { CycleDetected, NotComplete, Complete };
