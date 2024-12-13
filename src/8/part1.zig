const std = @import("std");
const data = @embedFile("8.input");

pub fn main() !void {
    var lines = std.mem.tokenizeAny(u8, data, "\n");
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var antinodes = std.AutoHashMap(Vec2, void).init(allocator);
    var occupied = std.AutoHashMap(Vec2, u8).init(allocator);
    var antennas = std.AutoArrayHashMap(u8, std.ArrayList(Vec2)).init(allocator);

    var lineNum: i32 = 0;
    var lineLen: usize = 0;
    while (lines.next()) |line| : (lineNum += 1) {
        if (lineLen == 0)
            lineLen = line.len;
        for (line, 0..) |char, i| {
            if (char == '.')
                continue;

            const charPosition = Vec2.init(i, lineNum);
            var list = antennas.get(char);
            if (list == null) {
                list = std.ArrayList(Vec2).init(allocator);
            }
            try list.?.append(charPosition);
            try antennas.put(char, list.?);
            try occupied.put(charPosition, char);
        }
    }

    const mapSize = Vec2.init(lineLen, lineNum);

    for (antennas.keys()) |key| {
        const positions = antennas.get(key).?;
        for (positions.items) |a| {
            for (positions.items) |b| {
                if (a.eq(&b))
                    continue;
                const diff = a.sub(&b);
                const pos = a.add(&diff);
                if (pos.isOutside(&mapSize))
                    continue;

                const candidate = Vec2.init(pos.x, pos.y);

                if (antinodes.contains(candidate))
                    continue;

                try antinodes.put(candidate, {});
            }
        }
    }
    printMap(&occupied, &antinodes, &mapSize);
    std.debug.print("Total {}\n", .{antinodes.count()});
}

fn printMap(antennas: *const std.AutoHashMap(Vec2, u8), antinodes: *const std.AutoHashMap(Vec2, void), mapSize: *const Vec2) void {
    for (0..@intCast(mapSize.y)) |y| {
        for (0..@intCast(mapSize.x)) |x| {
            const pos = Vec2.init(x, y);
            const antenna = antennas.get(pos);
            if (antinodes.contains(pos)) {
                std.debug.print("#", .{});
            }
            if (antenna != null) {
                std.debug.print("{c}", .{antenna.?});
                continue;
            }
            std.debug.print(".", .{});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(self: *const Vec2, right: *const Vec2) Vec2 {
        return .{ .x = self.x + right.x, .y = self.y + right.y };
    }

    pub fn sub(self: *const Vec2, right: *const Vec2) Vec2 {
        return .{ .x = self.x - right.x, .y = self.y - right.y };
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

    pub fn init(x: anytype, y: anytype) Vec2 {
        return .{ .x = @intCast(x), .y = @intCast(y) };
    }
};

const Node = struct {
    char: u8,
    pos: Vec2,
    pub fn init(char: u8, x: anytype, y: anytype) Node {
        return .{ .char = char, .pos = Vec2.init(x, y) };
    }
};
