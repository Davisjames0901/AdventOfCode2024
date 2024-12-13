const std = @import("std");
const data = @embedFile("2.input");
const List = std.ArrayList;

pub fn main() !void {
    var reports = std.mem.tokenizeAny(u8, data, "\n");
    var report = List(i32).init(std.heap.page_allocator);
    defer report.deinit();

    var safeReports: i32 = 0;
    while (reports.next()) |reportLine| : (report.clearRetainingCapacity()) {
        var reportTokens = std.mem.tokenizeAny(u8, reportLine, " ");

        while (reportTokens.next()) |reportToken| {
            try report.append(try std.fmt.parseInt(i32, reportToken, 10));
        }

        if (isSafe(report)) {
            safeReports += 1;
            std.debug.print("{any} Safe!\n", .{report.items});
            continue;
        }

        var iteration: usize = 0;
        while (iteration < report.items.len) : (iteration += 1) {
            var slice = try report.clone();
            _ = slice.orderedRemove(iteration);
            if (isSafe(slice)) {
                safeReports += 1;
                std.debug.print("{any} Safe!\n", .{report.items});
                break;
            }
        }
        std.debug.print("{any} Unsafe!\n", .{report.items});
    }
    std.debug.print("Answer: {}\n", .{safeReports});
}

fn isSafe(report: List(i32)) bool {
    var reportIsDecreasing: ?bool = null;
    var lastLevel = report.items[0];
    for (report.items[1..]) |level| {
        defer lastLevel = level;
        const diff = lastLevel - level;
        const absDiff = @abs(diff);
        const levelIsDecreasing = diff < 0;
        const directionMatches = reportIsDecreasing orelse levelIsDecreasing == levelIsDecreasing;

        if (absDiff < 1 or absDiff > 3 or !directionMatches) {
            return false;
        }
        if (reportIsDecreasing == null)
            reportIsDecreasing = levelIsDecreasing;
    }
    return true;
}
