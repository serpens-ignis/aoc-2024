const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Towel = []const u8;
const TowelSet = std.StringHashMap(void);
const TowelList = std.ArrayList(Towel);

fn parse_input(raw: []const u8) !struct { available: TowelSet, designs: TowelList } {
    var available = TowelSet.init(allocator);
    var designs = TowelList.init(allocator);
    var line_it = std.mem.splitAny(u8, raw, "\n");

    var available_it = std.mem.splitAny(u8, line_it.next().?, ", ");
    while (available_it.next()) |towel| {
        if (towel.len == 0) continue;
        try available.put(towel, {});
    }

    while (line_it.next()) |towel| {
        if (towel.len == 0) continue;
        try designs.append(towel);
    }

    return .{ .available = available, .designs = designs };
}

const Cache = std.StringHashMap(usize);

fn can_form(cache: *Cache, available: TowelSet, design: Towel) !usize {
    if (cache.get(design)) |res| return res;

    var combos: usize = 0;
    if (available.contains(design)) combos = 1;
    for (0..design.len) |i| {
        const j = design.len - i;
        if (available.contains(design[0..j])) {
            combos += try can_form(cache, available, design[j..]);
        }
    }

    try cache.put(design, combos);
    return combos;
}

fn solve(available: TowelSet, designs: TowelList) !struct { combos: usize, unique: usize } {
    var unique: usize = 0;
    var combos: usize = 0;
    for (designs.items) |combo| {
        var cache = Cache.init(allocator);
        defer cache.deinit();
        const res = try can_form(&cache, available, combo);
        if (res > 0) {
            combos += res;
            unique += 1;
        }
    }
    return .{ .combos = combos, .unique = unique };
}

pub fn main() !void {
    var input = try parse_input(@embedFile("input"));
    var example = try parse_input(@embedFile("example"));
    defer input.available.deinit();
    defer input.designs.deinit();
    defer example.available.deinit();
    defer example.designs.deinit();

    var ans = try solve(example.available, example.designs);
    std.debug.print("Answer to part 1 (example): {}\n", .{ans.unique});
    std.debug.print("Answer to part 2 (example): {}\n", .{ans.combos});
    std.debug.print("\n", .{});

    ans = try solve(input.available, input.designs);
    std.debug.print("Answer to part 1: {}\n", .{ans.unique});
    std.debug.print("Answer to part 2: {}\n", .{ans.combos});
}
