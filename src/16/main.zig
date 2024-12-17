const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Pos = struct { x: usize, y: usize };
const Dir = enum { UP, DOWN, LEFT, RIGHT };

const Node = struct {
    pos: Pos,
    dir: Dir,
    cost: usize,

    fn move_forward(self: *const Node) Node {
        var next = Node{ .pos = self.pos, .dir = self.dir, .cost = self.cost + 1 };
        switch (self.dir) {
            .UP => next.pos.y -= 1,
            .DOWN => next.pos.y += 1,
            .LEFT => next.pos.x -= 1,
            .RIGHT => next.pos.x += 1,
        }
        return next;
    }

    fn turn_left(self: *const Node) Node {
        return Node{
            .pos = self.pos,
            .dir = switch (self.dir) {
                .UP => .LEFT,
                .DOWN => .RIGHT,
                .LEFT => .DOWN,
                .RIGHT => .UP,
            },
            .cost = self.cost + 1000,
        };
    }

    fn turn_right(self: *const Node) Node {
        return Node{
            .pos = self.pos,
            .dir = switch (self.dir) {
                .UP => .RIGHT,
                .DOWN => .LEFT,
                .LEFT => .UP,
                .RIGHT => .DOWN,
            },
            .cost = self.cost + 1000,
        };
    }
};

const Map = struct {
    tiles: std.ArrayList([]const u8),
    start: Pos,

    fn init(raw: []const u8) !Map {
        var map = Map{
            .tiles = std.ArrayList([]const u8).init(allocator),
            .start = undefined,
        };
        var line_it = std.mem.splitAny(u8, raw, "\n");
        var y: usize = 0;
        while (line_it.next()) |line| {
            try map.tiles.append(line);
            for (line, 0..) |char, x| {
                if (char == 'S') {
                    map.start.x = x;
                    map.start.y = y;
                }
            }
            y += 1;
        }
        return map;
    }

    fn deinit(self: *Map) void {
        self.tiles.deinit();
    }

    fn get(self: *const Map, pos: Pos) u8 {
        return self.tiles.items[pos.y][pos.x];
    }
};

const Path = std.ArrayList(Node);

fn cmp_paths(context: void, a: Path, b: Path) std.math.Order {
    _ = context;
    return std.math.order(a.getLast().cost, b.getLast().cost);
}

fn solve(map: Map) !struct { cost: usize, tiles: usize } {
    var visited = std.AutoHashMap(std.meta.Tuple(&.{ Pos, Dir }), usize).init(allocator);
    defer visited.deinit();

    var pq = std.PriorityQueue(Path, void, cmp_paths).init(allocator, {});
    defer pq.deinit();

    var best_tiles = std.AutoHashMap(Pos, void).init(allocator);
    defer best_tiles.deinit();

    var best_cost: ?usize = null;

    var first_path = Path.init(allocator);
    try first_path.append(.{ .pos = map.start, .dir = .RIGHT, .cost = 0 });
    try pq.add(first_path);
    while (pq.peek() != null) {
        var path = pq.remove();
        defer path.deinit();

        const node = path.getLast();
        const tile = map.get(node.pos);

        if (tile == '#') continue;
        if (tile == 'E') {
            if (best_cost != null and node.cost > best_cost.?) break;
            best_cost = node.cost;
            for (path.items) |n| {
                try best_tiles.put(n.pos, {});
                _ = visited.remove(.{ n.pos, n.dir });
            }
            continue;
        }

        inline for (.{ node.move_forward(), node.turn_left(), node.turn_right() }) |next| {
            const key = .{ next.pos, next.dir };
            if (!visited.contains(key) or visited.get(key).? >= next.cost) {
                var new_path = try path.clone();
                try new_path.append(next);
                try pq.add(new_path);
                try visited.put(key, next.cost);
            }
        }
    }
    return .{ .cost = best_cost.?, .tiles = best_tiles.count() };
}

pub fn main() !void {
    var input = try Map.init(@embedFile("input"));
    var example1 = try Map.init(@embedFile("example1"));
    var example2 = try Map.init(@embedFile("example2"));
    defer input.deinit();
    defer example1.deinit();
    defer example2.deinit();

    var ans = try solve(example1);
    std.debug.print("Answer to part 1 (example 1): {}\n", .{ans.cost});
    std.debug.print("Answer to part 2 (example 1): {}\n", .{ans.tiles});
    std.debug.print("\n", .{});

    ans = try solve(example2);
    std.debug.print("Answer to part 1 (example 2): {}\n", .{ans.cost});
    std.debug.print("Answer to part 2 (example 2): {}\n", .{ans.tiles});
    std.debug.print("\n", .{});

    ans = try solve(input);
    std.debug.print("Answer to part 1: {}\n", .{ans.cost});
    std.debug.print("Answer to part 2: {}\n", .{ans.tiles});
}
