const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const ComputerList = std.ArrayList([]const u8);
const Links = std.StringHashMap(void);
const LinkMap = std.StringHashMap(Links);

fn cmp_str(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs) == .lt;
}

fn parse_input(raw: []const u8) !struct { computers: ComputerList, links: LinkMap } {
    var computers = ComputerList.init(allocator);
    errdefer computers.deinit();

    var links = LinkMap.init(allocator);
    errdefer links.deinit();

    var line_it = std.mem.splitAny(u8, raw, "\n");
    while (line_it.next()) |line| {
        if (line.len == 0) continue;
        const cpu1 = line[0..2];
        const cpu2 = line[3..5];
        if (!links.contains(cpu1)) {
            try links.put(cpu1, Links.init(allocator));
            try computers.append(cpu1);
        }
        if (!links.contains(cpu2)) {
            try links.put(cpu2, Links.init(allocator));
            try computers.append(cpu2);
        }
        try links.getPtr(cpu1).?.put(cpu2, {});
        try links.getPtr(cpu2).?.put(cpu1, {});
    }

    std.mem.sort([]const u8, computers.items, {}, cmp_str);

    return .{ .computers = computers, .links = links };
}

fn solve_part1(map: LinkMap) !usize {
    var res: usize = 0;

    var known = Links.init(allocator);
    defer known.deinit();

    var it = map.iterator();
    while (it.next()) |cpu| {
        const cpu1 = cpu.key_ptr.*;
        const links1 = cpu.value_ptr.*;

        try known.put(cpu1, {});

        var known2 = Links.init(allocator);
        defer known2.deinit();

        var links1_it = links1.iterator();
        while (links1_it.next()) |link1| {
            const cpu2 = link1.key_ptr.*;
            const links2 = map.get(cpu2).?;
            if (known.contains(cpu2)) continue;

            try known2.put(cpu2, {});

            var links2_it = links2.iterator();
            while (links2_it.next()) |link2| {
                const cpu3 = link2.key_ptr.*;

                if (known.contains(cpu3)) continue;
                if (known2.contains(cpu3)) continue;
                if (!(cpu1[0] == 't') and !(cpu2[0] == 't') and !(cpu3[0] == 't')) continue;

                if (links1.contains(cpu3)) {
                    res += 1;
                }
            }
        }
    }

    return res;
}

fn find_longest(
    map: LinkMap,
    cpu: []const u8,
    other_cpus: [][]const u8,
    cur: *ComputerList,
    longest: *ComputerList,
) !void {
    for (cur.items) |prev| {
        if (!map.get(prev).?.contains(cpu)) return;
    }

    try cur.append(cpu);

    if (cur.items.len > longest.items.len) {
        longest.deinit();
        longest.* = try cur.clone();
    }

    for (other_cpus, 0..) |next, i| {
        try find_longest(map, next, other_cpus[i + 1 ..], cur, longest);
    }

    _ = cur.pop();
}

fn solve_part2(computers: ComputerList, map: LinkMap) ![]u8 {
    var cur = ComputerList.init(allocator);
    defer cur.deinit();

    var longest = ComputerList.init(allocator);
    errdefer longest.deinit();

    for (computers.items, 0..) |cpu, i| {
        try find_longest(map, cpu, computers.items[i + 1 ..], &cur, &longest);
    }

    var res: [256]u8 = .{0} ** 256;
    var i: usize = 0;
    for (longest.items) |cpu| {
        for (cpu) |char| {
            res[i] = char;
            i += 1;
        }
        res[i] = ',';
        i += 1;
    }
    return res[0 .. i - 1];
}

pub fn main() !void {
    var input = try parse_input(@embedFile("input"));
    var example = try parse_input(@embedFile("example"));
    defer input.computers.deinit();
    defer input.links.deinit();
    defer example.computers.deinit();
    defer example.links.deinit();

    std.debug.print("Answer to part 1 (example): {}\n", .{try solve_part1(example.links)});
    std.debug.print(
        "Answer to part 2 (example): {s}\n",
        .{try solve_part2(example.computers, example.links)},
    );
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1: {}\n", .{try solve_part1(input.links)});
    std.debug.print(
        "Answer to part 2: {s}\n",
        .{try solve_part2(input.computers, input.links)},
    );
}
