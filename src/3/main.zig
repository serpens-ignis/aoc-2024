const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

fn parse_mul(s: []const u8) ?usize {
    var first = true;
    var op1: usize = 0;
    var op2: usize = 0;
    for (s) |c| {
        if (first and c == ',') {
            first = false;
        } else if (!first and c == ')') {
            return op1 * op2;
        } else if (std.ascii.isDigit(c)) {
            const digit = c - '0';
            if (first) {
                op1 *= 10;
                op1 += digit;
            } else {
                op2 *= 10;
                op2 += digit;
            }
        } else break;
    }
    return null;
}

fn solve_part1(s: []const u8) usize {
    var res: usize = 0;
    for (0..s.len - 4) |i| {
        if (std.mem.eql(u8, s[i .. i + 4], "mul(")) {
            const mul = parse_mul(s[i + 4 ..]);
            if (mul != null) res += mul.?;
        }
    }
    return res;
}

fn solve_part2(s: []const u8) usize {
    var res: usize = 0;
    var enabled = true;
    for (0..s.len - 7) |i| {
        if (enabled and std.mem.eql(u8, s[i .. i + 4], "mul(")) {
            const mul = parse_mul(s[i + 4 ..]);
            if (mul != null) res += mul.?;
        } else if (std.mem.eql(u8, s[i .. i + 7], "don't()")) {
            enabled = false;
        } else if (std.mem.eql(u8, s[i .. i + 4], "do()")) {
            enabled = true;
        }
    }
    return res;
}

pub fn main() void {
    const input = @embedFile("input");
    const example1 = @embedFile("example1");
    const example2 = @embedFile("example2");

    var ans1 = solve_part1(example1);
    var ans2 = solve_part2(example2);
    std.debug.print("Answer to part 1 (example): {}\n", .{ans1});
    std.debug.print("Answer to part 2 (example): {}\n", .{ans2});

    ans1 = solve_part1(input);
    ans2 = solve_part2(input);
    std.debug.print("Answer to part 1: {}\n", .{ans1});
    std.debug.print("Answer to part 2: {}\n", .{ans2});
}
