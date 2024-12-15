const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Dir = enum { UP, DOWN, LEFT, RIGHT };
const Moves = std.ArrayList(Dir);

const Pos = struct {
    x: usize,
    y: usize,

    fn move(self: Pos, dir: Dir) Pos {
        var new_pos = self;
        switch (dir) {
            .UP => new_pos.y -= 1,
            .DOWN => new_pos.y += 1,
            .LEFT => new_pos.x -= 1,
            .RIGHT => new_pos.x += 1,
        }
        return new_pos;
    }
};

const Map = struct {
    const Tile = enum { WALL, BOX, BOX_LEFT, BOX_RIGHT, NONE };
    const TileRow = std.ArrayList(Tile);
    const TileGrid = std.ArrayList(TileRow);

    tiles: TileGrid,
    w: usize,
    h: usize,
    start_pos: Pos,
    wide: bool,

    fn init(raw: []const u8) !Map {
        var map = Map{
            .tiles = TileGrid.init(allocator),
            .w = 0,
            .h = 0,
            .start_pos = Pos{ .x = 0, .y = 0 },
            .wide = false,
        };
        errdefer map.deinit();

        var x: usize = 0;
        var y: usize = 0;
        var line_it = std.mem.splitAny(u8, raw, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) break;

            var row = TileRow.init(allocator);
            errdefer row.deinit();

            x = 0;
            for (line) |char| {
                if (char == '@') {
                    map.start_pos = Pos{ .x = x, .y = y };
                }
                try row.append(switch (char) {
                    '#' => .WALL,
                    'O' => .BOX,
                    '.' => .NONE,
                    '@' => .NONE,
                    else => unreachable,
                });
                x += 1;
            }
            try map.tiles.append(row);
            y += 1;
        }

        map.w = x;
        map.h = y;

        return map;
    }

    fn deinit(self: *Map) void {
        for (self.tiles.items) |item| {
            item.deinit();
        }
        self.tiles.deinit();
    }

    fn clone(self: *const Map) !Map {
        var tiles = TileGrid.init(allocator);
        errdefer tiles.deinit();

        for (self.tiles.items) |row| {
            try tiles.append(try row.clone());
        }

        return Map{
            .tiles = tiles,
            .w = self.w,
            .h = self.h,
            .start_pos = self.start_pos,
            .wide = self.wide,
        };
    }

    fn widen(self: *const Map) !Map {
        var tiles = TileGrid.init(allocator);
        errdefer tiles.deinit();

        for (self.tiles.items) |row| {
            var wide_row = TileRow.init(allocator);
            errdefer wide_row.deinit();
            for (row.items) |tile| {
                switch (tile) {
                    .WALL => {
                        try wide_row.append(.WALL);
                        try wide_row.append(.WALL);
                    },
                    .BOX => {
                        try wide_row.append(.BOX_LEFT);
                        try wide_row.append(.BOX_RIGHT);
                    },
                    .NONE => {
                        try wide_row.append(.NONE);
                        try wide_row.append(.NONE);
                    },
                    else => unreachable,
                }
            }
            try tiles.append(wide_row);
        }

        return Map{
            .tiles = tiles,
            .w = self.w * 2,
            .h = self.h,
            .start_pos = Pos{
                .x = self.start_pos.x * 2,
                .y = self.start_pos.y,
            },
            .wide = true,
        };
    }

    fn get(self: *const Map, pos: Pos) Tile {
        return self.tiles.items[pos.y].items[pos.x];
    }

    fn set(self: *Map, pos: Pos, tile: Tile) void {
        self.tiles.items[pos.y].items[pos.x] = tile;
    }

    fn can_push(self: *Map, pos: Pos, dir: Dir) bool {
        switch (self.get(pos)) {
            .NONE => return true,
            .WALL => return false,
            .BOX => return self.can_push(pos.move(dir), dir),
            .BOX_LEFT, .BOX_RIGHT => |tile| {
                switch (dir) {
                    .UP, .DOWN => {
                        if (tile == .BOX_RIGHT) {
                            return self.can_push(pos.move(dir).move(.LEFT), dir) and
                                self.can_push(pos.move(dir), dir);
                        }
                        return self.can_push(pos.move(dir).move(.RIGHT), dir) and
                            self.can_push(pos.move(dir), dir);
                    },
                    .LEFT, .RIGHT => return self.can_push(pos.move(dir), dir),
                }
            },
        }
        unreachable;
    }

    fn push(self: *Map, pos: Pos, dir: Dir) void {
        switch (self.get(pos)) {
            .BOX, .BOX_LEFT, .BOX_RIGHT => |tile| {
                const next = pos.move(dir);
                self.push(next, dir);
                self.set(next, tile);
                self.set(pos, .NONE);
                if (tile != .BOX and (dir == .UP or dir == .DOWN)) {
                    const side: Dir = if (tile == .BOX_RIGHT) .LEFT else .RIGHT;
                    const opposite: Tile = if (tile == .BOX_RIGHT) .BOX_LEFT else .BOX_RIGHT;
                    const neighbor = pos.move(side);
                    self.push(neighbor, dir);
                    self.set(neighbor.move(dir), opposite);
                    self.set(neighbor, .NONE);
                }
            },
            else => {},
        }
    }

    fn gps(self: *const Map) usize {
        var res: usize = 0;
        for (self.tiles.items, 0..) |row, y| {
            for (row.items, 0..) |tile, x| {
                if (tile == .BOX or tile == .BOX_LEFT) res += 100 * y + x;
            }
        }
        return res;
    }
};

