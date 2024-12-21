const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Pos = struct {
    x: i32,
    y: i32,

    fn eql(self: Pos, other: Pos) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const Cheat = struct {
    start: Pos,
    end: Pos,
    save: i32,
};
const CheatSet = std.AutoHashMap(Cheat, void);

const Map = struct {
    const CostMap = std.AutoHashMap(Pos, i32);

    tiles: CostMap,
    w: i32,
    h: i32,

    fn init(raw: []const u8) !Map {
        var line_it = std.mem.splitAny(u8, raw, "\n");

        const w: usize = line_it.next().?.len + 1;
        const h: usize = raw.len / w;

        var end: Pos = undefined;
        for (raw, 0..) |char, i| {
            if (char == 'E') {
                end = .{ .x = @intCast(i % w), .y = @intCast(i / w) };
                break;
            }
        }

        var map = Map{
            .tiles = CostMap.init(allocator),
            .w = @intCast(w),
            .h = @intCast(h),
        };
        errdefer map.deinit();

        var char: u8 = 'E';
        var cost: i32 = 0;
        var pos = end;
        var prev = end;
        while (char != 'S') {
            try map.tiles.put(pos, cost);
            const neighbors = .{
                Pos{ .x = pos.x - 1, .y = pos.y },
                Pos{ .x = pos.x + 1, .y = pos.y },
                Pos{ .x = pos.x, .y = pos.y - 1 },
                Pos{ .x = pos.x, .y = pos.y + 1 },
            };
            inline for (neighbors) |neighbor| {
                const x: usize = @intCast(neighbor.x);
                const y: usize = @intCast(neighbor.y);
                if (x >= 0 and y >= 0 and
                    x < w or y < h)
                {
                    char = raw[y * w + x];
                    if (!neighbor.eql(prev) and char != '#') {
                        prev = pos;
                        pos = neighbor;
                        cost += 1;
                        break;
                    }
                }
            }
        }
        try map.tiles.put(pos, cost);
        return map;
    }

    fn deinit(self: *Map) void {
        self.tiles.deinit();
    }
};

fn solve(map: Map, duration: i32, threshold: i32) !i32 {
    var set = CheatSet.init(allocator);
    defer set.deinit();

    var it = map.tiles.iterator();
    while (it.next()) |item| {
        const start = item.key_ptr.*;
        try get_cheats(&set, map, start, duration);
    }

    var res: i32 = 0;
    var set_it = set.iterator();
    while (set_it.next()) |item| {
        if (item.key_ptr.save >= threshold) {
            res += 1;
        }
    }

    return res;
}

fn get_cheats(set: *CheatSet, map: Map, start: Pos, dist: i32) !void {
    // Arcane spell of an iter loop
    const min_y: i32 = @max(0, start.y - dist);
    const max_y: i32 = @min(start.y + dist + 1, map.h);
    var end = Pos{ .x = undefined, .y = min_y };
    while (end.y < max_y) : (end.y += 1) {
        const dy: i32 = dist - @as(i32, @intCast(@abs(start.y - end.y)));
        const min_x = @max(0, start.x - dy);
        const max_x = @min(start.x + dy + 1, map.w);
        end.x = min_x;
        while (end.x < max_x) : (end.x += 1) {
            if (map.tiles.get(end)) |cheat_cost| {
                const original_cost = map.tiles.get(start).?;
                const cheat_dist: i32 = @intCast(
                    @abs(start.x - end.x) + @abs(start.y - end.y),
                );
                const save = original_cost - cheat_cost - cheat_dist;
                if (save <= 0) continue;
                const cheat = Cheat{ .start = start, .end = end, .save = save };
                try set.put(cheat, {});
            }
        }
    }
}

pub fn main() !void {
    var input = try Map.init(@embedFile("input"));
    var example = try Map.init(@embedFile("example"));
    defer input.deinit();
    defer example.deinit();

    std.debug.print("Answer to part 1 (example): {}\n", .{try solve(example, 2, 1)});
    std.debug.print("Answer to part 2 (example): {}\n", .{try solve(example, 20, 50)});
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1: {}\n", .{try solve(input, 2, 100)});
    std.debug.print("Answer to part 2: {}\n", .{try solve(input, 20, 100)});
}
