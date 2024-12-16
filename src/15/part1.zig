const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var map = std.AutoArrayHashMap(Vec2, BlockType).init(allocator);
    var instructions = std.ArrayList(Direction).init(allocator);
    var robot: Vec2 = undefined;

    var y: usize = 0;
    var x: i32 = 0;
    for (data) |char| {
        const pos = Vec2.init(x, y);
        switch (char) {
            '@' => {
                robot = pos;
                try map.put(pos, BlockType.Air);
            },
            '#' => try map.put(pos, BlockType.Wall),
            'O' => try map.put(pos, BlockType.Box),
            '.' => try map.put(pos, BlockType.Air),
            '^' => try instructions.append(Direction.Up),
            'v' => try instructions.append(Direction.Down),
            '<' => try instructions.append(Direction.Left),
            '>' => try instructions.append(Direction.Right),
            '\n' => {
                y += 1;
                x = -1;
            },
            else => std.debug.print("Wtf is this??? {c}", .{char}),
        }
        x += 1;
    }

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
        if (blockType == BlockType.Box) {
            total += pos.getCoordinate();
        }
    }

    std.debug.print("Answer: {}", .{total});
}

fn tryMove(pos: *const Vec2, direction: *const Direction, map: *std.AutoArrayHashMap(Vec2, BlockType)) !bool {
    const cell = map.get(pos.*);
    return switch (cell.?) {
        BlockType.Wall => false,
        BlockType.Air => true,
        BlockType.Box => {
            const nextPos = pos.move(direction);
            if (try tryMove(&nextPos, direction, map)) {
                try map.put(pos.*, BlockType.Air);
                try map.put(nextPos, cell.?);
                return true;
            }
            return false;
        },
    };
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

const BlockType = enum { Box, Wall, Air };
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
                BlockType.Box => std.debug.print("O", .{}),
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