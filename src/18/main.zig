const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Pos = struct { x: i32, y: i32 };

const MemSpace = struct {
    byte_list: std.ArrayList(Pos),
    fallen: std.AutoHashMap(Pos, void),
    w: usize,
    h: usize,

    fn init(raw: []const u8, w: usize, h: usize) !MemSpace {
        var space = MemSpace{
            .byte_list = std.ArrayList(Pos).init(allocator),
            .fallen = std.AutoHashMap(Pos, void).init(allocator),
            .w = w,
            .h = h,
        };
        errdefer space.deinit();

        var line_it = std.mem.splitAny(u8, raw, "\n");
        while (line_it.next()) |line| {
            if (line.len == 0) break;
            var it = std.mem.splitAny(u8, line, ",");
            try space.byte_list.append(.{
                .x = try std.fmt.parseInt(i32, it.next().?, 10),
                .y = try std.fmt.parseInt(i32, it.next().?, 10),
            });
        }

        return space;
    }

    fn deinit(self: *MemSpace) void {
        self.byte_list.deinit();
        self.fallen.deinit();
    }

    fn fall(self: *MemSpace, count: usize) !void {
        const cur_count = self.fallen.count();

        if (cur_count > count) {
            for (count..cur_count) |i| {
                _ = self.fallen.remove(self.byte_list.items[i]);
            }
            return;
        }

        for (cur_count..count) |i| {
            try self.fallen.put(self.byte_list.items[i], {});
        }
    }

    fn is_blocked(self: *MemSpace, pos: Pos) bool {
        if (self.fallen.contains(pos) or
            pos.x < 0 or pos.y < 0 or pos.x >= self.w or pos.y >= self.h)
            return true;
        return false;
    }
};

const Node = struct {
    pos: Pos,
    cost: usize,

    fn cmp(context: void, a: Node, b: Node) std.math.Order {
        _ = context;
        return std.math.order(a.cost, b.cost);
    }
};

fn pathfind(space: *MemSpace) !?usize {
    var pq = std.PriorityQueue(Node, void, Node.cmp).init(allocator, {});
    defer pq.deinit();
    try pq.add(.{ .pos = .{ .x = 0, .y = 0 }, .cost = 0 });

    var visited = std.AutoHashMap(Pos, void).init(allocator);
    defer visited.deinit();

    while (pq.removeOrNull()) |node| {
        if (space.is_blocked(node.pos)) continue;
        if (node.pos.x == space.w - 1 and node.pos.y == space.h - 1) return node.cost;
        const neighbors = .{
            Pos{
                .x = node.pos.x,
                .y = node.pos.y - 1,
            },
            Pos{
                .x = node.pos.x,
                .y = node.pos.y + 1,
            },
            Pos{
                .x = node.pos.x - 1,
                .y = node.pos.y,
            },
            Pos{
                .x = node.pos.x + 1,
                .y = node.pos.y,
            },
        };
        inline for (neighbors) |neighbor| {
            if (!visited.contains(neighbor)) {
                try pq.add(.{ .pos = neighbor, .cost = node.cost + 1 });
                try visited.put(neighbor, {});
            }
        }
    }

    return null;
}

fn solve_part1(space: *MemSpace, count: usize) !?usize {
    try space.fall(count);
    return try pathfind(space);
}

fn solve_part2(space: *MemSpace) !Pos {
    var l: usize = 1;
    var r = space.byte_list.items.len - 1;
    while (l < r) {
        const mid = l + (r - l) / 2;
        try space.fall(mid);
        if (try pathfind(space) == null)
            r = mid
        else
            l = mid + 1;
    }
    return space.byte_list.items[l - 1];
}

pub fn main() !void {
    var input = try MemSpace.init(@embedFile("input"), 71, 71);
    var example = try MemSpace.init(@embedFile("example"), 7, 7);
    defer input.deinit();
    defer example.deinit();

    std.debug.print("Answer to part 1 (example): {?}\n", .{try solve_part1(&example, 12)});
    std.debug.print("Answer to part 2 (example): {}\n", .{try solve_part2(&example)});
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1: {?}\n", .{try solve_part1(&input, 1024)});
    std.debug.print("Answer to part 2: {}\n", .{try solve_part2(&input)});
}
