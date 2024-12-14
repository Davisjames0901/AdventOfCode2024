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
    while(lines.next()) |line|: (lineNum += 1) {
        if(lineLen == 0)
            //Add one to account for the missing \n
            lineLen = line.len + 1;


        for(line, 0..) |plant, i| {
            const pos = Vec2.init(i, lineNum);
            if(!anyPlotContains(plant, pos, &plots)){
                const newPlot = try Plot.init(plant, pos, lineLen, allocator);
                totalPrice += newPlot.getFencePrice();
                try plots.append(newPlot);
            }
        }

    }

    std.debug.print("Answer: {}", .{totalPrice});
}

fn anyPlotContains(plantType: u8, pos: Vec2, plots: *const std.ArrayList(Plot)) bool {
    for(plots.items) |plot| {
        if(plot.plantType == plantType and plot.plants.contains(pos))
            return true;
    }
    return false;
}

const Plot = struct {
    plantType: u8,
    plants: std.AutoArrayHashMap(Vec2, void),

    pub fn init(plantType: u8, start: Vec2, width: usize, alloc: std.mem.Allocator) !Plot {
        var plot: Plot = .{
            .plantType = plantType,
            .plants = std.AutoArrayHashMap(Vec2, void).init(alloc)
        };

        try plot.tryAddPlant(start, width);

        return plot;
    }

    fn tryAddPlant(self: *Plot, pos: Vec2, width: usize) !void {
        if(pos.getMapChar(width)) |plant|{
            if(self.plantType != plant)
                return;

            if(self.plants.contains(pos))
                return;

            try self.plants.put(pos, {});
            try self.tryAddPlant(pos.goUp(), width);
            try self.tryAddPlant(pos.goDown(), width);
            try self.tryAddPlant(pos.goLeft(), width);
            try self.tryAddPlant(pos.goRight(), width);
        }
    }

    fn getExposedFaces(self: *const Plot, pos: Vec2) usize {
        var faces: usize = 0;
        const up = pos.goUp();
        const down = pos.goDown();
        const left = pos.goLeft();
        const right = pos.goRight();

        if(!self.plants.contains(up))
            faces += 1;
        if(!self.plants.contains(down))
            faces += 1;
        if(!self.plants.contains(left))
            faces += 1;
        if(!self.plants.contains(right))
            faces += 1;

        return faces;
    }

    fn getFencePrice(self: *const Plot) usize {
        var perimeter: usize = 0;
        const plants = self.plants.keys();
        for(plants) |plant| {
            perimeter += self.getExposedFaces(plant);
        }
        return plants.len * perimeter;
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
        if(oneD < 0 or oneD > data.len - 1)
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
