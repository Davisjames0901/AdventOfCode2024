const std = @import("std");
const data = @embedFile("10.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = std.mem.tokenizeAny(u8, data, "\n");
    var trailHeads = std.ArrayList(Vec2).init(allocator);

    var lineNum: usize = 0;
    var lineLen: usize = 0;
    while(lines.next()) |line| : (lineNum += 1){
        if(lineLen == 0)
            lineLen = line.len;

        for(line, 0..) |char, i| {
            if(char == '0')
                try trailHeads.append(Vec2.init(i, lineNum));
        }
    }
    const mapSize = Vec2.init(lineLen, lineNum);

    var total: usize = 0;
    for(trailHeads.items) |head| {
        var neighbors = std.AutoArrayHashMap(Vec2, void).init(allocator);
        try populateValidNeighbors(&head, 1, &mapSize, &neighbors);
        for(2..10) |i| {
            var nextNeighbors = std.AutoArrayHashMap(Vec2, void).init(allocator);
            for(neighbors.keys()) |neighbor| {
                try populateValidNeighbors(&neighbor, i, &mapSize, &nextNeighbors);
            }
            neighbors.deinit();
            neighbors = nextNeighbors;
        }
        total += neighbors.keys().len;

        neighbors.clearRetainingCapacity();
    }
    std.debug.print("Answer: {}\n", .{total});
}

fn populateValidNeighbors(start: *const Vec2, targetInx: usize, mapSize: *const Vec2, buf: *std.AutoArrayHashMap(Vec2, void)) !void {
    const target = inxToChar(targetInx);

    const up = start.goUp();
    const upChar = up.getMapChar(mapSize);
    if(upChar == target)
        try buf.put(up,{});

    const down = start.goDown();
    const downChar = down.getMapChar(mapSize);
    if(downChar == target)
        try buf.put(down,{});

    const left = start.goLeft();
    const leftChar = left.getMapChar(mapSize);
    if(leftChar == target)
        try buf.put(left, {});

    const right = start.goRight();
    const rightChar = right.getMapChar(mapSize);
    if(rightChar == target)
        try buf.put(right, {});
}

fn inxToChar(i: usize) u8 {
    return switch (i) {
        0 => '0',
        1 => '1',
        2 => '2',
        3 => '3',
        4 => '4',
        5 => '5',
        6 => '6',
        7 => '7',
        8 => '8',
        9 => '9',
        else => unreachable,
    };
}


const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn goDown(self: *const Vec2) Vec2 {
        return .{ .x = self.x, .y = self.y + 1 };
    }

    pub fn goUp(self: *const Vec2) Vec2 {
        return .{ .x = self.x, .y = self.y - 1 };
    }
    pub fn goLeft(self: *const Vec2) Vec2 {
        return .{ .x = self.x - 1, .y = self.y };
    }

    pub fn goRight(self: *const Vec2) Vec2 {
        return .{ .x = self.x + 1, .y = self.y };
    }

    pub fn eq(self: *const Vec2, right: *const Vec2) bool {
        return self.x == right.x and self.y == right.y;
    }

    pub fn isOutside(self: *const Vec2, upper: *const Vec2) bool {
        if (self.x < 0 or self.x > upper.x - 1 or self.y < 0 or self.y > upper.y - 1) {
            return true;
        }
        return false;
    }

    pub fn getMapChar(self: *const Vec2, mapSize: *const Vec2) u8 {
        if(self.isOutside(mapSize))
            return 'A';
        return data[self.to1d(mapSize.x)];
    }

    pub fn to1d(self: *const Vec2, width: i32) usize {
        return @intCast((self.y * (width + 1)) + self.x);
    }

    pub fn init(x: anytype, y: anytype) Vec2 {
        return .{ .x = @intCast(x), .y = @intCast(y) };
    }
};