const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var plots = std.ArrayList(Plot).init(allocator);
    var lines = std.mem.tokenize(u8, data, "\n");

    var lineLen: usize = 0;
    var lineNum: usize = 0;
    var totalPrice: usize = 0;
    while (lines.next()) |line| : (lineNum += 1) {
        if (lineLen == 0)
            //Add one to account for the missing \n
            lineLen = line.len + 1;

        for (line, 0..) |plant, i| {
            const pos = Vec2.init(i, lineNum);
            if (!anyPlotContains(plant, pos, &plots)) {
                const newPlot = try Plot.init(plant, pos, lineLen, allocator);
                totalPrice += try newPlot.getFencePrice();
                try plots.append(newPlot);
            }
        }
    }

    std.debug.print("Answer: {}", .{totalPrice});
}

fn anyPlotContains(plantType: u8, pos: Vec2, plots: *const std.ArrayList(Plot)) bool {
    for (plots.items) |plot| {
        if (plot.plantType == plantType and plot.plants.contains(pos))
            return true;
    }
    return false;
}

fn append(self: *std.AutoArrayHashMap(i32, std.ArrayList(i32)), key: i32, val: i32) !void {
    if (self.contains(key)) {
        var vals = self.get(key).?;
        try vals.append(val);
        try self.put(key, vals);
    } else {
        var vals = std.ArrayList(i32).init(self.allocator);
        try vals.append(val);
        try self.put(key, vals);
    }
}

fn numOfSegments(list: *std.ArrayList(i32)) usize {
    var total: usize = 1;
    std.mem.sort(i32, list.items, {}, comptime std.sort.asc(i32));
    var next: ?i32 = null;
    for (list.items) |num| {
        if (next == null) {
            next = num + 1;
            continue;
        }
        if (num != next) {
            total += 1;
        }
        next = num + 1;
    }
    return total;
}

const Plot = struct {
    plantType: u8,
    plants: std.AutoArrayHashMap(Vec2, void),

    pub fn init(plantType: u8, start: Vec2, width: usize, alloc: std.mem.Allocator) !Plot {
        var plot: Plot = .{ .plantType = plantType, .plants = std.AutoArrayHashMap(Vec2, void).init(alloc) };

        try plot.tryAddPlant(start, width);

        return plot;
    }

    fn tryAddPlant(self: *Plot, pos: Vec2, width: usize) !void {
        if (pos.getMapChar(width)) |plant| {
            if (self.plantType != plant)
                return;

            if (self.plants.contains(pos))
                return;

            try self.plants.put(pos, {});
            try self.tryAddPlant(pos.goUp(), width);
            try self.tryAddPlant(pos.goDown(), width);
            try self.tryAddPlant(pos.goLeft(), width);
            try self.tryAddPlant(pos.goRight(), width);
        }
    }

    // I am not exactly proud of this, but whatever.
    fn getFencePrice(self: *const Plot) !usize {
        //Up faces, key: row, value col
        var up = std.AutoArrayHashMap(i32, std.ArrayList(i32)).init(self.plants.allocator);
        //Down faces, key: row, value col
        var down = std.AutoArrayHashMap(i32, std.ArrayList(i32)).init(self.plants.allocator);
        //Left faces, key: col, value row
        var left = std.AutoArrayHashMap(i32, std.ArrayList(i32)).init(self.plants.allocator);
        //Right faces, key: col, value row
        var right = std.AutoArrayHashMap(i32, std.ArrayList(i32)).init(self.plants.allocator);

        for (self.plants.keys()) |pos| {
            const faces = Faces.init(self, pos);
            if (faces.up)
                try append(&up, pos.y, pos.x);
            if (faces.down)
                try append(&down, pos.y, pos.x);
            if (faces.left)
                try append(&left, pos.x, pos.y);
            if (faces.right)
                try append(&right, pos.x, pos.y);
        }
        var totalFaces: usize = 0;
        for (up.keys()) |key| {
            var list = up.get(key).?;
            totalFaces += numOfSegments(&list);
        }
        for (down.keys()) |key| {
            var list = down.get(key).?;
            totalFaces += numOfSegments(&list);
        }
        for (left.keys()) |key| {
            var list = left.get(key).?;
            totalFaces += numOfSegments(&list);
        }
        for (right.keys()) |key| {
            var list = right.get(key).?;
            totalFaces += numOfSegments(&list);
        }

        return self.plants.keys().len * totalFaces;
    }
};

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

    pub fn getMapChar(self: *const Vec2, width: usize) ?u8 {
        const oneD = self.to1d(width);
        if (oneD < 0 or oneD > data.len - 1)
            return null;

        return data[@intCast(oneD)];
    }

    pub fn to1d(self: *const Vec2, width: usize) i32 {
        const iWidth: i32 = @intCast(width);
        return (self.y * iWidth) + self.x;
    }

    pub fn init(x: anytype, y: anytype) Vec2 {
        return .{ .x = @intCast(x), .y = @intCast(y) };
    }
};

const Faces = struct {
    up: bool,
    down: bool,
    left: bool,
    right: bool,

    fn init(plot: *const Plot, pos: Vec2) Faces {
        return .{
            .up = !plot.plants.contains(pos.goUp()),
            .down = !plot.plants.contains(pos.goDown()),
            .left = !plot.plants.contains(pos.goLeft()),
            .right = !plot.plants.contains(pos.goRight()) };
    }
};