fn parse_input(raw: []const u8) !struct { map: Map, moves: Moves } {
    var part_it = std.mem.splitSequence(u8, raw, "\n\n");
    const map_s = part_it.next().?;
    const moves_s = part_it.next().?;

    var map = try Map.init(map_s);
    errdefer map.deinit();

    var moves = Moves.init(allocator);
    errdefer moves.deinit();

    for (moves_s) |char| {
        try moves.append(switch (char) {
            '^' => .UP,
            'v' => .DOWN,
            '<' => .LEFT,
            '>' => .RIGHT,
            else => continue,
        });
    }

    return .{ .map = map, .moves = moves };
}

fn solve(map: *Map, moves: Moves) usize {
    var pos = map.start_pos;
    for (moves.items) |dir| {
        const next_pos = pos.move(dir);
        switch (map.get(next_pos)) {
            .WALL => {},
            .BOX, .BOX_LEFT, .BOX_RIGHT => {
                if (map.can_push(next_pos, dir)) {
                    map.push(next_pos, dir);
                    pos = next_pos;
                }
            },
            .NONE => pos = next_pos,
        }
    }
    return map.gps();
}

fn solve_part1(map: Map, moves: Moves) !usize {
    var map_cp = try map.clone();
    defer map_cp.deinit();
    return solve(&map_cp, moves);
}

fn solve_part2(map: Map, moves: Moves) !usize {
    var wide_map = try map.widen();
    defer wide_map.deinit();
    return solve(&wide_map, moves);
}

pub fn main() !void {
    var input = try parse_input(@embedFile("input"));
    var example1 = try parse_input(@embedFile("example1"));
    var example2 = try parse_input(@embedFile("example2"));
    var example3 = try parse_input(@embedFile("example3"));
    defer input.map.deinit();
    defer input.moves.deinit();
    defer example1.map.deinit();
    defer example1.moves.deinit();
    defer example2.map.deinit();
    defer example2.moves.deinit();
    defer example3.map.deinit();
    defer example3.moves.deinit();

    std.debug.print("Answer to part 1 (example 1): {}\n", .{try solve_part1(example1.map, example1.moves)});
    std.debug.print("Answer to part 2 (example 1): {}\n", .{try solve_part2(example1.map, example1.moves)});
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1 (example 2): {}\n", .{try solve_part1(example2.map, example2.moves)});
    std.debug.print("Answer to part 2 (example 2): {}\n", .{try solve_part2(example2.map, example2.moves)});
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1 (example 3): {}\n", .{try solve_part1(example3.map, example3.moves)});
    std.debug.print("Answer to part 2 (example 3): {}\n", .{try solve_part2(example3.map, example3.moves)});
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1: {}\n", .{try solve_part1(input.map, input.moves)});
    std.debug.print("Answer to part 2: {}\n", .{try solve_part2(input.map, input.moves)});
}
