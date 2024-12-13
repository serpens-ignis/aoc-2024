const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const MachineList = std.ArrayList(Machine);

const Vec2D = struct { x: i64, y: i64 };

const Machine = struct {
    button_a: Vec2D,
    button_b: Vec2D,
    prize: Vec2D,

    fn min(self: Machine) ?i64 {
        const a = .{ self.button_a.x, self.button_a.y };
        const b = .{ self.button_b.x, self.button_b.y };
        const c = .{ self.prize.x, self.prize.y };
        const det = a[0] * b[1] - a[1] * b[0];
        if (det == 0) return null;
        const det_x = c[0] * b[1] - c[1] * b[0];
        const det_y = a[0] * c[1] - a[1] * c[0];
        if (@mod(det_x, det) != 0 or @mod(det_y, det) != 0) return null;
        return 3 * @divFloor(det_x, det) + @divFloor(det_y, det);
    }
};

fn parse_input(raw: []const u8) !MachineList {
    var list = MachineList.init(allocator);
    errdefer list.deinit();

    var line_it = std.mem.splitAny(u8, raw, "\n");
    var machine = Machine{
        .button_a = .{ .x = 0, .y = 0 },
        .button_b = .{ .x = 0, .y = 0 },
        .prize = .{ .x = 0, .y = 0 },
    };
    while (line_it.next()) |line| {
        if (line.len == 0) continue;

        var expr_it = std.mem.splitAny(u8, line, ":");
        _ = expr_it.next();
        const expr = expr_it.next().?;

        var it = std.mem.splitAny(u8, expr, ",");
        const x = try std.fmt.parseInt(i64, it.next().?[3..], 10);
        const y = try std.fmt.parseInt(i64, it.next().?[3..], 10);

        if (line[7] == 'A') {
            machine.button_a = .{ .x = x, .y = y };
        } else if (line[7] == 'B') {
            machine.button_b = .{ .x = x, .y = y };
        } else {
            machine.prize = .{ .x = x, .y = y };
            try list.append(machine);
        }
    }

    return list;
}

fn solve_part1(list: MachineList) i64 {
    var res: i64 = 0;
    for (list.items) |machine| {
        const min = machine.min();
        if (min != null) res += min.?;
    }
    return res;
}

fn solve_part2(list: MachineList) i64 {
    var res: i64 = 0;
    for (list.items) |machine| {
        const new_machine = Machine{
            .prize = .{
                .x = machine.prize.x + 10000000000000,
                .y = machine.prize.y + 10000000000000,
            },
            .button_a = machine.button_a,
            .button_b = machine.button_b,
        };
        const min = new_machine.min();
        if (min != null) res += min.?;
    }
    return res;
}

pub fn main() !void {
    var input = try parse_input(@embedFile("input"));
    var example = try parse_input(@embedFile("example"));
    defer input.deinit();
    defer example.deinit();

    std.debug.print("Answer to part 1 (example): {}\n", .{solve_part1(example)});
    std.debug.print("Answer to part 2 (example): {}\n", .{solve_part2(example)});
    std.debug.print("\n", .{});

    std.debug.print("Answer to part 1: {}\n", .{solve_part1(input)});
    std.debug.print("Answer to part 2: {}\n", .{solve_part2(input)});
}
