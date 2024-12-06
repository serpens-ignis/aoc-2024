const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Dir = enum { UP, DOWN, LEFT, RIGHT };

const Pos = struct { x: i32, y: i32, dir: Dir };

const Map = struct {
    tiles: std.ArrayList([]u8),
    start_pos: Pos,
    w: usize,
    h: usize,

    fn init(raw: []const u8) !Map {
        var map = Map{
            .tiles = std.ArrayList([]u8).init(allocator),
            .start_pos = undefined,
            .w = 0,
            .h = 0,
        };
        errdefer map.deinit();

        var line_it = std.mem.splitAny(u8, raw, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) continue;
            const line_cp = try allocator.dupe(u8, line);
            try map.tiles.append(line_cp);
            map.w = line.len;
            map.h += 1;
        }

        const tiles = map.tiles.items;
        for (0..map.h) |y| {
            for (0..map.w) |x| {
                if (tiles[y][x] != '^') continue;
                map.start_pos = Pos{ .x = @intCast(x), .y = @intCast(y), .dir = .UP };
                break;
            }
        }

        return map;
    }

    fn deinit(self: *Map) void {
        for (self.tiles.items) |line| {
            allocator.free(line);
        }
        self.tiles.deinit();
    }

    fn in_bounds(self: *const Map, x: i32, y: i32) bool {
        return x >= 0 and y >= 0 and x < self.w and y < self.h;
    }

    fn get(self: *const Map, x: i32, y: i32) ?u8 {
        if (self.in_bounds(x, y)) return self.tiles.items[@intCast(y)][@intCast(x)];
        return null;
    }

    fn blocked(self: *const Map, x: i32, y: i32) bool {
        const tile = self.get(x, y);
        return tile == '#' or tile == 'O';
    }

    fn visit(self: *const Map, pos: Pos) void {
        if (self.in_bounds(pos.x, pos.y)) {
            const tile = &self.tiles.items[@intCast(pos.y)][@intCast(pos.x)];
            if (tile.* == '-' and (pos.dir == .UP or pos.dir == .DOWN)) {
                tile.* = '+';
            } else if (tile.* == '|' and (pos.dir == .LEFT or pos.dir == .RIGHT)) {
                tile.* = '+';
            } else if (tile.* == '.') {
                if (pos.dir == .UP or pos.dir == .DOWN) tile.* = '|';
                if (pos.dir == .LEFT or pos.dir == .RIGHT) tile.* = '-';
            }
        }
    }

    fn is_visited(self: *const Map, x: i32, y: i32) bool {
        const tile = self.get(x, y);
        return tile == '-' or tile == '|' or tile == '+' or tile == '^';
    }

    fn detect_loop(self: *const Map, pos: Pos) bool {
        const tile = self.get(pos.x, pos.y);
        if ((tile == '|' and (pos.dir == .UP or pos.dir == .DOWN)) or
            (tile == '-' and (pos.dir == .LEFT or pos.dir == .RIGHT)) or
            (tile == '+'))
            return true;
        return false;
    }

    fn place_obstacle(self: *Map, x: usize, y: usize) void {
        const tile = &self.tiles.items[x][y];
        if (tile.* == '.') tile.* = 'O';
    }

    fn clear(self: *Map) void {
        const tiles = self.tiles.items;
        for (0..self.w) |x| {
            for (0..self.h) |y| {
                const tile = &tiles[x][y];
                if (tile.* == '|' or tile.* == '-' or tile.* == '+' or tile.* == 'O')
                    tile.* = '.';
            }
        }
    }

    fn traverse(self: *Map) !union(enum) { LOOP: void, LEAVE: usize } {
        var count: usize = 0;
        var pos = self.start_pos;
        var traversed = std.AutoHashMap(Pos, void).init(allocator);
        defer traversed.deinit();
        while (self.in_bounds(pos.x, pos.y)) {
            switch (pos.dir) {
                .UP => {
                    if (self.blocked(pos.x, pos.y - 1))
                        pos.dir = .RIGHT
                    else
                        pos.y -= 1;
                },
                .DOWN => {
                    if (self.blocked(pos.x, pos.y + 1))
                        pos.dir = .LEFT
                    else
                        pos.y += 1;
                },
                .LEFT => {
                    if (self.blocked(pos.x - 1, pos.y))
                        pos.dir = .UP
                    else
                        pos.x -= 1;
                },
                .RIGHT => {
                    if (self.blocked(pos.x + 1, pos.y))
                        pos.dir = .DOWN
                    else
                        pos.x += 1;
                },
            }
            if (!self.is_visited(pos.x, pos.y)) count += 1;
            self.visit(pos);
            if (traversed.contains(pos)) return .{ .LOOP = {} };
            try traversed.put(pos, {});
        }
        return .{ .LEAVE = count };
    }

    fn print(self: *const Map) void {
        std.debug.print("\n", .{});
        for (0..self.w) |x| {
            for (0..self.h) |y| {
                std.debug.print("{c}", .{self.tiles.items[x][y]});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }
};

fn solve_part1(map: *Map) !usize {
    return (try map.traverse()).LEAVE;
}

fn solve_part2(map: *Map) !usize {
    var count: usize = 0;

    _ = try map.traverse();
    var traversed = std.ArrayList(std.meta.Tuple(&.{ usize, usize })).init(allocator);
    for (0..map.w) |x| {
        for (0..map.h) |y| {
            const tile = map.tiles.items[x][y];
            if (tile == '|' or tile == '-' or tile == '+') {
                try traversed.append(.{ x, y });
            }
        }
    }

    for (traversed.items) |pos| {
        map.clear();
        map.place_obstacle(pos[0], pos[1]);
        if (try map.traverse() == .LOOP) count += 1;
    }

    return count;
}

pub fn main() !void {
    var input = try Map.init(@embedFile("input"));
    var example = try Map.init(@embedFile("example"));
    defer input.deinit();
    defer example.deinit();

    var ans1 = try solve_part1(&example);
    var ans2 = try solve_part2(&example);
    std.debug.print("Answer to part 1 (example): {}\n", .{ans1});
    std.debug.print("Answer to part 2 (example): {}\n", .{ans2});

    ans1 = try solve_part1(&input);
    ans2 = try solve_part2(&input);
    std.debug.print("Answer to part 1: {}\n", .{ans1});
    std.debug.print("Answer to part 2: {}\n", .{ans2});
}
