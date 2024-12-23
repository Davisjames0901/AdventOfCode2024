const std = @import("std");
const data = @embedFile("test.input");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = std.mem.tokenize(u8, data, "\nProgramRegisterABC:, ");

    _ = lines.next();
    _ = lines.next();
    _ = lines.next();

    var program = std.ArrayList(i64).init(allocator);
    while (lines.peek()) |_| {
        try program.append(try std.fmt.parseInt(i64, lines.next().?, 10));
    }

    var bests = std.ArrayList(i64).init(allocator);
    var running = true;
    var handles = std.ArrayList(std.Thread).init(allocator);
    for(0..24) |i| {
        const start: i64 = @intCast(i);
        const thread = try std.Thread.spawn(.{}, threadStart, .{start, 24, &running, &bests, &program, allocator});
        try handles.append(thread);
    }

    while(true) {
        if(bests.items.len > 0){
            std.debug.print("Bingo!\n", .{});
            break;
        }
        std.time.sleep(10_000_000);
    }
    running = false;

    std.debug.print("Wut\n", .{});
    const answer = std.mem.min(i64, bests.items);

    std.debug.print("Answer: {}", .{answer});
}

fn threadStart(start: i64, by: i64, run: *const bool, bests: *std.ArrayList(i64), program: *const std.ArrayList(i64), allocator: std.mem.Allocator) void {
    var a: i64 = start;
    var cpu = Cpu.init(a, allocator) catch {std.debug.print("Couldnt init cpu\n", .{});};
    while (run.*) {
        cpu.simulate(program) catch {std.debug.print("Couldnt simulate\n", .{});};

        if (cpu.output.items.len != program.items.len)
            continue;

        if (std.mem.eql(i64, program.items, cpu.output.items)) {
            bests.append(a) catch {std.debug.print("Couldnt append\n", .{});};
            std.debug.print("Thread: {} found a solution at {}\n", .{start, a});
            break;
        }

        a += by;
        cpu.reset(a);
    }
}

const Instruction = struct {
    opcode: i64,
    input: i64,

    fn getCombo(self: *const Instruction, cpu: *const Cpu) i64 {
        return switch (self.input) {
            4 => cpu.registerA,
            5 => cpu.registerB,
            6 => cpu.registerC,
            7 => unreachable,
            else => self.input,
        };
    }
};

const Cpu = struct {
    registerA: i64,
    registerB: i64,
    registerC: i64,
    output: std.ArrayList(i64),

    fn init(a: i64, alloc: std.mem.Allocator) !Cpu {
        return .{ .registerA = a, .registerB = 0, .registerC = 0, .output = std.ArrayList(i64).init(alloc) };
    }

    fn reset(self: *Cpu, a: i64) void {
        self.registerA = a;
        self.registerB = 0;
        self.registerC = 0;
        self.output.clearRetainingCapacity();
    }

    fn doInstruction(self: *Cpu, instruction: *const Instruction, ptr: i64) !i64 {
        switch (instruction.opcode) {
            0 => {
                const denominator = std.math.pow(i64, 2, instruction.getCombo(self));
                self.registerA = @divTrunc(self.registerA, denominator);
            },
            1 => self.registerB = self.registerB ^ instruction.input,
            2 => self.registerB = @mod(instruction.getCombo(self), 8),
            3 => {
                if (self.registerA != 0)
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

    fn simulate(self: *Cpu, instructions: *const std.ArrayList(i64)) !void {
        var stackPointer: i64 = 0;
        while (true) {
            if (stackPointer < 0 or stackPointer + 1 > instructions.items.len)
                break;

            const instruction: Instruction = .{ .opcode = instructions.items[@intCast(stackPointer)], .input = instructions.items[@intCast(stackPointer + 1)] };
            stackPointer = try self.doInstruction(&instruction, stackPointer);
        }
    }
};
