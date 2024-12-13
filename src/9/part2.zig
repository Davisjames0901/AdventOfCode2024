const std = @import("std");
const data = @embedFile("9.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var fs = std.ArrayList(Block).init(allocator);

    for (0..data.len) |inx| {
        const count = quickInt(data[inx]);
        var value: ?usize = null;
        //file block
        if (inx % 2 == 0) {
            value = @divFloor(inx, 2);
        }

        try fs.append(.{ .len = count, .id = value });
    }

    printFs(&fs);

    for (0..fs.items.len) |i| {
        const reverseInx = fs.items.len - 1 - i;
        const blockToMove = fs.items[reverseInx];
        if (blockToMove.id == null)
            continue;

        fs.items[reverseInx] = blockToMove.free();
        if (!try moveBlock(&fs, blockToMove, reverseInx)) {
            fs.items[reverseInx] = blockToMove;
        }
    }

    var total: usize = 0;
    var fsI: usize = 0;
    for (fs.items) |block| {
        for (0..block.len) |_| {
            if (block.id != null) {
                total += block.id.? * fsI;
            }
            fsI += 1;
        }
    }
    std.debug.print("Answer: {}\n", .{total});
}

fn moveBlock(fs: *std.ArrayList(Block), block: Block, cutoff: usize) !bool {
    for (0..cutoff) |i| {
        //is free
        if (fs.items[i].id != null)
            continue;

        const current = fs.items[i];
        //Will fit target block
        if (current.len < block.len)
            continue;

        fs.items[i] = block;
        //readd the leftover free
        if (current.len > block.len) {
            const freeBlock: Block = .{ .len = current.len - block.len, .id = null };
            try fs.insert(i + 1, freeBlock);
        }
        return true;
    }
    return false;
}

fn quickInt(char: u8) usize {
    return switch (char) {
        '0' => 0,
        '1' => 1,
        '2' => 2,
        '3' => 3,
        '4' => 4,
        '5' => 5,
        '6' => 6,
        '7' => 7,
        '8' => 8,
        '9' => 9,
        else => unreachable,
    };
}

fn printFs(fs: *const std.ArrayList(Block)) void {
    for (fs.items) |value| {
        for (0..value.len) |_| {
            if (value.id == null) {
                std.debug.print(".", .{});
            } else {
                std.debug.print("{}", .{value.id.?});
            }
        }
    }
    std.debug.print("\n", .{});
}

const Block = struct {
    len: usize,
    id: ?usize,
    pub fn free(self: *const Block) Block {
        return .{ .len = self.len, .id = null };
    }
};
const BlockType = enum { Free, Used };
