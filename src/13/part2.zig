//Although this technically would work, it is still far too slow to get the answer in a reasonable amount of time,
//There is probably some math trick that I am not picking up on here
// :(

const std = @import("std");
const math = std.math;
const data = @embedFile("puzzle.input");

const TOLERANCE = 0.0001;

pub fn main() !void {
    var lines = std.mem.tokenize(u8, data, "\nButtonAB:Prize ,XY=+");
    var total: u64 = 0;
    while (lines.peek()) |_| {
        const a = try Vec2.init(lines.next().?, lines.next().?);
        const b = try Vec2.init(lines.next().?, lines.next().?);
        var prize = try Vec2.init(lines.next().?, lines.next().?);
        prize.x += 10000000000000;
        prize.y += 10000000000000;
        total += getLowestCost(a, b, prize);
    }

    std.debug.print("Answer: {}", .{total});
}

fn getLowestCost(a: Vec2, b: Vec2, prize: Vec2) u64 {
    const targetSlope = prize.slope();
    const targetMagnitude = prize.magnitude();
    const bSlope = b.slope();
    const aSlope = a.slope();

    //Unreachable if both slopes are on the same side of the target
    if (bSlope < targetSlope and aSlope < targetSlope)
        return 0;
    if (bSlope > targetSlope and aSlope > targetSlope)
        return 0;

    var move = a.add(&b);
    var cost: u64 = 4;
    while (true) {
        const currentSlope = move.slope();
        if (currentSlope > targetSlope) {
            if (aSlope < targetSlope) {
                move = move.add(&a);
                cost += 3;
            } else {
                move = move.add(&b);
                cost += 1;
            }
        } else if (currentSlope < targetSlope) {
            if (aSlope > targetSlope) {
                move = move.add(&a);
                cost += 3;
            } else {
                move = move.add(&b);
                cost += 1;
            }
        }
        if (@abs(currentSlope - targetSlope) < TOLERANCE) {
            const multiple: u64 = @intFromFloat(math.round(targetMagnitude / move.magnitude()));
            const newMove = move.multScalar(multiple);
            if (newMove.eq(&prize)) {
                return cost * multiple;
            }
        }

        //unreachable
        if (move.gt(&prize)) {
            return 0;
        }
    }

    std.debug.print("Prize: {}, A: {}, B: {}\n", .{ targetSlope, aSlope, bSlope });

    return cost;
}

const Vec2 = struct {
    x: u64,
    y: u64,

    pub fn magnitude(self: *const Vec2) f64 {
        const exactX: f64 = @floatFromInt(self.x);
        const exactY: f64 = @floatFromInt(self.y);
        return math.sqrt((math.pow(f64, exactX, 2) + math.pow(f64, exactY, 2)));
    }

    pub fn slope(self: *const Vec2) f64 {
        const exactX: f64 = @floatFromInt(self.x);
        const exactY: f64 = @floatFromInt(self.y);
        return exactY / exactX;
    }

    pub fn add(left: *const Vec2, right: *const Vec2) Vec2 {
        return .{ .x = left.x + right.x, .y = left.y + right.y };
    }

    pub fn divFloorMin(left: *const Vec2, right: *const Vec2) u64 {
        return @min(@divFloor(left.x, right.x), @divFloor(left.y, right.y));
    }

    pub fn mod(left: *const Vec2, right: *const Vec2) Vec2 {
        return .{ .x = @mod(left.x, right.x), .y = @mod(left.y, right.y) };
    }

    pub fn sub(left: *const Vec2, right: *const Vec2) Vec2 {
        return .{ .x = left.x - right.x, .y = left.y - right.y };
    }
    pub fn multScalar(left: *const Vec2, right: u64) Vec2 {
        return .{ .x = left.x * right, .y = left.y * right };
    }

    pub fn eq(self: *const Vec2, right: *const Vec2) bool {
        return self.x == right.x and self.y == right.y;
    }

    pub fn lt(self: *const Vec2, right: *const Vec2) bool {
        return self.x < right.x or self.y < right.y;
    }

    pub fn gt(self: *const Vec2, right: *const Vec2) bool {
        return self.x > right.x or self.y > right.y;
    }

    pub fn init(x: []const u8, y: []const u8) !Vec2 {
        return .{ .x = try std.fmt.parseInt(u64, x, 10), .y = try std.fmt.parseInt(u64, y, 10) };
    }

    pub fn zero() Vec2 {
        return .{ .x = 0, .y = 0 };
    }

    pub fn one() Vec2 {
        return .{ .x = 1, .y = 1 };
    }
};

const Button = struct {
    move: Vec2,
    cost: u64,
};
