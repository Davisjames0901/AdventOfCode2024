const std = @import("std");
const data = @embedFile("2.input");

pub fn main() !void {
    var reports = std.mem.tokenizeAny(u8, data, "\n");

    var safeReports: i32 = 0;
    report: while (reports.next()) |report| {
        var levelsStrings = std.mem.tokenizeAny(u8, report, " ");

        var lastLevel: i32 = try std.fmt.parseInt(i32, levelsStrings.next().?, 10);
        var reportIsDecreasing: ?bool = null;

        level: while (levelsStrings.next()) |levelString| {
            const level = try std.fmt.parseInt(i32, levelString, 10);
            defer lastLevel = level;

            const diff = lastLevel - level;
            const absDiff = @abs(diff);
            const levelIsDecreasing = diff < 0;
            const directionMatches = reportIsDecreasing orelse levelIsDecreasing == levelIsDecreasing;

            //safe
            if (absDiff > 0 and absDiff < 4 and directionMatches) {
                if (reportIsDecreasing == null)
                    reportIsDecreasing = levelIsDecreasing;
                continue :level;
            }

            //unsafe
            std.debug.print("{s} -> Unsafe!\n", .{report});
            continue :report;
        }
        std.debug.print("{s} -> Safe!\n", .{report});
        safeReports += 1;
    }
    std.debug.print("Answer: {}\n", .{safeReports});
}
