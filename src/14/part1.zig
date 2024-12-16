const std = @import("std");
const data = @embedFile("puzzle.input");

const MAP_SIZE: Vec2 = .{ .x = 101, .y = 103 };
const SIM_ITERATIONS = 100;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var robots = std.ArrayList(Robot).init(allocator);

    var lines = std.mem.tokenize(u8, data, "pv=, \n");
    while (lines.peek()) |_| {
        const position = try Vec2.init(lines.next().?, lines.next().?);
        const velocity = try Vec2.init(lines.next().?, lines.next().?);
        try robots.append(.{ .pos = position, .velocity = velocity });
    }
    //
    // printMap(&robots);
    // std.debug.print("\n", .{});
    for (0..SIM_ITERATIONS) |iter| {
        std.debug.print("ITERATION: {}\n", .{iter});
        for (0..robots.items.len) |i| {
            var robot = robots.items[i];
            robot.update();
            robots.items[i] = robot;
        }
        printMap(&robots);
        std.debug.print("\n", .{});
        std.time.sleep(1000000000);
    }

    printMap(&robots);

    const quadrantWidth = @divFloor(MAP_SIZE.x, 2);
    const quadrantHeight = @divFloor(MAP_SIZE.y, 2);

    const firstQuadrent = Box.init(0, 0, quadrantWidth, quadrantHeight);
    const secondQuadrent = Box.init(quadrantWidth + 1, 0, quadrantWidth, quadrantHeight);
    const thirdQuadrent =  Box.init(0, quadrantHeight + 1, quadrantWidth, quadrantHeight);
    const forthQuadrent = Box.init(quadrantWidth + 1, quadrantHeight + 1, quadrantWidth, quadrantHeight);

    // std.debug.print("1: {any}\n", .{firstQuadrent});
    // std.debug.print("Robot: {any}\n", .{robots.items[0].pos});
    // std.debug.print("2: {any}\n", .{secondQuadrent});
    // std.debug.print("3: {any}\n", .{thirdQuadrent});
    // std.debug.print("4: {any}\n", .{forthQuadrent});

    var one: u32 = 0;
    var two: u32 = 0;
    var three: u32 = 0;
    var four: u32 = 0;

    for (robots.items) |robot| {
        if (firstQuadrent.contains(&robot.pos)) {
            one += 1;
        } else if (secondQuadrent.contains(&robot.pos)) {
            two += 1;
        } else if (thirdQuadrent.contains(&robot.pos)) {
            three += 1;
        } else if (forthQuadrent.contains(&robot.pos)) {
            four += 1;
        }
    }

    std.debug.print("Answer: {}", .{one * two * three * four});
}

fn printMap(robots: *const std.ArrayList(Robot)) void {
    for (0..MAP_SIZE.y) |y| {
        for (0..MAP_SIZE.x) |x| {
            var count: i32 = 0;
            for(robots.items) |robot| {
                if(robot.pos.x == x and robot.pos.y == y)
                    count += 1;
            }
            if(count == 0) {
                std.debug.print(".", .{});
            } else {
                std.debug.print("{}", .{count});
            }
        }
        std.debug.print("\n", .{});
    }
}

const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(left: *const Vec2, right: *const Vec2) Vec2 {
        return .{ .x = left.x + right.x, .y = left.y + right.y };
    }

    pub fn init(x: []const u8, y: []const u8) !Vec2 {
        return .{ .x = try std.fmt.parseInt(i32, x, 10), .y = try std.fmt.parseInt(i32, y, 10) };
    }
};

const Robot = struct {
    pos: Vec2,
    velocity: Vec2,

    pub fn update(self: *Robot) void {
        self.pos = self.pos.add(&self.velocity);
        if (self.pos.x > MAP_SIZE.x - 1) {
            self.pos.x = self.pos.x - MAP_SIZE.x;
        } else if (self.pos.x < 0) {
            self.pos.x = self.pos.x + MAP_SIZE.x;
        }
        if (self.pos.y > MAP_SIZE.y - 1) {
            self.pos.y = self.pos.y - MAP_SIZE.y;
        } else if (self.pos.y < 0) {
            self.pos.y = self.pos.y + MAP_SIZE.y;
        }
    }
};

const Box = struct {
    x1: i32,
    y1: i32,
    x2: i32,
    y2: i32,

    pub fn contains(self: *const Box, point: *const Vec2) bool {
        if (point.x < self.x1 or point.x > self.x2){
            return false;
        }

        if (point.y < self.y1 or point.y > self.y2){
            return false;
        }

        return true;
    }

    pub fn init(x: i32, y: i32, width: i32, height: i32) Box {
        return .{
            .x1 = x,
            .y1 = y,
            .x2 = x + width - 1,
            .y2 = y + height - 1
        };
    }
};
