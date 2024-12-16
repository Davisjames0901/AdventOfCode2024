const std = @import("std");
const data = @embedFile("puzzle.input");

const MAP_SIZE: Vec2 = .{ .x = 101, .y = 103 };
const SIM_ITERATIONS = 60000;

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
        for (0..robots.items.len) |i| {
            var robot = robots.items[i];
            robot.update();
            robots.items[i] = robot;
        }
        if(try maybeTree(&robots)) {
            std.debug.print("TREE!: {}\n", .{iter + 1});
            printMap(&robots);
            std.debug.print("\n", .{});
        }
    }

    std.debug.print("Done.\n", .{});
}

//the bottom of the tree is flat probably??? Idk what its supposed to look like....
//I am not proud of this
fn maybeTree(robots: *const std.ArrayList(Robot)) !bool {
    var map = std.AutoHashMap(Vec2, void).init(robots.allocator);
    defer map.deinit();

    for (robots.items) |robot| {
        try map.put(robot.pos, {});
    }
    for(robots.items) |robot| {
        var next = robot.pos.moveLeft();
        if(!map.contains(next))
            continue;
        next = next.moveLeft();
        if(!map.contains(next))
            continue;
        next = next.moveLeft();
        if(!map.contains(next))
            continue;
        next = next.moveLeft();
        if(!map.contains(next))
            continue;
        next = next.moveLeft();
        if(!map.contains(next))
            continue;
        next = next.moveLeft();
        if(!map.contains(next))
            continue;
        next = next.moveLeft();
        if(!map.contains(next))
            continue;
        next = next.moveLeft();
        if(!map.contains(next))
            continue;
        return true;
    }
    return false;
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

    pub fn moveLeft(self: *const Vec2) Vec2 {
        return self.add(&.{.x = 1, .y = 0});
    }

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