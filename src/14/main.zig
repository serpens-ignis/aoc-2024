const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Vec2D = struct {
    x: i32,
    y: i32,
};

const Robot = struct {
    p: Vec2D,
    v: Vec2D,

    fn move(self: *Robot, count: i32, bx: i32, by: i32) void {
        self.p.x += self.v.x * count;
        self.p.y += self.v.y * count;
        if (self.p.x >= 0) {
            self.p.x = @mod(self.p.x, bx);
        } else {
            const mod = @mod(-1 * self.p.x, bx);
            if (mod == 0) self.p.x = 0 else self.p.x = bx - mod;
        }
        if (self.p.y >= 0) {
            self.p.y = @mod(self.p.y, by);
        } else {
            const mod = @mod(-1 * self.p.y, by);
            if (mod == 0) self.p.y = 0 else self.p.y = by - mod;
        }
    }
};

const RobotList = std.ArrayList(Robot);

fn parse_input(raw: []const u8) !RobotList {
    var robots = RobotList.init(allocator);
    errdefer robots.deinit();

    var line_it = std.mem.splitAny(u8, raw, "\n");
    while (line_it.next()) |line| {
        if (line.len == 0) break;
        var it = std.mem.splitAny(u8, line, " ,");
        const p = Vec2D{
            .x = try std.fmt.parseInt(i32, it.next().?[2..], 10),
            .y = try std.fmt.parseInt(i32, it.next().?, 10),
        };
        const v = Vec2D{
            .x = try std.fmt.parseInt(i32, it.next().?[2..], 10),
            .y = try std.fmt.parseInt(i32, it.next().?, 10),
        };
        try robots.append(Robot{
            .p = p,
            .v = v,
        });
    }

    return robots;
}

fn safety_factor(robots: RobotList, comptime bx: i32, comptime by: i32) usize {
    var q1: usize = 0;
    var q2: usize = 0;
    var q3: usize = 0;
    var q4: usize = 0;

    for (robots.items) |robot| {
        switch (robot.p.x) {
            0...bx / 2 - 1 => {
                switch (robot.p.y) {
                    0...by / 2 - 1 => q1 += 1,
                    by / 2 + 1...by - 1 => q3 += 1,
                    else => continue,
                }
            },
            bx / 2 + 1...bx - 1 => {
                switch (robot.p.y) {
                    0...by / 2 - 1 => q2 += 1,
                    by / 2 + 1...by - 1 => q4 += 1,
                    else => continue,
                }
            },
            else => continue,
        }
    }

    return q1 * q2 * q3 * q4;
}

fn xmas_tree(robots: RobotList, comptime bx: usize, comptime by: usize) bool {
    var s: [by][bx]u8 = undefined;
    for (0..by) |y| {
        for (0..bx) |x| {
            s[y][x] = '.';
        }
    }
    for (robots.items) |robot| {
        const x: usize = @intCast(robot.p.x);
        const y: usize = @intCast(robot.p.y);
        s[y][x] = 'X';
    }
    for (s) |line| {
        var longest: usize = 0;
        var cur: usize = 0;
        for (line) |char| {
            if (char == '.') {
                longest = @max(longest, cur);
                cur = 0;
            } else {
                cur += 1;
            }
        }
        if (longest >= 12) {
            return true;
        }
    }
    return false;
}

fn solve_part1(robots: RobotList, comptime bx: i32, comptime by: i32) !usize {
    var cp_robots = try robots.clone();
    defer cp_robots.deinit();
    const items = cp_robots.items;
    for (0..items.len) |i| {
        items[i].move(100, bx, by);
    }
    return safety_factor(robots, bx, by);
}

fn solve_part2(robots: RobotList, comptime bx: usize, comptime by: usize) usize {
    const items = robots.items;
    for (0..100000) |i| {
        if (xmas_tree(robots, bx, by)) return i;
        for (0..items.len) |j| {
            items[j].move(1, bx, by);
        }
    }
    unreachable;
}

pub fn main() !void {
    var input = try parse_input(@embedFile("input"));
    var example = try parse_input(@embedFile("example"));
    defer input.deinit();
    defer example.deinit();

    std.debug.print("Answer to part 1 (example): {}\n", .{try solve_part1(example, 11, 7)});
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1: {}\n", .{try solve_part1(input, 101, 103)});
    std.debug.print("Answer to part 2: {}\n", .{solve_part2(input, 101, 103)});
}
