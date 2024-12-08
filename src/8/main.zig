const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Pos = struct { x: i32, y: i32 };

const AntennaMap = struct {
    antennas: std.AutoHashMap(u8, std.ArrayList(Pos)),
    w: i32,
    h: i32,

    fn init(raw: []const u8) !AntennaMap {
        var map: AntennaMap = undefined;
        var antennas = std.AutoHashMap(u8, std.ArrayList(Pos)).init(allocator);
        var line_it = std.mem.splitAny(u8, raw, "\n");
        var y: usize = 0;
        while (line_it.next()) |line| : (y += 1) {
            for (line, 0..) |char, x| {
                map.w = @intCast(x + 1);
                if (char == '.') continue;
                if (!antennas.contains(char))
                    try antennas.put(char, std.ArrayList(Pos).init(allocator));
                var list = antennas.getPtr(char).?;
                try list.append(.{ .x = @intCast(x), .y = @intCast(y) });
            }
        }
        map.antennas = antennas;
        map.h = @intCast(y - 1);
        std.debug.print("{} {}\n", .{ map.w, map.h });
        return map;
    }

    fn deinit(self: *AntennaMap) void {
        var it = self.antennas.iterator();
        while (it.next()) |item| item.value_ptr.deinit();
        self.antennas.deinit();
    }

    fn in_bounds(self: *const AntennaMap, x: i32, y: i32) bool {
        return x >= 0 and y >= 0 and x < self.w and y < self.w;
    }
};

fn solve_part1(map: AntennaMap) !u32 {
    var it = map.antennas.iterator();
    var occupied = std.AutoHashMap(std.meta.Tuple(&.{ i32, i32 }), void).init(allocator);
    defer occupied.deinit();
    while (it.next()) |item| {
        const list = item.value_ptr.items;
        for (0..list.len) |i| {
            for (i + 1..list.len) |j| {
                const p1 = list[i];
                const p2 = list[j];
                const dx: i32 = @intCast(@abs(p1.x - p2.x));
                const dy: i32 = @intCast(@abs(p1.y - p2.y));
                const x1 = if (p1.x < p2.x) p1.x - dx else p1.x + dx;
                const y1 = if (p1.y < p2.y) p1.y - dy else p1.y + dy;
                const x2 = if (p2.x < p1.x) p2.x - dx else p2.x + dx;
                const y2 = if (p2.y < p1.y) p2.y - dy else p2.y + dy;
                if (map.in_bounds(x1, y1)) try occupied.put(.{ x1, y1 }, {});
                if (map.in_bounds(x2, y2)) try occupied.put(.{ x2, y2 }, {});
            }
        }
    }
    return occupied.count();
}

fn solve_part2(map: AntennaMap) !u32 {
    var it = map.antennas.iterator();
    var occupied = std.AutoHashMap(std.meta.Tuple(&.{ i32, i32 }), void).init(allocator);
    defer occupied.deinit();
    while (it.next()) |item| {
        const list = item.value_ptr.items;
        for (0..list.len) |i| {
            for (i + 1..list.len) |j| {
                const p1 = list[i];
                const p2 = list[j];
                const dx: i32 = @intCast(@abs(p1.x - p2.x));
                const dy: i32 = @intCast(@abs(p1.y - p2.y));
                var x1 = p1.x;
                var y1 = p1.y;
                while (map.in_bounds(x1, y1)) {
                    try occupied.put(.{ x1, y1 }, {});
                    x1 = if (p1.x < p2.x) x1 - dx else x1 + dx;
                    y1 = if (p1.y < p2.y) y1 - dy else y1 + dy;
                }
                var x2 = p2.x;
                var y2 = p2.y;
                while (map.in_bounds(x2, y2)) {
                    try occupied.put(.{ x2, y2 }, {});
                    x2 = if (p2.x < p1.x) x2 - dx else x2 + dx;
                    y2 = if (p2.y < p1.y) y2 - dy else y2 + dy;
                }
            }
        }
    }
    return occupied.count();
}

pub fn main() !void {
    var input = try AntennaMap.init(@embedFile("input"));
    var example = try AntennaMap.init(@embedFile("example"));
    defer input.deinit();
    defer example.deinit();

    var ans1 = try solve_part1(example);
    var ans2 = try solve_part2(example);
    std.debug.print("Answer to part 1 (example): {}\n", .{ans1});
    std.debug.print("Answer to part 2 (example): {}\n", .{ans2});

    ans1 = try solve_part1(input);
    ans2 = try solve_part2(input);
    std.debug.print("Answer to part 1: {}\n", .{ans1});
    std.debug.print("Answer to part 2: {}\n", .{ans2});
}
