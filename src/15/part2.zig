const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var map = std.AutoArrayHashMap(Vec2, BlockType).init(allocator);
    var instructions = std.ArrayList(Direction).init(allocator);
    var robot: Vec2 = undefined;

    var filePos = Vec2.init(0, 0);
    for (data) |char| {
        switch (char) {
            '@' => {
                robot = filePos;
                try map.put(filePos, BlockType.Air);
                filePos.x += 1;
                try map.put(filePos, BlockType.Air);
            },
            '#' => {
                try map.put(filePos, BlockType.Wall);
                filePos.x += 1;
                try map.put(filePos, BlockType.Wall);
            },
            'O' => {
                try map.put(filePos, BlockType.BoxLeft);
                filePos.x += 1;
                try map.put(filePos, BlockType.BoxRight);

            },
            '.' => {
                try map.put(filePos, BlockType.Air);
                filePos.x += 1;
                try map.put(filePos, BlockType.Air);
            },
            '^' => try instructions.append(Direction.Up),
            'v' => try instructions.append(Direction.Down),
            '<' => try instructions.append(Direction.Left),
            '>' => try instructions.append(Direction.Right),
            '\n' => {
                filePos.y += 1;
                filePos.x = -1;
            },
            else => std.debug.print("Wtf is this??? {c}", .{char}),
        }
        filePos.x += 1;
    }
    drawMap(&map, robot);

    for (instructions.items) |instruction| {
        const nextRobot = robot.move(&instruction);
        // drawMap(&map, robot);
        // std.debug.print("Go {}\n", .{instruction});
        if (try tryMove(&nextRobot, &instruction, &map))
            robot = nextRobot;
    }

    var total: i32 = 0;
    for (map.keys()) |pos| {
        const blockType = map.get(pos).?;
        if (blockType == BlockType.BoxLeft) {
            total += pos.getCoordinate();
        }
    }

    std.debug.print("Answer: {}", .{total});
}

fn tryMove(pos: *const Vec2, direction: *const Direction, map: *std.AutoArrayHashMap(Vec2, BlockType)) !bool {
    const cell = map.get(pos.*).?;
    return switch (cell) {
        BlockType.Wall => false,
        BlockType.Air => true,
        BlockType.BoxLeft, BlockType.BoxRight => {
            const next = pos.move(direction);
            if(direction.* == Direction.Left or direction.* == Direction.Right) {
                if (try tryMove(&next, direction, map)) {
                    try map.put(pos.*, BlockType.Air);
                    try map.put(next, cell);
                    return true;
                }
                return false;
            }
            var compliment: Vec2 = undefined;
            var complimentType: BlockType = undefined;
            var nextCompliment: Vec2 = undefined;
            if(cell == BlockType.BoxLeft) {
                compliment = pos.move(&Direction.Right);
                complimentType = BlockType.BoxRight;
            } else {
                compliment = pos.move(&Direction.Left);
                complimentType = BlockType.BoxLeft;
            }
            nextCompliment = compliment.move(direction);

            var nextPositions = std.AutoArrayHashMap(Vec2, void).init(map.allocator);
            defer nextPositions.deinit();

            try nextPositions.put(pos.*, {});
            try nextPositions.put(compliment, {});

            if(try tryMoveMany(&nextPositions, direction, map)) {
                try map.put(pos.*, BlockType.Air);
                try map.put(compliment, BlockType.Air);
                try map.put(next, cell);
                try map.put(nextCompliment, complimentType);

                return true;
            }
            return false;
        }
    };
}

fn tryMoveMany(positions: *const std.AutoArrayHashMap(Vec2, void), direction: *const Direction, map: *std.AutoArrayHashMap(Vec2, BlockType)) !bool {
    if(positions.count() == 0)
        return true;

    var nextPositions = std.AutoArrayHashMap(Vec2, void).init(positions.allocator);
    defer nextPositions.deinit();

    for(positions.keys()) |pos| {
        const next = pos.move(direction);
        const cell = map.get(next).?;
        if(cell == BlockType.Wall)
            return false;
        if(cell == BlockType.BoxLeft){
            try nextPositions.put(next, {});
            try nextPositions.put(next.move(&Direction.Right), {});
        } else if(cell == BlockType.BoxRight){
            try nextPositions.put(next, {});
            try nextPositions.put(next.move(&Direction.Left), {});
        }
    }

    if(!try tryMoveMany(&nextPositions, direction, map))
        return false;

    for(positions.keys()) |pos| {
        const next = pos.move(direction);
        const cell = map.get(pos).?;
        try map.put(pos, BlockType.Air);
        try map.put(next, cell);
    }
    return true;
}


const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn move(self: *const Vec2, direction: *const Direction) Vec2 {
        return switch (direction.*) {
            Direction.Up => .{ .x = self.x, .y = self.y - 1 },
            Direction.Down => .{ .x = self.x, .y = self.y + 1 },
            Direction.Left => .{ .x = self.x - 1, .y = self.y },
            Direction.Right => .{ .x = self.x + 1, .y = self.y },
        };
    }

    pub fn getCoordinate(self: *const Vec2) i32 {
        return (self.y * 100) + self.x;
    }

    pub fn eq(self: *const Vec2, right: *const Vec2) bool {
        return self.x == right.x and self.y == right.y;
    }

    pub fn init(x: anytype, y: anytype) Vec2 {
        return .{ .x = @intCast(x), .y = @intCast(y) };
    }
};

const BlockType = enum { BoxLeft, BoxRight, Wall, Air };
const Direction = enum { Up, Down, Left, Right };

fn drawMap(map: *const std.AutoArrayHashMap(Vec2, BlockType), robot: Vec2) void {
    var vec: Vec2 = .{ .x = 0, .y = 0 };
    var notFound = false;
    while (true) {
        if (map.get(vec)) |block| {
            notFound = false;
            switch (block) {
                BlockType.Wall => std.debug.print("#", .{}),
                BlockType.Air => {
                    if (vec.eq(&robot)) {
                        std.debug.print("@", .{});
                    } else {
                        std.debug.print(".", .{});
                    }
                },
                BlockType.BoxLeft => std.debug.print("[", .{}),
                BlockType.BoxRight => std.debug.print("]", .{}),
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