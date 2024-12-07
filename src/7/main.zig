const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Equation = struct {
    result: i64,
    operands: std.ArrayList(i64),

    fn init(expr: []const u8) !Equation {
        var it = std.mem.splitAny(u8, expr, ":");
        const result = try std.fmt.parseInt(i64, it.next().?, 10);

        var op_it = std.mem.splitAny(u8, it.next().?, " ");
        var operands = std.ArrayList(i64).init(allocator);
        errdefer operands.deinit();
        while (op_it.next()) |op| {
            if (op.len == 0) continue;
            try operands.append(try std.fmt.parseInt(i64, op, 10));
        }

        return Equation{
            .result = result,
            .operands = operands,
        };
    }

    fn deinit(self: *const Equation) void {
        self.operands.deinit();
    }

    fn solve_recursive(self: *const Equation, cur: i64, i: usize, can_concat: bool) bool {
        if (i >= self.operands.items.len) return cur == self.result;
        return self.solve_recursive(cur + self.operands.items[i], i + 1, can_concat) or
            self.solve_recursive(cur * self.operands.items[i], i + 1, can_concat) or
            (can_concat and
            self.solve_recursive(concat(cur, self.operands.items[i]), i + 1, can_concat));
    }

    fn is_solvable(self: *const Equation, can_concat: bool) bool {
        return self.solve_recursive(self.operands.items[0], 1, can_concat);
    }
};

const EquationList = std.ArrayList(Equation);

fn parse_input(raw: []const u8) !EquationList {
    var list = EquationList.init(allocator);
    var line_it = std.mem.splitAny(u8, raw, "\n");
    while (line_it.next()) |line| {
        if (line.len == 0) continue;
        try list.append(try Equation.init(line));
    }
    return list;
}

fn concat(op1: i64, op2: i64) i64 {
    var res = op1;
    var temp = op2;
    while (temp > 0) {
        res *= 10;
        temp = @divFloor(temp, 10);
    }
    return res + op2;
}

fn solve(equations: EquationList, can_concat: bool) i64 {
    var res: i64 = 0;
    for (equations.items) |equation| {
        if (equation.is_solvable(can_concat)) res += equation.result;
    }
    return res;
}

pub fn main() !void {
    var input = try parse_input(@embedFile("input"));
    var example = try parse_input(@embedFile("example"));
    defer input.deinit();
    defer example.deinit();
    defer for (input.items) |item| item.deinit();
    defer for (example.items) |item| item.deinit();

    var ans1 = solve(example, false);
    var ans2 = solve(example, true);
    std.debug.print("Answer to part 1 (example): {}\n", .{ans1});
    std.debug.print("Answer to part 2 (example): {}\n", .{ans2});

    ans1 = solve(input, false);
    ans2 = solve(input, true);
    std.debug.print("Answer to part 1: {}\n", .{ans1});
    std.debug.print("Answer to part 2: {}\n", .{ans2});
}
