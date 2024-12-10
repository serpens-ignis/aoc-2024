const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Pos = struct { x: i32, y: i32 };

const PathCount = std.AutoHashMap(Pos, usize);

const TopoMap = struct {
    const HeightMap = std.ArrayList(std.ArrayList(?usize));

    hmap: HeightMap,
    trailheads: std.ArrayList(Pos),
    w: usize,
    h: usize,

    fn init(raw: []const u8) !TopoMap {
        var map = TopoMap{
            .hmap = HeightMap.init(allocator),
            .trailheads = std.ArrayList(Pos).init(allocator),
            .w = 0,
            .h = 0,
        };
        errdefer map.deinit();

        var y: usize = 0;
        var line_it = std.mem.splitAny(u8, raw, "\n");
        while (line_it.next()) |line| : (y += 1) {
            var heights = std.ArrayList(?usize).init(allocator);
            errdefer heights.deinit();
            for (line, 0..) |char, x| {
                map.w = x + 1;
                const height = std.fmt.parseInt(usize, &[1]u8{char}, 10) catch null;
                try heights.append(height);
                if (height == 0) {
                    try map.trailheads.append(.{ .x = @intCast(x), .y = @intCast(y) });
                }
            }
            try map.hmap.append(heights);
        }
        map.h = y - 1;

        return map;
    }

    fn deinit(self: TopoMap) void {
        for (self.hmap.items) |item| {
            item.deinit();
        }
        self.hmap.deinit();
        self.trailheads.deinit();
    }

    fn get(self: TopoMap, x: i32, y: i32) ?usize {
        if (x < 0 or y < 0 or x >= self.w or y >= self.h) return null;
        return self.hmap.items[@intCast(y)].items[@intCast(x)];
    }
};

fn search(
    map: TopoMap,
    reachable: *PathCount,
    x: i32,
    y: i32,
    target_h: usize,
) !void {
    const h = map.get(x, y);
    if (h != target_h) return;
    if (h == 9) {
        const pos = Pos{ .x = x, .y = y };
        if (reachable.contains(pos)) {
            try reachable.put(pos, reachable.get(pos).? + 1);
        } else try reachable.put(pos, 1);
        return;
    }
    try search(map, reachable, x - 1, y, target_h + 1);
    try search(map, reachable, x, y - 1, target_h + 1);
    try search(map, reachable, x + 1, y, target_h + 1);
    try search(map, reachable, x, y + 1, target_h + 1);
}

fn solve(map: TopoMap) !struct { unique: usize, total: usize } {
    var unique: usize = 0;
    var total: usize = 0;
    for (map.trailheads.items) |thead| {
        var reachable = PathCount.init(allocator);
        defer reachable.deinit();
        try search(map, &reachable, thead.x, thead.y, 0);
        var it = reachable.iterator();
        while (it.next()) |item| {
            unique += 1;
            total += item.value_ptr.*;
        }
    }
    return .{ .unique = unique, .total = total };
}

pub fn main() !void {
    var input = try TopoMap.init(@embedFile("input"));
    var example = try TopoMap.init(@embedFile("example"));
    defer input.deinit();
    defer example.deinit();

    var path_count = try solve(example);
    std.debug.print("Answer to part 1 (example): {}\n", .{path_count.unique});
    std.debug.print("Answer to part 2 (example): {}\n", .{path_count.total});

    path_count = try solve(input);
    std.debug.print("Answer to part 1: {}\n", .{path_count.unique});
    std.debug.print("Answer to part 2: {}\n", .{path_count.total});
}
