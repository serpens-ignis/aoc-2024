const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Report = std.ArrayList(i32);
const ReportList = std.ArrayList(Report);

fn parse_input(raw: []const u8) !ReportList {
    var list = ReportList.init(allocator);
    errdefer list.deinit();

    var line_it = std.mem.splitAny(u8, raw, "\n");
    while (line_it.next()) |line| {
        if (line.len == 0) continue;

        var report = std.ArrayList(i32).init(allocator);
        errdefer report.deinit();

        var it = std.mem.splitAny(u8, line, " ");
        while (it.next()) |s| {
            const num = try std.fmt.parseInt(i32, s, 10);
            try report.append(num);
        }
        try list.append(report);
    }

    return list;
}

fn is_safe(report: Report) bool {
    const items = report.items;
    const increasing = items[1] > items[0];
    var prev = items[0];
    for (items[1..]) |level| {
        const diff = @abs(level - prev);
        if ((diff < 1 or diff > 3) or
            (increasing and prev > level) or
            (!increasing and level > prev))
        {
            return false;
        }
        prev = level;
    }
    return true;
}

fn solve_part1(list: ReportList) usize {
    var unsafe: usize = 0;
    for (list.items) |report| {
        if (!is_safe(report)) unsafe += 1;
    }
    return list.items.len - unsafe;
}

fn solve_part2(list: ReportList) !usize {
    var unsafe: usize = 0;
    next: for (list.items) |report| {
        if (is_safe(report)) continue;
        for (0..report.items.len) |i| {
            var dampened = try report.clone();
            defer dampened.deinit();
            _ = dampened.orderedRemove(i);
            if (is_safe(dampened)) continue :next;
        }
        unsafe += 1;
    }
    return list.items.len - unsafe;
}

pub fn main() !void {
    const raw_input = @embedFile("input");
    const raw_example = @embedFile("example");
    const input = try parse_input(raw_input);
    const example = try parse_input(raw_example);
    defer input.deinit();
    defer example.deinit();

    var ans1 = solve_part1(example);
    var ans2 = try solve_part2(example);
    std.debug.print("Answer to part 1 (example): {}\n", .{ans1});
    std.debug.print("Answer to part 2 (example): {}\n", .{ans2});

    ans1 = solve_part1(input);
    ans2 = try solve_part2(input);
    std.debug.print("Answer to part 1: {}\n", .{ans1});
    std.debug.print("Answer to part 2: {}\n", .{ans2});
}
