const std = @import("std");
const data = @embedFile("test.input");

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
        BlockType.BoxLeft => {
            if(direction.* == Direction.Left or direction.* == Direction.Right) {
                const next = pos.move(direction);
                if (try tryMove(&next, direction, map)) {
                    try map.put(pos.*, BlockType.Air);
                    try map.put(next, cell);
                    return true;
                }
                return false;
            }
            try tryMoveBoxUpDown(pos, &pos.move(&Direction.Right), direction, map);
        },
        BlockType.BoxRight => {
            const next = pos.move(direction);
            if(direction.* == Direction.Left or direction.* == Direction.Right) {
                if (try tryMove(&next, direction, map)) {
                    try map.put(pos.*, BlockType.Air);
                    try map.put(next, cell);
                    return true;
                }
                return false;
            }
            const left = pos.move(&Direction.Left);
            const nextLeft = left.move(direction);
            if(try tryMoveBoxUpDown(&nextLeft, &next, direction, map)) {
                try map.put(pos.*, BlockType.Air);
                try map.put(left.*, BlockType.Air);
                try map.put(next, cell);
                try map.put(nextLeft, BlockType.BoxLeft);
                return true;
            }
            return false;
        },
    };
}

fn tryMoveDouble(pos: *const Vec2, compliment: *const Vec2, direction: *const Direction, map: *std.AutoArrayHashMap(Vec2, BlockType)) !bool {
    const cell = map.get(pos.*);
    const complimentCell = map.get(compliment.*);
    if(cell == BlockType.Wall or complimentCell == BlockType.Wall)
        return false;
    if(cell == BlockType.Air and complimentCell == BlockType.Air)
        return true;
    if(cell == BlockType.Air and (complimentCell == BlockType.BoxLeft or complimentCell == BlockType.BoxRight))
        return try tryMove(compliment, direction, map);
    if(complimentCell == BlockType.Air and (cell == BlockType.BoxLeft or cell == BlockType.BoxRight))
        return try tryMove(pos, direction, map);
}

fn tryMoveBoxUpDown(left: *const Vec2, right: *const Vec2, direction: *const Direction, map: *std.AutoArrayHashMap(Vec2, BlockType)) !bool {
    const leftCell = map.get(left.*).?;
    const rightCell = map.get(right.*).?;

    const nextLeft = leftCell.move(direction);
    const nextRight = rightCell.move(direction);
    


    if(try tryMoveDouble(pos, compliment, direction, map)) {
        try map.put(pos.*, BlockType.Air);
        try map.put(compliment.*, BlockType.Air);
        try map.put(nextPos, cell);
        try map.put(nextCompliment, complimentCell);
        return true;
    }
    return false;
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