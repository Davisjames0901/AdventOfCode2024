const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var lines = std.mem.tokenize(u8, data, "\nButtonAB:Prize ,XY=+");
    var total: i32 = 0;
    while(lines.peek()) |_| {
        const a = try Vec2.init(lines.next().?, lines.next().?);
        const b = try Vec2.init(lines.next().?, lines.next().?);
        const prize = try Vec2.init(lines.next().?, lines.next().?);
        total += getLowestCost(a, b, prize);
    }

    std.debug.print("Answer: {}", .{total});
}

fn getLowestCost(a: Vec2, b: Vec2, prize: Vec2) i32 {
    var bestCost: ?i32 = null;
    var aPresses: usize = 0;
    while(true) {
        var claw: Vec2 = .{.x = 0, .y = 0};
        var pressedB = false;
        var presses: usize = 0;
        var cost: i32 = 0;
        while(true) : (presses += 1) {
            if(presses >= aPresses) {
                pressedB = true;
                claw = claw.add(&b);
                cost += 1;
            } else {
                claw = claw.add(&a);
                cost += 3;
            }
            presses += 1;
            if(claw.eq(&prize)) {
                if(bestCost != null)
                    std.debug.print("More solutions?\n", .{});
                if(bestCost == null or cost < bestCost.?) {
                    bestCost = cost;
                }
            } else if(prize.lt(&claw)) {
                break;
            }
        }

        //We've gone through them all
        if(!pressedB)
            break;

        //lets add in another A press!
        aPresses += 1;
    }
    if(bestCost) |best|
        return best;

    return 0;
}


const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(left: *const Vec2, right: *const Vec2) Vec2 {
        return .{ .x = left.x + right.x, .y = left.y + right.y };
    }

    pub fn eq(self: *const Vec2, right: *const Vec2) bool {
        return self.x == right.x and self.y == right.y;
    }

    pub fn lt(self: *const Vec2, right: *const Vec2) bool {
        return self.x < right.x or self.y < right.y;
    }

    pub fn init(x: []const u8, y: []const u8) !Vec2 {
        return .{
            .x = try std.fmt.parseInt(i32, x, 10),
            .y = try std.fmt.parseInt(i32, y, 10)
        };
    }
};
