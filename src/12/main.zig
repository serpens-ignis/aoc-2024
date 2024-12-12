const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Price = struct { full: usize, discount: usize };

const Pos = struct { x: i32, y: i32 };
const Dir = enum { UP, DOWN, LEFT, RIGHT };
const Edge = struct { pos: Pos, dir: Dir };

const PosSet = std.AutoHashMap(Pos, void);
const EdgeSet = std.AutoHashMap(Edge, void);

const Region = struct {
    plant: u8,
    perimeter: usize,
    sides: usize,
    area: usize,
};

const Farm = struct {
    tiles: std.ArrayList([]const u8),
    w: usize,
    h: usize,

    fn init(raw: []const u8) !Farm {
        var farm = Farm{
            .tiles = std.ArrayList([]const u8).init(allocator),
            .w = 0,
            .h = 0,
        };
        var line_it = std.mem.splitAny(u8, raw, "\n");
        while (line_it.next()) |line| : (farm.h += 1) {
            if (line.len == 0) break;
            try farm.tiles.append(line);
            farm.w = line.len;
        }
        return farm;
    }

    fn deinit(self: *Farm) void {
        self.tiles.deinit();
    }

    fn get_plant(self: *const Farm, x: i32, y: i32) ?u8 {
        if (x >= 0 and y >= 0 and x < self.w and y < self.h)
            return self.tiles.items[@intCast(x)][@intCast(y)];
        return null;
    }

    fn walk_region(
        self: *const Farm,
        region: *Region,
        visited: *PosSet,
        edges: *EdgeSet,
        x: i32,
        y: i32,
        dir: ?Dir,
    ) !void {
        const pos: Pos = .{ .x = x, .y = y };

        const plant = self.get_plant(x, y);
        if (plant != region.plant) {
            region.perimeter += 1;
            try edges.put(Edge{ .pos = pos, .dir = dir.? }, {});
            return;
        }

        if (visited.contains(pos)) return;
        try visited.put(pos, {});

        try self.walk_region(region, visited, edges, x - 1, y, .LEFT);
        try self.walk_region(region, visited, edges, x + 1, y, .RIGHT);
        try self.walk_region(region, visited, edges, x, y - 1, .UP);
        try self.walk_region(region, visited, edges, x, y + 1, .DOWN);
        region.area += 1;
    }

    fn get_regions(self: *const Farm) !std.ArrayList(Region) {
        var regions = std.ArrayList(Region).init(allocator);
        errdefer regions.deinit();

        var visited = PosSet.init(allocator);
        defer visited.deinit();

        for (0..self.h) |y| {
            for (0..self.w) |x| {
                const pos: Pos = .{ .x = @intCast(x), .y = @intCast(y) };
                if (visited.contains(pos)) continue;

                var edges = EdgeSet.init(allocator);
                defer edges.deinit();
                var region = Region{
                    .plant = self.get_plant(pos.x, pos.y).?,
                    .perimeter = 0,
                    .sides = 0,
                    .area = 0,
                };

                try self.walk_region(&region, &visited, &edges, pos.x, pos.y, null);
                region.sides = try count_sides(edges);
                try regions.append(region);
            }
        }

        return regions;
    }
};

fn count_sides(edges: EdgeSet) !usize {
    var res: usize = 0;
    var visited = EdgeSet.init(allocator);
    defer visited.deinit();

    var it = edges.iterator();
    while (it.next()) |item| {
        const edge = item.key_ptr.*;
        if (visited.contains(edge)) continue;
        try visited.put(edge, {});
        res += 1;
        switch (edge.dir) {
            .UP, .DOWN => {
                var neighbor = Edge{
                    .pos = Pos{ .x = edge.pos.x + 1, .y = edge.pos.y },
                    .dir = edge.dir,
                };
                while (edges.contains(neighbor)) : (neighbor.pos.x += 1) {
                    try visited.put(neighbor, {});
                }
                neighbor.pos.x = edge.pos.x - 1;
                while (edges.contains(neighbor)) : (neighbor.pos.x -= 1) {
                    try visited.put(neighbor, {});
                }
            },
            .LEFT, .RIGHT => {
                var neighbor = Edge{
                    .pos = Pos{ .x = edge.pos.x, .y = edge.pos.y + 1 },
                    .dir = edge.dir,
                };
                while (edges.contains(neighbor)) : (neighbor.pos.y += 1) {
                    try visited.put(neighbor, {});
                }
                neighbor.pos.y = edge.pos.y - 1;
                while (edges.contains(neighbor)) : (neighbor.pos.y -= 1) {
                    try visited.put(neighbor, {});
                }
            },
        }
    }

    return res;
}

fn solve(farm: Farm) !Price {
    var res = Price{ .full = 0, .discount = 0 };
    const regions = try farm.get_regions();
    defer regions.deinit();
    for (regions.items) |region| {
        res.full += region.perimeter * region.area;
        res.discount += region.sides * region.area;
    }
    return res;
}

pub fn main() !void {
    var input = try Farm.init(@embedFile("input"));
    var example1 = try Farm.init(@embedFile("example1"));
    var example2 = try Farm.init(@embedFile("example2"));
    var example3 = try Farm.init(@embedFile("example3"));
    defer input.deinit();
    defer example1.deinit();
    defer example2.deinit();
    defer example3.deinit();

    var ans = try solve(example1);
    std.debug.print("Answer to part 1 (example 1): {}\n", .{ans.full});
    std.debug.print("Answer to part 2 (example 1): {}\n", .{ans.discount});
    std.debug.print("\n", .{});

    ans = try solve(example2);
    std.debug.print("Answer to part 1 (example 2): {}\n", .{ans.full});
    std.debug.print("Answer to part 2 (example 2): {}\n", .{ans.discount});
    std.debug.print("\n", .{});

    ans = try solve(example3);
    std.debug.print("Answer to part 1 (example 3): {}\n", .{ans.full});
    std.debug.print("Answer to part 2 (example 3): {}\n", .{ans.discount});
    std.debug.print("\n", .{});

    ans = try solve(example3);
    std.debug.print("Answer to part 1: {}\n", .{ans.full});
    std.debug.print("Answer to part 2: {}\n", .{ans.discount});
}
