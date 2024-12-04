const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

const Board = std.ArrayList([]const u8);

fn parse_input(raw: []const u8) !Board {
    var board = Board.init(allocator);
    errdefer board.deinit();

    var line_it = std.mem.splitAny(u8, raw, "\n");
    while (line_it.next()) |line| {
        if (line.len == 0) continue;
        try board.append(line);
    }
    return board;
}

fn find_xmas(board: Board, x: usize, y: usize) usize {
    const items = board.items;
    if (items[x][y] != 'X') return 0;
    var res: usize = 0;

    // left
    if (x >= 3 and
        items[x - 1][y] == 'M' and
        items[x - 2][y] == 'A' and
        items[x - 3][y] == 'S') res += 1;

    // right
    if (x <= items[0].len - 4 and
        items[x + 1][y] == 'M' and
        items[x + 2][y] == 'A' and
        items[x + 3][y] == 'S') res += 1;

    // up
    if (y >= 3 and
        items[x][y - 1] == 'M' and
        items[x][y - 2] == 'A' and
        items[x][y - 3] == 'S') res += 1;

    // down
    if (y <= board.items.len - 4 and
        items[x][y + 1] == 'M' and
        items[x][y + 2] == 'A' and
        items[x][y + 3] == 'S') res += 1;

    // up-left
    if (x >= 3 and
        y >= 3 and
        items[x - 1][y - 1] == 'M' and
        items[x - 2][y - 2] == 'A' and
        items[x - 3][y - 3] == 'S') res += 1;

    // up-right
    if (x <= items[0].len - 4 and
        y >= 3 and
        items[x + 1][y - 1] == 'M' and
        items[x + 2][y - 2] == 'A' and
        items[x + 3][y - 3] == 'S') res += 1;

    // down-left
    if (x >= 3 and
        y <= board.items.len - 4 and
        items[x - 1][y + 1] == 'M' and
        items[x - 2][y + 2] == 'A' and
        items[x - 3][y + 3] == 'S') res += 1;

    // down-right
    if (x <= items[0].len - 4 and
        y <= board.items.len - 4 and
        items[x + 1][y + 1] == 'M' and
        items[x + 2][y + 2] == 'A' and
        items[x + 3][y + 3] == 'S') res += 1;

    return res;
}

fn find_mas_cross(board: Board, x: usize, y: usize) usize {
    const items = board.items;
    if (items[x + 1][y + 1] != 'A') return 0;
    const diag1 = ((items[x][y] == 'M' and items[x + 2][y + 2] == 'S') or
        (items[x][y] == 'S' and items[x + 2][y + 2] == 'M'));
    const diag2 = ((items[x + 2][y] == 'M' and items[x][y + 2] == 'S') or
        (items[x + 2][y] == 'S' and items[x][y + 2] == 'M'));
    return if (diag1 and diag2) 1 else 0;
}

fn solve_part1(board: Board) usize {
    var res: usize = 0;
    for (0..board.items.len) |y| {
        for (0..board.items[0].len) |x| {
            res += find_xmas(board, x, y);
        }
    }
    return res;
}

fn solve_part2(board: Board) usize {
    var res: usize = 0;
    for (0..board.items.len - 2) |y| {
        for (0..board.items[0].len - 2) |x| {
            res += find_mas_cross(board, x, y);
        }
    }
    return res;
}

pub fn main() !void {
    const input = try parse_input(@embedFile("input"));
    const example = try parse_input(@embedFile("example"));
    defer input.deinit();
    defer example.deinit();

    var ans1 = solve_part1(example);
    var ans2 = solve_part2(example);
    std.debug.print("Answer to part 1 (example): {}\n", .{ans1});
    std.debug.print("Answer to part 2 (example): {}\n", .{ans2});

    ans1 = solve_part1(input);
    ans2 = solve_part2(input);
    std.debug.print("Answer to part 1: {}\n", .{ans1});
    std.debug.print("Answer to part 2: {}\n", .{ans2});
}
