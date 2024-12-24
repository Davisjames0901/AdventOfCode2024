const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var visited = std.AutoArrayHashMap(Vec2, Edge).init(allocator);
    var path = std.AutoHashMap(Vec2, void).init(allocator);
    var end: Vec2 = undefined;
    var start: Vec2 = undefined;

    var pos: Vec2 = .{ .x = 0, .y = 0 };
    for (data) |char| {
        switch (char) {
            '.' => try path.put(pos, {}),
            'S' => {
                start = pos;
                try path.put(pos, {});
            },
            'E' => {
                end = pos;
                try path.put(pos, {});
            },
            '\n' => {
                pos.y += 1;
                pos.x = -1;
            },
            else => {},
        }
        pos.x += 1;
    }

    try visited.ensureTotalCapacity(path.capacity());

    var next: ?Vec2 = start;
    var step: usize = 0;
    while (next) |current| : (step += 1) {
        next = null;
        var cheats = std.ArrayList(Vec2).init(allocator);
        var move = current.go(.Up);
        if(path.contains(move) and !visited.contains(move)) {
            next = move;
        } else if(evaluateCheat(&path, move, .Up)) |cheat| {
            try cheats.append(cheat);
        }

        move = current.go(.Down);
        if(path.contains(move) and !visited.contains(move)) {
            next = move;
        } else if(evaluateCheat(&path, move, .Down)) |cheat| {
            try cheats.append(cheat);
        }

        move = current.go(.Left);
        if(path.contains(move) and !visited.contains(move)) {
            next = move;
        } else if(evaluateCheat(&path, move, .Left)) |cheat| {
            try cheats.append(cheat);
        }

        move = current.go(.Right);
        if(path.contains(move) and !visited.contains(move)) {
            next = move;
        } else if(evaluateCheat(&path, move, .Right)) |cheat| {
            try cheats.append(cheat);
        }
        try visited.put(current, .{.cheats = cheats, .step = step});
    }

    var cheatTotal :usize = 0;
    for(visited.keys()) |key| {
        const val = visited.get(key).?;
        if(val.cheats.items.len == 0)
            continue;
        for (val.cheats.items) |cheat| {
            const cheatVal = visited.get(cheat).?;
            if(cheatVal.step < val.step)
                continue;
            const skip = cheatVal.step - val.step - 2;
            if(skip >= 100){
                std.debug.print("Cheat {} from: {any} to {any}\n", .{skip, key, cheat});
                cheatTotal += 1;
            }
        }
    } 
    

    std.debug.print("Answer: {}", .{cheatTotal});
}

fn evaluateCheat(path: *const std.AutoHashMap(Vec2, void), maybeWall: Vec2, direction: Direction) ?Vec2 {
    const maybeCheat = maybeWall.go(direction);
    if(path.contains(maybeCheat))
        return maybeCheat;

    return null;
}


const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(self: *const Vec2, right: *const Vec2) Vec2 {
        return .{ .x = self.x + right.x, .y = self.y + right.y };
    }

    pub fn eq(self: *const Vec2, right: *const Vec2) bool {
        return self.x == right.x and self.y == right.y;
    }

    pub fn go(self: *const Vec2, direction: Direction) Vec2 {
        return switch (direction) {
            .Up => .{ .x = self.x, .y = self.y - 1 },
            .Down => .{ .x = self.x, .y = self.y + 1 },
            .Left => .{ .x = self.x - 1, .y = self.y },
            .Right => .{ .x = self.x + 1, .y = self.y }
        };
    }
};
const Direction = enum {
    Up,
    Down,
    Left,
    Right

};
const Edge = struct {
    cheats: std.ArrayList(Vec2),
    step: usize
};