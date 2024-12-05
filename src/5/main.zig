const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const PageList = std.ArrayList(usize);
const RuleMap = std.AutoHashMap(usize, PageList);
const UpdateList = std.ArrayList(PageList);

fn parse_input(raw: []const u8) !struct { RuleMap, UpdateList } {
    var rules = RuleMap.init(allocator);
    var updates = UpdateList.init(allocator);
    errdefer rules.deinit();
    errdefer updates.deinit();

    var line_it = std.mem.splitAny(u8, raw, "\n");
    while (line_it.next()) |line| {
        if (line.len == 0) break;
        var it = std.mem.splitAny(u8, line, "|");
        const p1 = try std.fmt.parseInt(usize, it.next().?, 10);
        const p2 = try std.fmt.parseInt(usize, it.next().?, 10);
        if (!rules.contains(p2)) try rules.put(p2, PageList.init(allocator));
        var dependencies = rules.getPtr(p2).?;
        try dependencies.append(p1);
    }
    while (line_it.next()) |line| {
        if (line.len == 0) continue;
        var it = std.mem.splitAny(u8, line, ",");
        var update = PageList.init(allocator);
        errdefer update.deinit();
        while (it.next()) |page| {
            try update.append(try std.fmt.parseInt(usize, page, 10));
        }
        try updates.append(update);
    }

    return .{ rules, updates };
}

fn is_correct(rules: RuleMap, update: PageList) !bool {
    const pages = update.items;
    var known = std.AutoHashMap(usize, void).init(allocator);
    defer known.deinit();
    for (pages) |page| try known.put(page, {});

    var previous = std.AutoHashMap(usize, void).init(allocator);
    defer previous.deinit();

    for (pages) |page| {
        const dependencies = rules.get(page);
        if (dependencies != null) {
            for (dependencies.?.items) |dependency| {
                if (known.contains(dependency) and
                    !previous.contains(dependency))
                {
                    return false;
                }
            }
        }
        try previous.put(page, {});
    }
    return true;
}

fn reorder(rules: RuleMap, update: PageList) !void {
    const pages = update.items;
    var known = std.AutoHashMap(usize, usize).init(allocator);
    defer known.deinit();
    for (pages, 0..) |page, i| try known.put(page, i);

    var previous = std.AutoHashMap(usize, void).init(allocator);
    defer previous.deinit();

    var i: usize = 0;
    outer: while (i < pages.len) {
        const page = pages[i];
        const dependencies = rules.get(page);
        if (dependencies != null) {
            for (dependencies.?.items) |dependency| {
                if (known.contains(dependency) and
                    !previous.contains(dependency))
                {
                    const j = known.get(dependency).?;
                    pages[i] = pages[j];
                    pages[j] = page;
                    try known.put(pages[i], i);
                    try known.put(pages[j], j);
                    continue :outer;
                }
            }
        }
        try previous.put(pages[i], {});
        i += 1;
    }
}

fn solve_part1(rules: RuleMap, updates: UpdateList) !usize {
    var res: usize = 0;
    for (updates.items) |update| {
        if (!try is_correct(rules, update)) continue;
        res += update.items[update.items.len / 2];
    }
    return res;
}

fn solve_part2(rules: RuleMap, updates: UpdateList) !usize {
    var res: usize = 0;
    for (updates.items) |update| {
        if (try is_correct(rules, update)) continue;
        try reorder(rules, update);
        res += update.items[update.items.len / 2];
    }
    return res;
}

pub fn main() !void {
    var input = try parse_input(@embedFile("input"));
    var example = try parse_input(@embedFile("example"));

    defer input[0].deinit();
    defer input[1].deinit();
    defer {
        var it = input[0].iterator();
        while (it.next()) |item| item.value_ptr.*.deinit();
    }
    defer for (input[1].items) |item| item.deinit();

    defer example[0].deinit();
    defer example[1].deinit();
    defer {
        var it = example[0].iterator();
        while (it.next()) |item| item.value_ptr.*.deinit();
    }
    defer for (example[1].items) |item| item.deinit();

    var ans1 = try solve_part1(example[0], example[1]);
    var ans2 = try solve_part2(example[0], example[1]);
    std.debug.print("Answer to part 1 (example): {}\n", .{ans1});
    std.debug.print("Answer to part 2 (example): {}\n", .{ans2});

    ans1 = try solve_part1(input[0], input[1]);
    ans2 = try solve_part2(input[0], input[1]);
    std.debug.print("Answer to part 1: {}\n", .{ans1});
    std.debug.print("Answer to part 2: {}\n", .{ans2});
}
