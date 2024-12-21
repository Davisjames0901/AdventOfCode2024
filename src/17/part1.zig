const std = @import("std");
const data = @embedFile("puzzle.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = std.mem.tokenize(u8, data, "\nProgramRegisterABC:, ");

    var cpu = try Cpu.init(lines.next().?, lines.next().?, lines.next().?, allocator);
    var instructions = std.ArrayList(i8).init(allocator);
    while (lines.peek()) |_| {
        try instructions.append(try std.fmt.parseInt(i8, lines.next().?, 10));
    }

    var stackPointer: i8 = 0;
    while(true) {
        if(stackPointer < 0 or stackPointer + 1 > instructions.items.len)
            break;

        const instruction: Instruction = .{.opcode = instructions.items[@intCast(stackPointer)], .input = instructions.items[@intCast(stackPointer + 1)]};
        stackPointer = try cpu.doInstruction(&instruction, stackPointer);
    }

    std.debug.print("Answer: {any}", .{cpu.output.items});
}

const Instruction = struct {
    opcode: i8,
    input: i8,

    fn getCombo(self: *const Instruction, cpu: *const Cpu) i64 {
        return switch (self.input) {
            4 => cpu.registerA,
            5 => cpu.registerB,
            6 => cpu.registerC,
            7 => unreachable,
            else => self.input
        };
    }
};

const Cpu = struct {
    registerA: i64,
    registerB: i64,
    registerC: i64,
    output: std.ArrayList(i64),

    fn init(a: []const u8, b: []const u8, c: []const u8, alloc: std.mem.Allocator) !Cpu {
        return .{
            .registerA = try std.fmt.parseInt(i64, a, 10),
            .registerB = try std.fmt.parseInt(i64, b, 10),
            .registerC = try std.fmt.parseInt(i64, c, 10),
            .output = std.ArrayList(i64).init(alloc)
        };
    }

    fn doInstruction(self: *Cpu, instruction: *const Instruction, ptr: i8) !i8 {
        switch (instruction.opcode) {
            0 => {
                const denominator = std.math.pow(i64, 2, instruction.getCombo(self));
                self.registerA = @divTrunc(self.registerA, denominator);
            },
            1 => self.registerB = self.registerB ^ instruction.input,
            2 => self.registerB = @mod(instruction.getCombo(self), 8),
            3 => {
                if(self.registerA != 0)
                    return instruction.input;
            },
            4 => self.registerB = self.registerB ^ self.registerC,
            5 => try self.output.append(@mod(instruction.getCombo(self), 8)),
            6 => {
                const denominator = std.math.pow(i64, 2, instruction.getCombo(self));
                self.registerB = @divTrunc(self.registerA, denominator);
            },
            7 => {
                const denominator = std.math.pow(i64, 2, instruction.getCombo(self));
                self.registerC = @divTrunc(self.registerA, denominator);
            },
            else => unreachable,
        }

        return ptr + 2;
    }
};