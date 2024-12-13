const std = @import("std");
const data = @embedFile("6test.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = std.mem.tokenizeAny(u8, data, "\n");
    var obsticals = std.ArrayList(Vec2).init(allocator);
    var guard: Guard = undefined;

    var lineNum: i32 = 0;
    var cols: ?i32 = null;
    while (lines.next()) |line| : (lineNum += 1) {
        if (cols == null)
            cols = @intCast(line.len);

        for (line, 0..) |char, i| {
            if (char == '#') {
                const obsPosition: Vec2 = .{ .x = @intCast(i), .y = lineNum };
                try obsticals.append(obsPosition);
                std.debug.print("Obstical at {any}\n", .{obsPosition});
            } else if (char == '^') {
                guard = try Guard.init(@intCast(i), lineNum, .{ .x = 0, .y = -1 }, allocator);
                std.debug.print("Guard starting at {any} moving {}\n", .{ guard.position, guard.direction });
            }
        }
    }
    const mapSize: Vec2 = .{ .x = cols.?, .y = lineNum };
    while (try guard.step(&obsticals, &mapSize)) {
        printMap(&mapSize, &guard, &obsticals);
        // for (0..@intCast(mapSize.y)) |line| {
        //     for (0..@intCast(mapSize.x)) |col| {
        //         if (line == guard.position.y and col == guard.position.x) {
        //             std.debug.print("0", .{});
        //             continue;
        //         }
        //         if (findObstical(col, line, &obsticals)) {
        //             std.debug.print("#", .{});
        //             continue;
        //         }
        //         const l: i32 = @intCast(line);
        //         const c: i32 = @intCast(col);
        //         const pos: Vec2 = .{ .x = c, .y = l };
        //         if (guard.path.contains(pos)) {
        //             std.debug.print("X", .{});
        //             continue;
        //         }

        //         std.debug.print(".", .{});
        //     }
        //     std.debug.print("\n", .{});
        // }
        // std.debug.print("\n\n", .{});
        // std.time.sleep(900000000);
    }

    std.debug.print("Unique Steps: {}\n", .{guard.path.count()});
}
fn printMap(mapSize: *const Vec2, guard: *const Guard, obsticals: *const std.ArrayList(Vec2)) void {
    for (0..@intCast(mapSize.y)) |line| {
        for (0..@intCast(mapSize.x)) |col| {
            const l: i32 = @intCast(line);
            const c: i32 = @intCast(col);
            const pos: Vec2 = .{ .x = c, .y = l };
            if (pos.x == guard.position.x and pos.y == guard.position.y) {
                std.debug.print("0", .{});
            } else if (findObstical(pos, obsticals)) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n\n", .{});
    std.time.sleep(900000000);
}

fn findObstical(pos: Vec2, obs: *const std.ArrayList(Vec2)) bool {
    for (obs.items) |ob| {
        if (ob.x == pos.x and ob.y == pos.y)
            return true;
    }
    return false;
}

const Guard = struct {
    position: Vec2,
    direction: Vec2,
    path: std.AutoHashMap(Vec2, void),

    pub fn init(x: i32, y: i32, direction: Vec2, alloc: std.mem.Allocator) !Guard {
        var path = std.AutoHashMap(Vec2, void).init(alloc);
        const position: Vec2 = .{ .x = x, .y = y };
        try path.put(position, {});

        return .{ .position = .{ .x = x, .y = y }, .direction = direction, .path = path };
    }

    //return false if step will be out of bounds
    pub fn step(self: *Guard, obs: *const std.ArrayList(Vec2), mapSize: *const Vec2) !bool {
        const nextPosition = self.position.add(&self.direction);
        if (nextPosition.isOutside(mapSize)) {
            return false;
        }
        for (obs.items) |ob| {
            if (nextPosition.eq(&ob)) {
                self.direction.rotateRight90();
                return true;
            }
        }
        self.position = nextPosition;

        try self.path.put(self.position, {});
        return true;
    }
};

const Obstical = struct {
    position: Vec2,

    pub fn init(x: i32, y: i32) Obstical {
        return .{ .position = .{ .x = x, .y = y } };
    }
};

const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(self: *const Vec2, right: *const Vec2) Vec2 {
        return .{ .x = self.x + right.x, .y = self.y + right.y };
    }

    pub fn eq(self: *const Vec2, right: *const Vec2) bool {
        return self.x == right.x and self.y == right.y;
    }
    pub fn rotateRight90(self: *Vec2) void {
        const tempX = self.x;
        self.x = self.y * -1;
        self.y = tempX;
    }

    pub fn isOutside(self: *const Vec2, upper: *const Vec2) bool {
        if (self.x < 0 or self.x > upper.x - 1 or self.y < 0 or self.y > upper.y - 1) {
            return true;
        }
        return false;
    }
};
