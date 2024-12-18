const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var map = std.AutoArrayHashMap(Vec2, BlockType).init(allocator);
    var runners = std.ArrayList(MazeRunner).init(allocator);

    var y: usize = 0;
    var x: i32 = 0;
    for (data) |char| {
        const pos = Vec2.init(x, y);
        switch (char) {
            '.' => try map.put(pos, BlockType.Air),
            '#' => try map.put(pos, BlockType.Wall),
            'S' => {
                try runners.append(MazeRunner.init(pos, Vec2.init(1, 0), &map));
                try map.put(pos, BlockType.Air);
            },
            'E' => try map.put(pos, BlockType.End),
            '\n' => {
                y += 1;
                x = -1;
            },
            else => std.debug.print("Wtf is this??? {c}\n", .{char}),
        }
        x += 1;
    }

    var cost: ?usize = 203784;
    while (true) {
        var runner = runners.popOrNull();
        if (runner == null)
            break;
        // drawMap(&map, &runner.?);
        // std.debug.print("\n\n\n", .{});
        // std.time.sleep(500000000);
        if (runner.?.standingOn == BlockType.End) {
            if (cost == null or cost.? > runner.?.cost){
                cost = runner.?.cost;
                std.debug.print("New cost: {?}", .{cost});
            }
        } else {
            try runner.?.stepAndAddPaths(&runners, cost);
        }
    }

    std.debug.print("Answer: {?}", .{cost});
}

const MazeRunner = struct {
    pos: Vec2,
    vel: Vec2,
    cost: usize,
    map: *const std.AutoArrayHashMap(Vec2, BlockType),
    visitedPaths: std.AutoHashMap(Vec2, void),
    standingOn: BlockType,

    fn stepAndAddPaths(self: *MazeRunner, runners: *std.ArrayList(MazeRunner), bestCost: ?usize) !void {
        if(bestCost != null and bestCost.? < self.cost)
            return;

        const nextForward = self.pos.add(&self.vel);

        const clockwize = self.vel.rotateClockwise90();
        const nextClockwise = self.pos.add(&clockwize);

        const antiClockwize = self.vel.rotateAntiClockwise90();
        const nextAntiClockwise = self.pos.add(&antiClockwize);
        if (!self.visitedPaths.contains(nextForward) and self.map.get(nextForward).? != BlockType.Wall)
            try runners.append(try self.with(nextForward, self.vel, self.cost + 1));
        if (!self.visitedPaths.contains(nextClockwise) and self.map.get(nextClockwise).? != BlockType.Wall)
            try runners.append(try self.with(nextClockwise, clockwize, self.cost + 1001));
        if (!self.visitedPaths.contains(nextAntiClockwise) and self.map.get(nextAntiClockwise).? != BlockType.Wall)
            try runners.append(try self.with(nextAntiClockwise, antiClockwize, self.cost + 1001));

        self.visitedPaths.deinit();
    }

    fn with(self: *const MazeRunner, pos: Vec2, vel: Vec2, cost: usize) !MazeRunner {
        var newPath = try self.visitedPaths.clone();
        try newPath.put(pos, {});
        return .{ .pos = pos, .vel = vel, .map = self.map, .cost = cost, .visitedPaths = newPath, .standingOn = self.map.get(pos).? };
    }

    fn init(pos: Vec2, vel: Vec2, map: *const std.AutoArrayHashMap(Vec2, BlockType)) MazeRunner {
        return .{ .pos = pos, .vel = vel, .map = map, .cost = 0, .visitedPaths = std.AutoHashMap(Vec2, void).init(map.allocator), .standingOn = BlockType.Air };
    }

    fn draw(self: *const MazeRunner) u8 {
        if (self.vel.x == 1) {
            return '>';
        }
        if (self.vel.x == -1) {
            return '<';
        }
        if (self.vel.y == 1) {
            return 'v';
        }
        return '^';
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

    pub fn rotateClockwise90(self: *const Vec2) Vec2 {
        return Vec2.init(self.y * -1, self.x);
    }

    pub fn rotateAntiClockwise90(self: *const Vec2) Vec2 {
        return Vec2.init(self.y, self.x * -1);
    }

    pub fn init(x: anytype, y: anytype) Vec2 {
        return .{ .x = @intCast(x), .y = @intCast(y) };
    }
};

const BlockType = enum { Wall, Air, End };

fn drawMap(map: *const std.AutoArrayHashMap(Vec2, BlockType), runner: *const MazeRunner) void {
    var vec: Vec2 = .{ .x = 0, .y = 0 };
    var notFound = false;
    while (true) {
        if (map.get(vec)) |block| {
            notFound = false;
            switch (block) {
                BlockType.Wall => std.debug.print("█", .{}),
                BlockType.Air => {
                    if (vec.eq(&runner.pos)) {
                        std.debug.print("{c}", .{runner.draw()});
                    } else {
                        std.debug.print(" ", .{});
                    }
                },
                BlockType.End => std.debug.print("E", .{}),
            }
            vec.x += 1;
        } else if (notFound) {
            std.debug.print("\n", .{});
            break;
        } else {
            std.debug.print("\n", .{});
            vec.x = 0;
            vec.y += 1;
            notFound = true;
        }
    }
}
