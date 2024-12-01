const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const List = std.ArrayList(i32);

fn parse_input(raw: []const u8) !struct { List, List } {
    var list1 = List.init(allocator);
    var list2 = List.init(allocator);

    var it = std.mem.splitAny(u8, raw, " \n");
    var which = true;
    while (it.next()) |s| {
        if (s.len == 0) continue;
        const num = try std.fmt.parseInt(i32, s, 10);
        if (which) try list1.append(num) else try list2.append(num);
        which = !which;
    }

    return .{ list1, list2 };
}

pub fn solve_part1(list1: List, list2: List) u32 {
    std.mem.sort(i32, list1.items, {}, std.sort.asc(i32));
    std.mem.sort(i32, list2.items, {}, std.sort.asc(i32));
    var res: u32 = 0;
    for (list1.items, list2.items) |i, j| {
        res += @abs(i - j);
    }
    return res;
}

pub fn solve_part2(list1: List, list2: List) !i32 {
    var map = std.AutoHashMap(i32, i32).init(allocator);
    var score: i32 = 0;
    for (list1.items) |i| {
        if (!map.contains(i)) try map.put(i, 1) else try map.put(i, map.get(i).? + 1);
    }
    for (list2.items) |j| {
        if (map.contains(j)) score += map.get(j).? * j;
    }
    return score;
}

pub fn main() !void {
    const raw_input = @embedFile("input");
    const raw_example = @embedFile("example");
    const input = try parse_input(raw_input);
    const example = try parse_input(raw_example);
    defer input[0].deinit();
    defer input[1].deinit();
    defer example[0].deinit();
    defer example[1].deinit();

    var ans1 = solve_part1(example[0], example[1]);
    var ans2 = try solve_part2(example[0], example[1]);
    std.debug.print("Answer to part 1 (example): {}\n", .{ans1});
    std.debug.print("Answer to part 2 (example): {}\n", .{ans2});

    ans1 = solve_part1(input[0], input[1]);
    ans2 = try solve_part2(input[0], input[1]);
    std.debug.print("Answer to part 1: {}\n", .{ans1});
    std.debug.print("Answer to part 2: {}\n", .{ans2});
}
